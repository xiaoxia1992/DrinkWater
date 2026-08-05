import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private let waterData = WaterData.shared
    private var timer: Timer?
    private var widgetWindow: NSWindow?
    private var reminderWindow: NSWindow?
    private var isReminderShowing = false
    private var intervalObserver: AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 先触发日志目录初始化
        let logDir = AppLog.logDirectory
        AppLog.log("APP", "应用启动")
        AppLog.log("APP", "日志目录: \(logDir)")
        AppLog.log("APP", "NSHomeDirectory: \(NSHomeDirectory())")
        setupDesktopWidget()
        AppLog.log("APP", "桌面面板已创建")

        // 自适应轮询：检测间隔 = min(30, max(5, reminderInterval))
        rebuildTimer()

        // 监听间隔变化，动态重建定时器
        intervalObserver = waterData.$reminderInterval
            .removeDuplicates()
            .sink { [weak self] _ in self?.rebuildTimer() }

        NSApp.setActivationPolicy(.regular)
        AppLog.log("APP", "初始化完成: 当前\(waterData.currentCups)/\(waterData.totalCups)杯, 已达目标=\(waterData.hasReachedGoal), 间隔=\(waterData.reminderInterval)s")
    }

    private func rebuildTimer() {
        timer?.invalidate()
        let pollInterval = min(30, max(5, waterData.reminderInterval))
        AppLog.log("TIMER", "重建定时器: 轮询间隔=\(pollInterval)s")
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.waterData.checkAndResetIfNeeded()
            self?.checkReminder()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    // MARK: - 桌面常驻面板

    private func setupDesktopWidget() {
        let panelView = UnifiedPanelView(waterData: waterData)

        let hosting = NSHostingController(rootView: panelView)
        let window = NSWindow(contentViewController: hosting)
        window.setContentSize(NSSize(width: 420, height: 465))
        window.styleMask = [.borderless, .nonactivatingPanel]
        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.isMovable = true
        window.isMovableByWindowBackground = true
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        // 右上角放置
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = window.frame.size
            window.setFrameOrigin(NSPoint(
                x: screenFrame.maxX - windowSize.width - 20,
                y: screenFrame.maxY - windowSize.height - 30
            ))
        }

        window.orderFrontRegardless()
        widgetWindow = window
    }

    // MARK: - 喝水提醒

    private func checkReminder() {
        guard !isReminderShowing else { return }
        // 已达成今日目标，不再提醒
        guard !waterData.hasReachedGoal else { return }
        // 距离上次提醒弹出 >= 设定间隔 才再弹
        let elapsed = waterData.secondsSinceLastReminder
        let interval = waterData.reminderInterval
        AppLog.log("CHECK", "检测提醒: 已过\(Int(elapsed))s / 间隔\(Int(interval))s => \(elapsed >= interval ? "触发" : "跳过")")
        guard elapsed >= interval else { return }
        showReminder()
    }

    private func showReminder() {
        isReminderShowing = true
        // 记录本次提醒时间
        waterData.markReminderShown()
        AppLog.log("REMINDER", "弹出喝水提醒")

        let reminderView = ReminderView {
            self.dismissReminder()
        }

        let hosting = NSHostingController(rootView: reminderView)
        let window = NSWindow(contentViewController: hosting)

        // 覆盖全屏
        if let screen = NSScreen.main {
            window.setFrame(screen.frame, display: true)
        } else {
            window.setFrame(NSRect(x: 0, y: 0, width: 800, height: 600), display: true)
        }

        window.styleMask = [.borderless]
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        window.hidesOnDeactivate = false

        window.makeKeyAndOrderFront(nil)
        reminderWindow = window
    }

    private func dismissReminder() {
        isReminderShowing = false
        reminderWindow?.close()
        reminderWindow = nil
        AppLog.log("REMINDER", "关闭喝水提醒")
    }

    // MARK: - 生命周期

    func applicationWillTerminate(_ notification: Notification) {
        AppLog.log("APP", "应用退出")
        timer?.invalidate()
        intervalObserver?.cancel()
        dismissReminder()
    }
}
