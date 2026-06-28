import Foundation

/// Shared settings backed by the App Group `UserDefaults` suite. This is the ONLY
/// channel between the main app, the keyboard extension, and the Decode action
/// extension — the app writes the user's selection, Caesar shift, and saved recipes;
/// the extensions read them. No networking, no other IPC.
public final class CipherSettings {
    /// App Group identifier. Must match the App Groups capability on the app and BOTH
    /// extensions. If you fork this, change the `com.xkabiir` prefix to your own and
    /// update the capability + entitlements to match.
    public static let appGroupID = "group.com.xkabiir.cipherkeys"

    /// Default Caesar shift when nothing has been chosen yet.
    public static let defaultCaesarShift = 3

    public static let shared = CipherSettings()

    private let defaults: UserDefaults

    private enum Key {
        static let selection = "cipherSelection"
        static let caesarShift = "caesarShift"
        static let recipes = "recipesData"
        static let legacyKind = "selectedCipherKind"   // migrated from the original schema
    }

    /// Falls back to `.standard` if the App Group suite is unavailable (e.g. the
    /// capability isn't configured yet), so the app and extensions still function
    /// locally instead of crashing.
    public init(suiteName: String = CipherSettings.appGroupID) {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
        self.defaults.register(defaults: [
            Key.caesarShift: CipherSettings.defaultCaesarShift
        ])
    }

    // MARK: - Caesar shift (built-in Caesar only)

    public var caesarShift: Int {
        get {
            let value = defaults.integer(forKey: Key.caesarShift)
            // 0 would be the identity transform; treat it as "unset" and default.
            return value == 0 ? CipherSettings.defaultCaesarShift : value
        }
        set { defaults.set(newValue, forKey: Key.caesarShift) }
    }

    // MARK: - Selection (built-in or recipe)

    public var selection: CipherSelection {
        get {
            if let raw = defaults.string(forKey: Key.selection),
               let selection = CipherSelection(storageString: raw) {
                return selection
            }
            // Migrate from the original "selectedCipherKind" string if present.
            if let raw = defaults.string(forKey: Key.legacyKind),
               let kind = CipherKind(rawValue: raw) {
                return .builtin(kind)
            }
            return .builtin(.caesar)
        }
        set { defaults.set(newValue.storageString, forKey: Key.selection) }
    }

    // MARK: - Recipes

    public var recipes: [CipherRecipe] {
        get {
            guard let data = defaults.data(forKey: Key.recipes),
                  let list = try? JSONDecoder().decode([CipherRecipe].self, from: data) else {
                return []
            }
            return list
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Key.recipes)
            }
        }
    }

    public func recipe(withID id: UUID) -> CipherRecipe? {
        recipes.first { $0.id == id }
    }

    // MARK: - Resolving a selection to a concrete cipher

    /// Every selectable option in display order: built-ins first, then saved recipes.
    public func availableSelections() -> [CipherSelection] {
        CipherKind.allCases.map { .builtin($0) } + recipes.map { .recipe($0.id) }
    }

    /// Human-readable name for a selection (looks up recipe names as needed).
    public func displayName(for selection: CipherSelection) -> String {
        switch selection {
        case .builtin(let kind): return kind.displayName
        case .recipe(let id):    return recipe(withID: id)?.name ?? "Recipe"
        }
    }

    /// Construct the concrete cipher for a selection. Unknown recipe ids fall back to
    /// Caesar so callers never get a nil cipher.
    public func cipher(for selection: CipherSelection) -> any Cipher {
        switch selection {
        case .builtin(let kind):
            return kind.make(caesarShift: caesarShift)
        case .recipe(let id):
            if let recipe = recipe(withID: id) { return RecipeCipher(recipe) }
            return CaesarCipher(shift: caesarShift)
        }
    }

    /// The currently selected cipher, fully constructed from the stored settings.
    public func currentCipher() -> any Cipher {
        cipher(for: selection)
    }
}
