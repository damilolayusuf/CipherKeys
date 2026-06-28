import Foundation

/// What the keyboard/app is currently set to: either one of the built-in ciphers or
/// a user-built recipe (referenced by id). Persisted as a single string in the App
/// Group suite.
public enum CipherSelection: Equatable, Hashable {
    case builtin(CipherKind)
    case recipe(UUID)

    /// Stable string form for storage, e.g. "builtin:caesar" or "recipe:<uuid>".
    public var storageString: String {
        switch self {
        case .builtin(let kind): return "builtin:" + kind.rawValue
        case .recipe(let id):    return "recipe:" + id.uuidString
        }
    }

    public init?(storageString: String) {
        if storageString.hasPrefix("builtin:"),
           let kind = CipherKind(rawValue: String(storageString.dropFirst("builtin:".count))) {
            self = .builtin(kind)
        } else if storageString.hasPrefix("recipe:"),
                  let id = UUID(uuidString: String(storageString.dropFirst("recipe:".count))) {
            self = .recipe(id)
        } else {
            return nil
        }
    }
}
