import SwiftUI

struct SettingsView: View {
    @ObservedObject var waterData: WaterData
    @State private var cupsInput: String = ""
    @State private var showSavedToast = false

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.accentColor)
                Text("饮水提醒设置")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, 16)

            VStack(spacing: 24) {
                // 目标杯数设置
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.accentColor)
                        Text("每日计划总杯数")
                            .font(.system(size: 14, weight: .medium))
                    }

                    HStack(spacing: 10) {
                        // 减号按钮
                        Button(action: { adjustCups(-1) }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)

                        // 杯数显示
                        TextField("", text: $cupsInput)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .frame(width: 80)
                            .textFieldStyle(.plain)
                            .onSubmit { saveSettings() }
                            .onChange(of: cupsInput) { _, _ in
                                validateInput()
                            }

                        Text("杯")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)

                        // 加号按钮
                        Button(action: { adjustCups(1) }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)

                // 快捷设置
                VStack(alignment: .leading, spacing: 10) {
                    Text("快捷设置")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        ForEach([4, 6, 8, 10, 12], id: \.self) { cups in
                            Button(action: { setCups(cups) }) {
                                Text("\(cups)")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(waterData.totalCups == cups ? .white : .primary)
                                    .frame(width: 44, height: 30)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(
                                                waterData.totalCups == cups
                                                    ? AnyShapeStyle(Color.accentColor)
                                                    : AnyShapeStyle(Color.blue.opacity(0.1))
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 16)

            Spacer()

            // Toast 提示
            if showSavedToast {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("设置已保存")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
                .transition(.opacity)
            }
        }
        .frame(width: 320, height: 260)
        .onAppear {
            cupsInput = "\(waterData.totalCups)"
        }
    }

    private func adjustCups(_ delta: Int) {
        let newValue = max(1, min(20, waterData.totalCups + delta))
        setCups(newValue)
    }

    private func setCups(_ cups: Int) {
        waterData.setTotalCups(cups)
        cupsInput = "\(cups)"
        flashSaved()
    }

    private func validateInput() {
        if let value = Int(cupsInput), value >= 1, value <= 20 {
            waterData.setTotalCups(value)
            flashSaved()
        }
    }

    private func saveSettings() {
        if let value = Int(cupsInput), value >= 1, value <= 20 {
            waterData.setTotalCups(value)
            flashSaved()
        }
    }

    private func flashSaved() {
        withAnimation {
            showSavedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSavedToast = false
            }
        }
    }
}


