import SwiftUI
import AppKit

@main
struct DrinkWaterApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(waterData: WaterData.shared)
                .frame(width: 320, height: 260)
        }
    }
}
