import SwiftUI
import CipherCore

/// Shared cipher selector used by the Encode and Decode screens. Lists the built-in
/// ciphers and any saved recipes, and reveals the Caesar shift stepper when relevant.
struct SelectionPicker: View {
    @Binding var selection: CipherSelection
    @Binding var caesarShift: Int
    let recipes: [CipherRecipe]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Cipher", selection: $selection) {
                Section("Built-in") {
                    ForEach(CipherKind.allCases) { kind in
                        Label(kind.displayName, systemImage: kind.symbolName)
                            .tag(CipherSelection.builtin(kind))
                    }
                }
                if !recipes.isEmpty {
                    Section("Your recipes") {
                        ForEach(recipes) { recipe in
                            Label(recipe.name, systemImage: "wand.and.stars")
                                .tag(CipherSelection.recipe(recipe.id))
                        }
                    }
                }
            }
            .pickerStyle(.menu)

            if case .builtin(let kind) = selection {
                Text(kind.blurb).font(.footnote).foregroundStyle(.secondary)
                if kind.usesShift {
                    Stepper(value: $caesarShift, in: 1...25) {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right")
                            Text("Shift")
                            Spacer()
                            Text("\(caesarShift)").monospacedDigit().foregroundStyle(.secondary)
                        }
                    }
                }
            } else if case .recipe(let id) = selection,
                      let recipe = recipes.first(where: { $0.id == id }) {
                Text(recipe.steps.map(\.summary).joined(separator: " → "))
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
