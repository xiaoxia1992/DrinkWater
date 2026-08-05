import Foundation
import Combine

struct DailyRecord: Codable, Equatable {
    var date: String
    var cups: Int
    var total: Int

    var completed: Bool { total > 0 && cups >= total }
    var progress: Double { total > 0 ? min(Double(cups) / Double(total), 1.0) : 0 }
}

class WaterData: ObservableObject {
    static let shared = WaterData()

    @Published var currentCups: Int = 0
    @Published var totalCups: Int = 8
    @Published var lastResetDate: String = ""
    @Published var monthlyRecords: [DailyRecord] = []
    @Published var lastDrinkTime: Date = Date()
    /// 上次提醒弹出的时间，用于计算提醒间隔
    @Published var lastReminderTime: Date = Date()
    /// 提醒间隔（秒），默认 2 小时，最短 10 秒
    @Published var reminderInterval: TimeInterval = 2 * 60 * 60

    private let defaults = UserDefaults.standard
    private let currentCupsKey = "DrinkWater_currentCups"
    private let totalCupsKey = "DrinkWater_totalCups"
    private let lastDateKey = "DrinkWater_lastDate"
    private let recordsKey = "DrinkWater_monthlyRecords"
    private let lastDrinkTimeKey = "DrinkWater_lastDrinkTime"
    private let lastReminderTimeKey = "DrinkWater_lastReminderTime"
    private let reminderIntervalKey = "DrinkWater_reminderInterval"

    init() {
        loadData()
        AppLog.log("DATA", "加载完成: currentCups=\(currentCups), totalCups=\(totalCups), reminderInterval=\(reminderInterval)s, lastDrinkTime=\(lastDrinkTime), lastReminderTime=\(lastReminderTime)")
        loadMonthlyRecords()
        checkAndResetIfNeeded()
        // 确保今天有记录
        ensureTodayRecord()
    }

    var hasReachedGoal: Bool {
        totalCups > 0 && currentCups >= totalCups
    }

    var progress: Double {
        guard totalCups > 0 else { return 0 }
        return min(Double(currentCups) / Double(totalCups), 1.0)
    }

    // 本月完成天数
    var monthlyCompletedDays: Int {
        monthlyRecords.filter { $0.completed }.count
    }

    // 本月总杯数
    var monthlyTotalCups: Int {
        monthlyRecords.reduce(0) { $0 + $1.cups }
    }

    // 本月已过天数
    var monthlyDays: Int {
        let cal = Calendar.current
        return cal.component(.day, from: Date())
    }

    // 本月平均每天杯数
    var monthlyAvgCups: Double {
        let days = monthlyDays
        return days > 0 ? Double(monthlyTotalCups) / Double(days) : 0
    }

    func incrementCup() {
        checkAndResetIfNeeded()
        currentCups += 1
        lastDrinkTime = Date()
        updateTodayRecord()
        saveData()
        AppLog.log("DATA", "喝水+1 => \(currentCups)/\(totalCups), 达成目标=\(hasReachedGoal)")
    }

    func recordDrink() {
        lastDrinkTime = Date()
        saveData()
    }

    /// 距离上次喝水已经过了多少秒
    var secondsSinceLastDrink: TimeInterval {
        Date().timeIntervalSince(lastDrinkTime)
    }

    /// 距离上次提醒已经过了多少秒
    var secondsSinceLastReminder: TimeInterval {
        Date().timeIntervalSince(lastReminderTime)
    }

    /// 记录提醒已弹出，更新上次提醒时间
    func markReminderShown() {
        lastReminderTime = Date()
        saveData()
        AppLog.log("DATA", "记录提醒时间 => lastReminderTime=\(lastReminderTime)")
    }

    func setTotalCups(_ cups: Int) {
        totalCups = max(1, min(20, cups))
        updateTodayRecord()
        saveData()
    }

    func resetToday() {
        currentCups = 0
        updateTodayRecord()
        saveData()
    }

    func checkAndResetIfNeeded() {
        let today = dateString(for: Date())
        if lastResetDate != today {
            AppLog.log("DATA", "日期变化: lastResetDate=\(lastResetDate) -> today=\(today), 清零")
            // 昨天的日期保存到历史记录
            if !lastResetDate.isEmpty {
                let yesterday = lastResetDate
                if monthlyRecords.contains(where: { $0.date == yesterday }) {
                    // 已存在，不重复处理
                } else if isCurrentMonthDate(yesterday) {
                    monthlyRecords.append(DailyRecord(date: yesterday, cups: currentCups, total: totalCups))
                }
            }

            currentCups = 0
            lastResetDate = today
            saveMonthlyRecords()
            saveData()
        }
        ensureTodayRecord()
    }

    // MARK: - 今日记录

    private func ensureTodayRecord() {
        let today = dateString(for: Date())
        if let idx = monthlyRecords.firstIndex(where: { $0.date == today }) {
            // 更新今天的记录
            monthlyRecords[idx].cups = currentCups
            monthlyRecords[idx].total = totalCups
        } else {
            monthlyRecords.append(DailyRecord(date: today, cups: currentCups, total: totalCups))
        }
        // 清理非本月记录
        monthlyRecords = monthlyRecords.filter { isCurrentMonthDate($0.date) }
        saveMonthlyRecords()
    }

    private func updateTodayRecord() {
        let today = dateString(for: Date())
        if let idx = monthlyRecords.firstIndex(where: { $0.date == today }) {
            monthlyRecords[idx].cups = currentCups
            monthlyRecords[idx].total = totalCups
        }
        saveMonthlyRecords()
    }

    // MARK: - 持久化

    private func loadData() {
        let saved = defaults.integer(forKey: totalCupsKey)
        totalCups = saved > 0 ? saved : 8
        currentCups = defaults.integer(forKey: currentCupsKey)
        lastResetDate = defaults.string(forKey: lastDateKey) ?? ""
        if let lt = defaults.object(forKey: lastDrinkTimeKey) as? Date {
            lastDrinkTime = lt
        }
        if let lr = defaults.object(forKey: lastReminderTimeKey) as? Date {
            lastReminderTime = lr
        }
        // 提醒间隔：默认 2 小时，最短 10 秒
        let savedInterval = defaults.double(forKey: reminderIntervalKey)
        reminderInterval = savedInterval >= 10 ? savedInterval : (2 * 60 * 60)
    }

    private func saveData() {
        defaults.set(currentCups, forKey: currentCupsKey)
        defaults.set(totalCups, forKey: totalCupsKey)
        defaults.set(lastResetDate, forKey: lastDateKey)
        defaults.set(lastDrinkTime, forKey: lastDrinkTimeKey)
        defaults.set(lastReminderTime, forKey: lastReminderTimeKey)
        defaults.set(reminderInterval, forKey: reminderIntervalKey)
    }

    /// 设置提醒间隔（秒），最短 10 秒
    func setReminderInterval(_ seconds: TimeInterval) {
        reminderInterval = max(10, seconds)
        saveData()
        AppLog.log("DATA", "设置提醒间隔 => \(reminderInterval)s")
    }

    private func loadMonthlyRecords() {
        guard let data = defaults.data(forKey: recordsKey),
              let records = try? JSONDecoder().decode([DailyRecord].self, from: data) else {
            monthlyRecords = []
            return
        }
        monthlyRecords = records.filter { isCurrentMonthDate($0.date) }
    }

    private func saveMonthlyRecords() {
        if let data = try? JSONEncoder().encode(monthlyRecords) {
            defaults.set(data, forKey: recordsKey)
        }
    }

    // MARK: - Helpers

    func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func isCurrentMonthDate(_ dateStr: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let thisMonth = formatter.string(from: Date())
        return dateStr.hasPrefix(thisMonth)
    }

    // 按日期从小到大排序的月记录
    var sortedMonthlyRecords: [DailyRecord] {
        monthlyRecords.sorted { $0.date < $1.date }
    }
}
