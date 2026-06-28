import SwiftUI

@main
struct CipherKeysApp: App {
    @StateObject private var model = SettingsModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .tint(.accentColor)
        }
    }
}
