import SwiftUI
import CipherCore

/// Observable wrapper around `CipherSettings`. Every change is persisted to the App
/// Group suite immediately, so the keyboard and the Decode action extension pick it
/// up the next time they read.
@MainActor
final class SettingsModel: ObservableObject {
    @Published var selection: CipherSelection {
        didSet { CipherSettings.shared.selection = selection }
    }

    @Published var caesarShift: Int {
        didSet { CipherSettings.shared.caesarShift = caesarShift }
    }

    @Published var recipes: [CipherRecipe] {
        didSet { CipherSettings.shared.recipes = recipes }
    }

    init() {
        let stored = CipherSettings.shared
        selection = stored.selection
        caesarShift = stored.caesarShift
        recipes = stored.recipes
    }

    /// Re-read from the suite (e.g. after returning to the foreground — the keyboard
    /// may have changed the selection via its inline picker).
    func reload() {
        let stored = CipherSettings.shared
        if recipes != stored.recipes { recipes = stored.recipes }
        if selection != stored.selection { selection = stored.selection }
        if caesarShift != stored.caesarShift { caesarShift = stored.caesarShift }
    }

    // MARK: - Resolving ciphers (uses the model's own live values)

    func cipher(for selection: CipherSelection) -> any Cipher {
        switch selection {
        case .builtin(let kind):
            return kind.make(caesarShift: caesarShift)
        case .recipe(let id):
            if let recipe = recipes.first(where: { $0.id == id }) { return RecipeCipher(recipe) }
            return CaesarCipher(shift: caesarShift)
        }
    }

    var currentCipher: any Cipher { cipher(for: selection) }

    func displayName(for selection: CipherSelection) -> String {
        switch selection {
        case .builtin(let kind): return kind.displayName
        case .recipe(let id):    return recipes.first(where: { $0.id == id })?.name ?? "Recipe"
        }
    }

    /// All options in display order: built-ins, then saved recipes.
    var availableSelections: [CipherSelection] {
        CipherKind.allCases.map { .builtin($0) } + recipes.map { .recipe($0.id) }
    }

    // MARK: - Recipe management

    func addRecipe(_ recipe: CipherRecipe, select: Bool = true) {
        recipes.append(recipe)
        if select { selection = .recipe(recipe.id) }
    }

    func updateRecipe(_ recipe: CipherRecipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
        }
    }

    func deleteRecipe(id: UUID) {
        recipes.removeAll { $0.id == id }
        if selection == .recipe(id) { selection = .builtin(.caesar) }
    }

    /// Import a recipe from a `cipherkeys://` deep link. De-dupes by name+steps so
    /// re-importing doesn't pile up copies. Returns the imported recipe's name.
    @discardableResult
    func importRecipe(from url: URL) -> String? {
        guard let incoming = RecipeShare.recipe(from: url) else { return nil }
        if let existing = recipes.first(where: { $0.name == incoming.name && $0.steps == incoming.steps }) {
            selection = .recipe(existing.id)
            return existing.name
        }
        let new = CipherRecipe(id: UUID(), name: incoming.name, steps: incoming.steps)
        addRecipe(new)
        return new.name
    }
}
