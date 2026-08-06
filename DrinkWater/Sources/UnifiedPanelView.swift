import SwiftUI

// MARK: - 主题色

enum Theme {
    static let bgTop = Color(red: 0.96, green: 0.97, blue: 1.00)
    static let bgBottom = Color(red: 0.92, green: 0.93, blue: 1.00)

    static let primary = Color(red: 0.31, green: 0.55, blue: 1.00)        // #4F8CFF
    static let primaryDark = Color(red: 0.43, green: 0.31, blue: 1.00)   // #6F4FFF
    static let success = Color(red: 0.20, green: 0.83, blue: 0.63)       // #34D4A0
    static let danger = Color(red: 1.00, green: 0.42, blue: 0.42)        // #FF6B6B
    static let warning = Color(red: 1.00, green: 0.74, blue: 0.27)       // #FFBC45

    static let cardBG = Color.white.opacity(0.85)
    static let cardStroke = Color.white.opacity(0.6)
    static let textPrimary = Color(red: 0.12, green: 0.14, blue: 0.22)
    static let textSecondary = Color(red: 0.45, green: 0.49, blue: 0.62)

    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let successGradient = LinearGradient(
        colors: [Color(red: 0.30, green: 0.92, blue: 0.70), success],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - 圆环进度

struct RingProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let trackColor: Color
    let gradientColors: [Color]

    init(progress: Double,
         lineWidth: CGFloat = 14,
         trackColor: Color = Color.white.opacity(0.5),
         gradientColors: [Color]? = nil) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.trackColor = trackColor
        self.gradientColors = gradientColors ?? [Theme.primary, Theme.primaryDark]
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors + [gradientColors[0]]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.75), value: progress)
        }
    }
}

// MARK: - Tab 枚举

enum PanelTab: String, CaseIterable {
    case today = "今日"
    case stats = "统计"
    case settings = "设置"
}

// MARK: - 主面板

struct UnifiedPanelView: View {
    @ObservedObject var waterData: WaterData
    @State private var selectedTab: PanelTab = .today
    @State private var lastTab: PanelTab = .today   // 记录离开设置页前的 tab
    @State private var statsRange: StatsRange = .last7   // 统计页时间范围

    var body: some View {
        VStack(spacing: 0) {
            // 顶部 Tab 栏
            tabBar

            // 内容区
            ZStack {
                if selectedTab == .today {
                    todayView.transition(.opacity)
                }
                if selectedTab == .stats {
                    statsView
                        .transition(.opacity)
                        .onAppear { logStats() }
                }
                if selectedTab == .settings {
                    SettingsPage(
                        waterData: waterData,
                        onBack: {
                            AppLog.log("UI", "返回: 设置 -> \(lastTab.rawValue)")
                            withAnimation(.easeInOut(duration: 0.25)) { selectedTab = lastTab }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 420, height: 465)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Theme.bgTop, Theme.bgBottom],
                    startPoint: .top, endPoint: .bottom
                )
                // 装饰性光晕
                Circle()
                    .fill(Theme.primary.opacity(0.10))
                    .frame(width: 240, height: 240)
                    .blur(radius: 60)
                    .offset(x: -120, y: -180)
                Circle()
                    .fill(Theme.primaryDark.opacity(0.08))
                    .frame(width: 220, height: 220)
                    .blur(radius: 60)
                    .offset(x: 130, y: 220)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 22, y: 7)
        // 整体缩小到 0.75（75% 大小）
        .compositingGroup()
        .scaleEffect(0.75, anchor: .center)
        .frame(width: 315, height: 349)
    }

    // MARK: - Tab 栏

    private var tabBar: some View {
        HStack(spacing: 6) {
            // 标题
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .foregroundStyle(Theme.primaryGradient)
                    .font(.system(size: 16, weight: .bold))
                Text("饮水助手")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
            }
            .padding(.leading, 6)

            Spacer(minLength: 0)

            // Tab 按钮组
            HStack(spacing: 2) {
                ForEach([PanelTab.today, .stats], id: \.self) { tab in
                    tabPill(tab)
                }
            }
            .padding(3)
            .background(
                Capsule().fill(Color.white.opacity(0.7))
            )

            // 设置按钮
            Button(action: {
                lastTab = selectedTab == .settings ? lastTab : selectedTab
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = .settings
                }
                AppLog.log("UI", "点击设置按钮")
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 14))
                    .foregroundColor(selectedTab == .settings ? .white : Theme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(selectedTab == .settings ? AnyShapeStyle(Theme.primaryGradient) : AnyShapeStyle(Color.clear))
                    )
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .padding(.leading, 14)
        .padding(.vertical, 10)
    }

    private func tabPill(_ tab: PanelTab) -> some View {
        let isSelected = selectedTab == tab
        return Button(action: {
            // 确保 window 是 key，否则点击可能不生效
            NSApp.windows.forEach { if $0 is NSPanel { $0.makeKey() } }
            AppLog.log("UI", "切换Tab: \(tab.rawValue)")
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
        }) {
            HStack(spacing: 4) {
                Image(systemName: tab == .today ? "drop.fill" : "chart.bar.xaxis")
                    .font(.system(size: 10, weight: .bold))
                Text(tab.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
            }
            .foregroundColor(isSelected ? .white : Theme.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(isSelected ? AnyShapeStyle(Theme.primaryGradient) : AnyShapeStyle(Color.clear))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 今日页

    private var todayView: some View {
        VStack(spacing: 0) {
            // 主区 - 居中显示
            VStack(spacing: 16) {
                // 圆环进度
                ZStack {
                    RingProgressView(progress: waterData.progress, lineWidth: 16,
                                     gradientColors: waterData.hasReachedGoal
                                        ? [Theme.success, Color(red: 0.30, green: 0.92, blue: 0.70)]
                                        : [Theme.primary, Theme.primaryDark])
                        .frame(width: 180, height: 180)

                    VStack(spacing: 0) {
                        Text("\(waterData.currentCups)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(waterData.hasReachedGoal ? Theme.successGradient : Theme.primaryGradient)
                            .contentTransition(.numericText())
                        Text("/ \(waterData.totalCups) 杯")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                // 完成状态
                if waterData.hasReachedGoal {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(Theme.success)
                        Text("今日目标已达成！继续保持")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.success)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.success.opacity(0.12)))
                } else {
                    HStack(spacing: 4) {
                        Text("还差")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                        Text("\(waterData.totalCups - waterData.currentCups)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.primary)
                        Text("杯达成今日目标")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                // 杯子网格
                // cupGrid
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.top, 4)

            // 按钮区 - 固定底部
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    actionButton(
                        icon: "arrow.counterclockwise",
                        bg: waterData.currentCups > 0 ? Theme.danger.opacity(0.12) : Color.gray.opacity(0.10),
                        fg: waterData.currentCups > 0 ? Theme.danger : Theme.textSecondary.opacity(0.6),
                        action: { showResetAlert = true },
                        disabled: waterData.currentCups == 0
                    )

                    mainDrinkButton
                }
                .padding(.horizontal, 24)

                // 底部提示
                HStack(spacing: 5) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 9))
                    Text("每日零点自动清零")
                        .font(.system(size: 10))
                }
                .foregroundColor(Theme.textSecondary.opacity(0.8))
            }
            .padding(.bottom, 14)
        }
        // 自定义重置确认弹框（比系统 alert 小，75% 大小）
        .overlay {
            if showResetAlert {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .onTapGesture { showResetAlert = false }

                    VStack(spacing: 12) {
                        Text("重置今日数据？")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        Text("当前 \(waterData.currentCups) 杯饮水记录将被清零。")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 10) {
                            Button(action: {
                                AppLog.log("UI", "取消重置")
                                showResetAlert = false
                            }) {
                                Text("取消")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Theme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(Color.gray.opacity(0.2)))
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                AppLog.log("UI", "确认重置今日数据")
                                waterData.resetToday()
                                showResetAlert = false
                            }) {
                                Text("确认重置")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(Theme.primaryGradient))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(18)
                    .frame(width: 240)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.95))
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }
            }
        }
    }

    @State private var showResetAlert = false

    private var cupGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)
        let total = waterData.totalCups
        let current = waterData.currentCups
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(i < current
                              ? AnyShapeStyle(Theme.primaryGradient)
                              : AnyShapeStyle(Color.gray.opacity(0.15)))
                        .frame(height: 28)
                    if i < current {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("\(i + 1)")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.textSecondary.opacity(0.7))
                    }
                }
            }
        }
    }

    private var mainDrinkButton: some View {
        Button(action: {
            AppLog.log("UI", "点击喝水按钮")
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                waterData.incrementCup()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                Text("喝一杯")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(waterData.hasReachedGoal ? Theme.successGradient : Theme.primaryGradient)
                    .shadow(color: (waterData.hasReachedGoal ? Theme.success : Theme.primary).opacity(0.35),
                            radius: 8, y: 3)
            )
        }
        .buttonStyle(.plain)
    }

    private func actionButton(icon: String, bg: Color, fg: Color, action: @escaping () -> Void, disabled: Bool = false) -> some View {
        Button(action: { showResetAlert = true }) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(fg)
                .frame(width: 48, height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 14).fill(bg)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: - 统计页

    private func logStats() {
        let records = waterData.records(for: statsRange)
        let completed = waterData.completedDays(for: statsRange)
        let days = waterData.totalDays(for: statsRange)
        let rate = waterData.completionRate(for: statsRange)
        AppLog.log("STATS", "统计页加载[\(statsRange.rawValue)]: 完成天数=\(completed)/\(days), 完成率=\(Int(rate * 100))%, 总杯数=\(waterData.totalCups(for: statsRange)), 日均=\(String(format: "%.1f", waterData.avgCups(for: statsRange))), 记录数=\(records.count)")
        AppLog.log("STATS", "明细[\(statsRange.rawValue)]: \(records.map { "\($0.date) \($0.cups)/\($0.total)" }.joined(separator: ", "))")
    }

    private var statsView: some View {
        return ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 14) {
                // 时间范围切换
                HStack(spacing: 2) {
                    ForEach(StatsRange.allCases, id: \.self) { r in
                        Button(action: {
                            AppLog.log("UI", "切换统计范围: \(r.rawValue)")
                            withAnimation(.easeInOut(duration: 0.2)) { statsRange = r }
                        }) {
                            Text(r.rawValue)
                                .font(.system(size: 11, weight: statsRange == r ? .semibold : .medium))
                                .foregroundColor(statsRange == r ? .white : Theme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule().fill(statsRange == r ? AnyShapeStyle(Theme.primaryGradient) : AnyShapeStyle(Color.clear))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
                .padding(3)
                .background(Capsule().fill(Color.white.opacity(0.7)))

                // 完成率大圆环
                HStack(spacing: 16) {
                    ZStack {
                        RingProgressView(progress: waterData.completionRate(for: statsRange), lineWidth: 10,
                                         trackColor: Color.gray.opacity(0.15),
                                         gradientColors: [Theme.primary, Theme.primaryDark])
                            .frame(width: 90, height: 90)
                        VStack(spacing: 0) {
                            Text("\(Int(waterData.completionRate(for: statsRange) * 100))%")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Theme.primaryGradient)
                            Text("完成率")
                                .font(.system(size: 9))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Circle().fill(Theme.success).frame(width: 8, height: 8)
                            Text("完成天数: \(waterData.completedDays(for: statsRange)) / \(waterData.totalDays(for: statsRange)) 天")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                        }
                        HStack(spacing: 4) {
                            Circle().fill(Theme.primary).frame(width: 8, height: 8)
                            Text("总杯数: \(waterData.totalCups(for: statsRange)) 杯")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                        }
                        HStack(spacing: 4) {
                            Circle().fill(Theme.warning).frame(width: 8, height: 8)
                            Text("日均: \(String(format: "%.1f", waterData.avgCups(for: statsRange))) 杯")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Theme.textPrimary)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background(cardBG)

                // 柱状图（仅最近7天显示，仅有效记录）
                if statsRange == .last7 {
                    recentChartCard(records: waterData.validRecords(for: statsRange))
                }
                // 明细表（仅显示有记录的数据）
                statsTableCard(records: waterData.validRecords(for: statsRange), rangeName: statsRange.rawValue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func cardBG<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Theme.cardBG)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )
    }

    private var cardBG: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Theme.cardBG)
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )
    }

    private func recentChartCard(records: [DailyRecord]) -> some View {
        // 按真实日历取最近 7 天（含今天），从 records 中按 date 查找
        let calendar = Calendar.current
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let last7Dates: [(date: Date, dateStr: String, weekday: String, dayNum: Int)] = (0..<7).map { i in
            let dayOffset = 6 - i
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let dateStr = formatter.string(from: date)
            let weekdayIdx = calendar.component(.weekday, from: date) - 1
            return (date, dateStr, calendar.shortWeekdaySymbols[weekdayIdx], calendar.component(.day, from: date))
        }
        let maxCups = max(records.suffix(7).map { $0.cups }.max() ?? 0, waterData.totalCups, 4)
        let barMaxH: CGFloat = 80

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("最近 7 天")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("有效 \(records.count) 天")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary.opacity(0.8))
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    let item = last7Dates[i]
                    let record = records.first(where: { $0.date == item.dateStr })
                    let goalH = barMaxH * CGFloat(waterData.totalCups) / CGFloat(maxCups)
                    let cupH: CGFloat = {
                        guard let r = record else { return 2 }
                        return max(CGFloat(r.cups) / CGFloat(maxCups) * barMaxH, 4)
                    }()

                    VStack(spacing: 4) {
                        // 杯数
                        Text(record.map { "\($0.cups)" } ?? "-")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(record?.completed == true ? Theme.success : Theme.primary)
                            .frame(height: 12)

                        // 柱子
                        ZStack(alignment: .bottom) {
                            // 目标虚线
                            Rectangle()
                                .fill(Theme.warning.opacity(0.5))
                                .frame(width: 18, height: 1)
                                .offset(y: -goalH)
                            // 柱
                            RoundedRectangle(cornerRadius: 4)
                                .fill(record?.completed == true
                                      ? AnyShapeStyle(Theme.successGradient)
                                      : AnyShapeStyle(Theme.primaryGradient))
                                .frame(width: 18, height: cupH)
                        }
                        .frame(width: 18, height: barMaxH)

                        // 星期
                        Text(item.weekday)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                        Text("\(item.dayNum)")
                            .font(.system(size: 9))
                            .foregroundColor(Theme.textSecondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
        }
        .padding(14)
        .background(cardBG)
    }

    private func statsTableCard(records: [DailyRecord], rangeName: String) -> some View {
        let displayRecords = records.reversed()
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(rangeName)明细")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("\(records.count) 天")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.bottom, 8)

            // 表头
            HStack(spacing: 0) {
                Text("日期").frame(maxWidth: .infinity, alignment: .leading)
                Text("杯数").frame(width: 60, alignment: .center)
                Text("进度").frame(width: 80, alignment: .center)
                Text("状态").frame(width: 36, alignment: .center)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(Theme.textSecondary)
            .padding(.bottom, 6)

            Divider().opacity(0.3)

            if displayRecords.isEmpty {
                Text("暂无数据")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(displayRecords), id: \.date) { record in
                    HStack(spacing: 0) {
                        Text(formattedDate(record.date))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textPrimary)

                        Text("\(record.cups)/\(record.total)")
                            .frame(width: 60, alignment: .center)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Theme.textPrimary)

                        // 小进度条
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 5)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(record.completed ? Theme.success : Theme.primary)
                                .frame(width: 80 * record.progress, height: 5)
                        }
                        .frame(width: 80, height: 5)

                        Image(systemName: record.completed ? "checkmark.circle.fill" : "circle")
                            .frame(width: 36, alignment: .center)
                            .font(.system(size: 12))
                            .foregroundColor(record.completed ? Theme.success : Theme.textSecondary.opacity(0.4))
                    }
                    .padding(.vertical, 5)

                    if record.date != displayRecords.last?.date {
                        Divider().opacity(0.2)
                    }
                }
            }
        }
        .padding(14)
        .background(cardBG)
    }

    private func formattedDate(_ dateStr: String) -> String {
        let parts = dateStr.components(separatedBy: "-")
        if parts.count == 3 {
            return "\(parts[1])/\(parts[2])"
        }
        return dateStr
    }
}

// MARK: - 设置页

enum IntervalUnit: String, CaseIterable {
    case second = "秒"
    case minute = "分钟"
    case hour = "小时"
    var seconds: TimeInterval {
        switch self {
        case .second: return 1
        case .minute: return 60
        case .hour: return 3600
        }
    }
}

struct SettingsPage: View {
    @ObservedObject var waterData: WaterData
    let onBack: () -> Void
    @State private var cupsInput: String = ""
    @State private var showSavedToast = false
    @State private var didInit = false
    @State private var intervalInput: String = ""
    @State private var intervalUnit: IntervalUnit = .minute

    var body: some View {
        VStack(spacing: 0) {
            // 顶部栏：返回 + 标题
            HStack(spacing: 10) {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                        Text("返回")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Theme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.primary.opacity(0.10)))
                }
                .buttonStyle(.plain)

                Spacer()

                Text("设置")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                // 占位
                Color.clear.frame(width: 60, height: 24)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 14) {
                    // 目标设置卡片
                    goalCard
                    // 提醒间隔设置卡片
                    intervalCard
                    // 快捷设置
                    quickCard
                    // 关于
                    aboutCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            if !didInit {
                cupsInput = "\(waterData.totalCups)"
                syncIntervalFromData()
                didInit = true
            }
        }
        .onChange(of: waterData.totalCups) { _, newValue in
            // 外部更新（快速选择）时同步显示
            if Int(cupsInput) != newValue {
                cupsInput = "\(newValue)"
            }
        }
    }

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.primary)
                Text("每日目标")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: { adjustCups(-1) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(canDecreaseCups ? AnyShapeStyle(Theme.primaryGradient) : AnyShapeStyle(Color.gray.opacity(0.35))))
                }
                .buttonStyle(.plain)
                .disabled(!canDecreaseCups)

                VStack(spacing: 0) {
                    TextField("", text: $cupsInput)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .textFieldStyle(.plain)
                        .foregroundStyle(Theme.primaryGradient)
                        .frame(width: 80)
                        .onChange(of: cupsInput) { _, newValue in
                            validateInput(newValue)
                        }
                    Text("杯 / 每天")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                }

                Button(action: { adjustCups(1) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(waterData.totalCups >= 20 ? AnyShapeStyle(Color.gray.opacity(0.35)) : AnyShapeStyle(Theme.primaryGradient)))
                }
                .buttonStyle(.plain)
                .disabled(waterData.totalCups >= 20)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(cardBG)
    }

    private var quickCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.warning)
                Text("快速选择")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            HStack(spacing: 8) {
                ForEach([4, 6, 8, 10, 12], id: \.self) { cups in
                    Button(action: {
                        AppLog.log("UI", "快速选择目标: \(cups)杯")
                        setCups(cups)
                    }) {
                        Text("\(cups)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(waterData.totalCups == cups ? .white : Theme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(waterData.totalCups == cups
                                          ? AnyShapeStyle(Theme.primaryGradient)
                                          : AnyShapeStyle(Color.gray.opacity(0.10)))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(cardBG)
    }

    private var intervalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Theme.primary)
                Text("提醒间隔")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            HStack(spacing: 12) {
                // 减号
                Button(action: { adjustInterval(-1) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(canDecreaseInterval ? AnyShapeStyle(Theme.primaryGradient) : AnyShapeStyle(Color.gray.opacity(0.35))))
                }
                .buttonStyle(.plain)
                .disabled(!canDecreaseInterval)

                // 数值显示
                VStack(spacing: 0) {
                    Text(intervalInput)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.primaryGradient)
                    Text(intervalUnit.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                }
                .frame(width: 70)

                // 加号
                Button(action: { adjustInterval(1) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Theme.primaryGradient))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                // 单位切换
                Picker("", selection: $intervalUnit) {
                    ForEach(IntervalUnit.allCases, id: \.self) { u in
                        Text(u.rawValue).tag(u)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
                .onChange(of: intervalUnit) { oldUnit, newUnit in
                    AppLog.log("UI", "切换间隔单位: \(oldUnit.rawValue) -> \(newUnit.rawValue)")
                    applyInterval()
                }
            }
            .frame(maxWidth: .infinity)

            Text("最短 10 秒，设置后立即生效")
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(16)
        .background(cardBG)
    }

    private var canDecreaseInterval: Bool {
        guard let cur = Double(intervalInput) else { return true }
        let minVal: Double = intervalUnit == .second ? 10 : 1
        return cur > minVal
    }

    private func adjustInterval(_ delta: Int) {
        guard let cur = Double(intervalInput) else { return }
        var next = cur + Double(delta)
        // 单位为秒时最短 10；分钟/小时最小为 1
        let minVal: Double = intervalUnit == .second ? 10 : 1
        if next < minVal { next = minVal }
        // 若当前已是下限且还要减小，则不再变动
        if cur <= minVal && delta < 0 { return }
        AppLog.log("UI", "调整提醒间隔: \(cur)\(intervalUnit.rawValue) -> \(next)\(intervalUnit.rawValue)")
        intervalInput = String(format: "%g", next)
        applyInterval()
    }

    private func applyInterval() {
        guard let v = Double(intervalInput), v > 0 else { return }
        // 单位为秒时低于 10 不生效
        if intervalUnit == .second && v < 10 { return }
        let totalSeconds = v * intervalUnit.seconds
        AppLog.log("UI", "应用提醒间隔: \(v)\(intervalUnit.rawValue) = \(totalSeconds)s")
        waterData.setReminderInterval(totalSeconds)
        flashSaved()
    }

    private func syncIntervalFromData() {
        let total = waterData.reminderInterval
        if total >= 3600 {
            intervalUnit = .hour
            intervalInput = String(format: "%g", total / 3600)
        } else if total >= 60 {
            intervalUnit = .minute
            intervalInput = String(format: "%g", total / 60)
        } else {
            intervalUnit = .second
            // 秒数至少显示 10
            intervalInput = String(format: "%g", max(10, total))
        }
    }

    private var aboutCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Theme.primary)
                Text("关于")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }
            HStack {
                Text("版本")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("1.0.0")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
            }
            HStack {
                Text("数据存储")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
                Spacer()
                Text("本地")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
            }
        }
        .padding(16)
        .background(cardBG)
    }

    private var cardBG: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Theme.cardBG)
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )
    }

    private var canDecreaseCups: Bool { waterData.totalCups > 1 }

    private func adjustCups(_ delta: Int) {
        let newValue = max(1, min(20, waterData.totalCups + delta))
        AppLog.log("UI", "调整目标杯数: \(waterData.totalCups) -> \(newValue)")
        setCups(newValue)
    }

    private func setCups(_ cups: Int) {
        waterData.setTotalCups(cups)
        cupsInput = "\(cups)"
        flashSaved()
    }

    private func validateInput(_ value: String) {
        if let v = Int(value), v >= 1, v <= 20 {
            waterData.setTotalCups(v)
            flashSaved()
        }
    }

    private func flashSaved() {
        withAnimation { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showSavedToast = false }
        }
    }
}
