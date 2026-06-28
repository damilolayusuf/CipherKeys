import SwiftUI
import CipherCore

struct RootView: View {
    @EnvironmentObject private var model: SettingsModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var importedName: String?
    @State private var showImportAlert = false
    @State private var selection: AppTab = RootView.initialTab

    private enum AppTab: String { case encode, decode, recipes, setup }

    /// UI tests (fastlane snapshot) preselect a tab via the UITEST_TAB launch
    /// environment so navigation works identically on iPhone and iPad. In normal
    /// use this is unset and the app opens on Encode.
    private static var initialTab: AppTab {
        if let raw = ProcessInfo.processInfo.environment["UITEST_TAB"],
           let tab = AppTab(rawValue: raw) {
            return tab
        }
        return .encode
    }

    var body: some View {
        TabView(selection: $selection) {
            EncodeView()
                .tabItem { Label("Encode", systemImage: "lock.fill") }
                .tag(AppTab.encode)

            DecodeView()
                .tabItem { Label("Decode", systemImage: "lock.open.fill") }
                .tag(AppTab.decode)

            RecipesView()
                .tabItem { Label("Recipes", systemImage: "wand.and.stars") }
                .tag(AppTab.recipes)

            EnableKeyboardView()
                .tabItem { Label("Setup", systemImage: "keyboard") }
                .tag(AppTab.setup)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { model.reload() }
        }
        .onOpenURL { url in
            // Importing a recipe is user-initiated (they tapped a link/QR). We add the
            // recipe locally and select it — no network, nothing destructive.
            if let name = model.importRecipe(from: url) {
                importedName = name
                showImportAlert = true
            }
        }
        .alert("Recipe imported", isPresented: $showImportAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("“\(importedName ?? "")” was added to your recipes and selected. Remember: a shared recipe is reversible by anyone who has it.")
        }
    }
}

/// Small reusable banner reminding the user this is a toy, not security.
struct DisclaimerBanner: View {
    var body: some View {
        Label("These are classic ciphers — fun and reversible by anyone. Not real security.",
              systemImage: "info.circle")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}
