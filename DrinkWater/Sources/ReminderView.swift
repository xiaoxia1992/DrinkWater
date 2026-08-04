import SwiftUI

struct ReminderView: View {
    let onDismiss: () -> Void

    @State private var pulse: CGFloat = 1.0
    @State private var dropY: CGFloat = -60
    @State private var dropOpacity: Double = 1
    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: Double = 0.6
    @State private var swirlAngle: Double = 0
    @State private var jiggle: CGFloat = -1   // 水滴液态弹性 (-1..1)

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height) * 0.70
                let dropSize = size * 0.70  // 主水滴放大2倍（原 size * 0.35）
                let dropSymbol = Image(systemName: "drop.fill")
                    .font(.system(size: dropSize))

                // 水滴 + 文字整体居中
                VStack(spacing: 16) {
                    ZStack {
                        // 背景光晕
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.blue.opacity(0.15), Color.clear],
                                    center: .center, startRadius: size * 0.3, endRadius: size * 0.8
                                )
                            )
                            .frame(width: size * 1.3, height: size * 1.3)

                        // 涟漪
                        Circle()
                            .stroke(Color.blue.opacity(rippleOpacity * 0.3), lineWidth: 2)
                            .frame(width: size * rippleScale, height: size * rippleScale)
                            .scaleEffect(pulse)
                            .opacity(rippleOpacity)
                        Circle()
                            .stroke(Color.purple.opacity(rippleOpacity * 0.2), lineWidth: 1.5)
                            .frame(width: size * rippleScale * 0.75, height: size * rippleScale * 0.75)
                            .scaleEffect(pulse * 0.85)
                            .opacity(rippleOpacity * 0.7)

                        // 主水滴 - 真实感渲染（径向渐变自带立体高光，零遮罩更稳定）+ 放大2倍
                        ZStack {
                            // 水滴主体：左上亮白高光 → 浅蓝 → 中蓝 → 深蓝底部
                            dropSymbol
                                .foregroundStyle(
                                    RadialGradient(
                                        colors: [
                                            Color.white,
                                            Color(red: 0.78, green: 0.92, blue: 1.0),
                                            Color(red: 0.36, green: 0.62, blue: 1.0),
                                            Color(red: 0.14, green: 0.28, blue: 0.74)
                                        ],
                                        center: UnitPoint(x: 0.32, y: 0.40),
                                        startRadius: 0,
                                        endRadius: dropSize * 0.65
                                    )
                                )
                                .scaleEffect(x: 1 - jiggle * 0.10, y: 1 + jiggle * 0.14)
                                .scaleEffect(pulse)
                                .offset(y: dropY)
                                .opacity(dropOpacity)
                                .shadow(color: .blue.opacity(0.45), radius: 30, y: 15)

                            Text("尊敬的主人\n您该喝水了！")
                                .font(.system(size: dropSize * 0.13, weight: .heavy, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .shadow(color: .blue.opacity(0.6), radius: 2)
                                .scaleEffect(pulse)
                                .offset(y: dropY + dropSize * 0.05)
                                .opacity(dropOpacity)
                        }

                        // 小水滴装饰
                        ForEach(0..<6, id: \.self) { i in
                            let angle = Double(i) * 60 + swirlAngle
                            let r = size * 0.48
                            Image(systemName: "drop.fill")
                                .font(.system(size: size * 0.06))
                                .foregroundColor(Color.blue.opacity(0.4))
                                .offset(
                                    x: r * cos(angle * .pi / 180),
                                    y: r * sin(angle * .pi / 180) + size * 0.05
                                )
                        }
                    }
                    .frame(width: size, height: size)

                    // 紧挨水滴的提示
                    Text("点击任意位置关闭")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 24)
                        .offset(y: -100)
                }
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .onTapGesture { onDismiss() }
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulse = 1.15
        }
        // 水滴液态弹性（纵向拉伸/横向收缩来回抖动）
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
            jiggle = 1
        }
        withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
            rippleScale = 1.2
            rippleOpacity = 0
        }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            swirlAngle = 360
        }
        withAnimation(.interpolatingSpring(stiffness: 100, damping: 8)) {
            dropY = 0
        }
    }
}
