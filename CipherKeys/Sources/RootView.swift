import SwiftUI
import CipherCore

struct RootView: View {
    @EnvironmentObject private var model: SettingsModel
    @Environment(\.scenePhase) private var scenePhase

    @State private var importedName: String?
    @State private var showImportAlert = false

    var body: some View {
        TabView {
            EncodeView()
                .tabItem { Label("Encode", systemImage: "lock.fill") }

            DecodeView()
                .tabItem { Label("Decode", systemImage: "lock.open.fill") }

            RecipesView()
                .tabItem { Label("Recipes", systemImage: "wand.and.stars") }

            EnableKeyboardView()
                .tabItem { Label("Setup", systemImage: "keyboard") }
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
