import Foundation
import Combine

struct DailyRecord: Codable, Equatable {
    var date: String
    var cups: Int
    var total: Int

    var completed: Bool { total > 0 && cups >= total }
    var progress: Double { total > 0 ? min(Double(cups) / Double(total), 1.0) : 0 }
}

/// 统计时间范围
enum StatsRange: String, CaseIterable {
    case last7 = "最近7天"
    case week = "本周"
    case month = "本月"
    case year = "本年"
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
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        AppLog.log("DATA", "加载完成: currentCups=\(currentCups), totalCups=\(totalCups), reminderInterval=\(reminderInterval)s, lastDrinkTime=\(fmt.string(from: lastDrinkTime)), lastReminderTime=\(fmt.string(from: lastReminderTime))")
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
        // 喝水后重置提醒计时，从这个时间点重新开始等下一个提醒周期
        lastReminderTime = lastDrinkTime
        updateTodayRecord()
        saveData()
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        AppLog.log("DATA", "喝水+1 => \(currentCups)/\(totalCups), 达成目标=\(hasReachedGoal), lastDrinkTime=\(fmt.string(from: lastDrinkTime)), lastReminderTime=\(fmt.string(from: lastReminderTime))")
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
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        AppLog.log("DATA", "记录提醒时间: lastReminderTime=\(fmt.string(from: lastReminderTime)), lastDrinkTime=\(fmt.string(from: lastDrinkTime))")
    }

    func setTotalCups(_ cups: Int) {
        totalCups = max(1, min(20, cups))
        updateTodayRecord()
        saveData()
        AppLog.log("DATA", "设置每日目标: \(totalCups)杯")
    }

    func resetToday() {
        currentCups = 0
        updateTodayRecord()
        saveData()
        AppLog.log("DATA", "重置今日数据: currentCups=0")
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
                } else {
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
        // 清理：保留最近1年数据（足够本年统计），避免无限增长
        monthlyRecords = monthlyRecords.filter { isWithinLastYear($0.date) }
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

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        AppLog.log("DATA", "从 UserDefaults 读取: currentCups=\(currentCups), totalCups=\(totalCups), lastResetDate=\(lastResetDate), lastDrinkTime=\(fmt.string(from: lastDrinkTime)), lastReminderTime=\(fmt.string(from: lastReminderTime)), reminderInterval=\(reminderInterval)s")
    }

    private func saveData() {
        defaults.set(currentCups, forKey: currentCupsKey)
        defaults.set(totalCups, forKey: totalCupsKey)
        defaults.set(lastResetDate, forKey: lastDateKey)
        defaults.set(lastDrinkTime, forKey: lastDrinkTimeKey)
        defaults.set(lastReminderTime, forKey: lastReminderTimeKey)
        defaults.set(reminderInterval, forKey: reminderIntervalKey)

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        AppLog.log("DATA", "写入 UserDefaults: currentCups=\(currentCups), totalCups=\(totalCups), lastResetDate=\(lastResetDate), lastDrinkTime=\(fmt.string(from: lastDrinkTime)), lastReminderTime=\(fmt.string(from: lastReminderTime)), reminderInterval=\(reminderInterval)s")
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
            AppLog.log("DATA", "无历史记录或解析失败")
            return
        }
        monthlyRecords = records.filter { isWithinLastYear($0.date) }
        AppLog.log("DATA", "加载历史记录: \(records.count)条, 过滤后\(monthlyRecords.count)条 => \(monthlyRecords.map { "\($0.date):\($0.cups)杯" }.joined(separator: ", "))")
    }

    private func saveMonthlyRecords() {
        if let data = try? JSONEncoder().encode(monthlyRecords) {
            defaults.set(data, forKey: recordsKey)
            AppLog.log("DATA", "写入月度记录: \(monthlyRecords.count)条 => \(monthlyRecords.map { "\($0.date):\($0.cups)/\($0.total)" }.joined(separator: ", "))")
        } else {
            AppLog.log("DATA", "写入月度记录失败: 编码错误")
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

    /// 是否在最近1年内（保留数据用）
    private func isWithinLastYear(_ dateStr: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateStr) else { return false }
        let daysAgo = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? -1
        return daysAgo >= 0 && daysAgo <= 365
    }

    // 按日期从小到大排序的全部记录
    var sortedMonthlyRecords: [DailyRecord] {
        monthlyRecords.sorted { $0.date < $1.date }
    }

    // MARK: - 按时间范围查询

    /// 获取指定范围内的日期字符串集合
    func dateStrings(for range: StatsRange) -> [String] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = Date()

        let startDate: Date
        switch range {
        case .last7:
            startDate = cal.date(byAdding: .day, value: -6, to: today)!
        case .week:
            // 本周（周一为起点）
            let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            startDate = cal.date(from: comps)!
        case .month:
            startDate = cal.date(from: cal.dateComponents([.year, .month], from: today))!
        case .year:
            startDate = cal.date(from: cal.dateComponents([.year], from: today))!
        }

        var dates: [String] = []
        var cur = startDate
        while cur <= today {
            dates.append(formatter.string(from: cur))
            cur = cal.date(byAdding: .day, value: 1, to: cur)!
        }
        return dates
    }

    /// 按时间范围获取记录（含无数据的日期，cups=0，用于图表展示）
    func records(for range: StatsRange) -> [DailyRecord] {
        let dates = Set(dateStrings(for: range))
        var result: [DailyRecord] = []
        for dateStr in dates.sorted() {
            if let r = monthlyRecords.first(where: { $0.date == dateStr }) {
                result.append(r)
            } else {
                result.append(DailyRecord(date: dateStr, cups: 0, total: totalCups))
            }
        }
        return result
    }

    /// 按时间范围获取【有效记录】（仅有记录数据的日期，无记录不统计）
    func validRecords(for range: StatsRange) -> [DailyRecord] {
        let dates = Set(dateStrings(for: range))
        return monthlyRecords
            .filter { dates.contains($0.date) }
            .sorted { $0.date < $1.date }
    }

    /// 按时间范围统计完成天数（仅有效记录）
    func completedDays(for range: StatsRange) -> Int {
        validRecords(for: range).filter { $0.completed }.count
    }

    /// 按时间范围统计有效记录天数（仅有效记录）
    func totalDays(for range: StatsRange) -> Int {
        validRecords(for: range).count
    }

    /// 按时间范围统计总杯数（仅有效记录）
    func totalCups(for range: StatsRange) -> Int {
        validRecords(for: range).reduce(0) { $0 + $1.cups }
    }

    /// 按时间范围统计日均杯数（仅有效记录）
    func avgCups(for range: StatsRange) -> Double {
        let days = totalDays(for: range)
        return days > 0 ? Double(totalCups(for: range)) / Double(days) : 0
    }

    /// 按时间范围统计完成率（仅有效记录）
    func completionRate(for range: StatsRange) -> Double {
        let days = totalDays(for: range)
        return days > 0 ? Double(completedDays(for: range)) / Double(days) : 0
    }
}
