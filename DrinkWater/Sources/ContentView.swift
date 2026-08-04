import SwiftUI

struct ContentView: View {
    @ObservedObject var waterData: WaterData
    @State private var buttonScale: CGFloat = 1.0
    @State private var showConfetti = false
    @State private var showResetAlert = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("💧 饮水提醒")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button(action: openSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("设置")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider().padding(.horizontal, 16)

            if waterData.hasReachedGoal {
                celebrationView
            } else {
                normalView
            }

            Spacer(minLength: 0)

            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text("每日零点自动清零")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: { showResetAlert = true }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 9))
                        Text("重置")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 16)
        }
        .frame(width: 300, height: 420)
        .onAppear { waterData.checkAndResetIfNeeded() }
        .alert("重置今日数据？", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) {}
            Button("确认重置", role: .destructive) {
                waterData.resetToday()
            }
        } message: {
            Text("当前 \(waterData.currentCups) 杯饮水记录将被清零，此操作不可恢复。")
        }
    }

    private var normalView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(waterData.currentCups)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                    Text("/ \(waterData.totalCups)")
                        .font(.system(size: 22, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Text("今日已饮水杯数")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)

            VStack(spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.12))
                            .frame(height: 16)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [Color.blue.opacity(0.6), Color.blue],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(geometry.size.width * waterData.progress, waterData.progress > 0 ? 8 : 0),
                                   height: 16)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: waterData.progress)
                    }
                }
                .frame(height: 16)
                Text("\(Int(waterData.progress * 100))%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)

            Button(action: onAddCup) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("喝了一杯水")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .scaleEffect(buttonScale)
            .padding(.horizontal, 20)
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
    }

    private var celebrationView: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("🎉🏆🎉")
                .font(.system(size: 40))
                .scaleEffect(showConfetti ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.5), value: showConfetti)
            Text("🎊 太棒了！🎊")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.accentColor)
            Text("今日已完成 \(waterData.totalCups) 杯饮水目标！")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text("继续保持，健康每一天 💪")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Button(action: onAddCup) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("再喝一杯")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            Spacer()
        }
        .padding(.horizontal, 20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation { showConfetti = true }
            }
        }
    }

    private func onAddCup() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { buttonScale = 0.85 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { buttonScale = 1.0 }
        }
        waterData.incrementCup()
    }

    private func openSettings() {
        if let w = NSApp.windows.first(where: { $0.title == "饮水提醒设置" }) {
            w.makeKeyAndOrderFront(nil)
            return
        }
        let vc = NSHostingController(rootView: SettingsView(waterData: waterData))
        let w = NSWindow(contentViewController: vc)
        w.title = "饮水提醒设置"
        w.setContentSize(NSSize(width: 320, height: 260))
        w.styleMask = [.titled, .closable]
        w.center()
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)
    }
}
