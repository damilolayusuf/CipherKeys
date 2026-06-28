import SwiftUI
import CipherCore

/// "Recipes" tab: list, create, edit, share, and delete user-built ciphers (Tier-2
/// composable pipelines).
struct RecipesView: View {
    @EnvironmentObject private var model: SettingsModel
    @State private var editing: CipherRecipe?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if model.recipes.isEmpty {
                        Text("No recipes yet. Build one by chaining steps like Caesar → Reverse → Vigenère, then share it with a friend.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(model.recipes) { recipe in
                        Button {
                            editing = recipe
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.name).font(.headline).foregroundStyle(.primary)
                                Text(recipe.steps.isEmpty
                                     ? "No steps (identity)"
                                     : recipe.steps.map(\.summary).joined(separator: " → "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { model.deleteRecipe(id: model.recipes[index].id) }
                    }
                } footer: {
                    Text("Recipes run their steps in order to encode, and in reverse to decode. Anyone with the recipe (or its share link) can decode — fun, not security.")
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editing = CipherRecipe(name: "New Recipe", steps: [.caesar(shift: 3)])
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $editing) { recipe in
                RecipeEditorView(recipe: recipe) { saved in
                    if model.recipes.contains(where: { $0.id == saved.id }) {
                        model.updateRecipe(saved)
                    } else {
                        model.addRecipe(saved)
                    }
                }
            }
        }
    }
}
