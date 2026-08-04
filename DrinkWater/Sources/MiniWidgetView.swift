import SwiftUI

// 桌面常驻小窗
struct MiniWidgetView: View {
    @ObservedObject var waterData: WaterData
    let onTap: () -> Void
    let onSettings: () -> Void

    @State private var isHovering = false
    @State private var showResetAlert = false

    var body: some View {
        VStack(spacing: 12) {
            // 顶部：图标 + 标题 + 设置按钮
            HStack(spacing: 8) {
                Text(waterData.hasReachedGoal ? "🎉" : "💧")
                    .font(.system(size: 22))
                Text("饮水进度")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                if isHovering {
                    Button(action: onSettings) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("打开设置")
                }
            }

            // 杯数大数字
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(waterData.currentCups)")
                    .font(.system(size: 68, weight: .bold, design: .rounded))
                    .foregroundColor(waterData.hasReachedGoal ? .green : .blue)
                Text("/ \(waterData.totalCups)")
                    .font(.system(size: 30, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            // 进度条
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.12))
                        .frame(height: 12)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: waterData.hasReachedGoal
                                    ? [Color.green, Color.mint]
                                    : [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(g.size.width * waterData.progress, waterData.progress > 0 ? 8 : 0), height: 12)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: waterData.progress)
                }
            }
            .frame(height: 12)

            // 底部：重置按钮 + "+1" 按钮
            HStack(spacing: 8) {
                // 重置按钮
                Button(action: { showResetAlert = true }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(waterData.currentCups > 0 ? .red.opacity(0.85) : .secondary)
                        .frame(width: 50, height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(waterData.currentCups > 0
                                      ? Color.red.opacity(0.10)
                                      : Color.gray.opacity(0.10))
                        )
                }
                .buttonStyle(.plain)
                .disabled(waterData.currentCups == 0)
                .help("重置今日数据")

                // "+1" 按钮
                Button(action: onTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                        Text("喝一杯")
                            .font(.system(size: 22, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(waterData.hasReachedGoal ? Color.green : Color.blue)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(width: 360, height: 240)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.18), radius: 20, y: 6)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .alert("重置今日数据？", isPresented: $showResetAlert) {
            Button("取消", role: .cancel) {}
            Button("确认重置", role: .destructive) {
                waterData.resetToday()
            }
        } message: {
            Text("当前 \(waterData.currentCups) 杯饮水记录将被清零。")
        }
    }
}
