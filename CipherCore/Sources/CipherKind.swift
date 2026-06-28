import Foundation

/// The registry of every cipher CipherKeys ships, in display order. The app and the
/// keyboard both list and construct ciphers through this enum, so adding a cipher is:
/// implement the type, add a case here, wire it in `make(caesarShift:)`.
public enum CipherKind: String, CaseIterable, Identifiable {
    case caesar
    case rot13
    case atbash
    case t9

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .caesar: return "Caesar"
        case .rot13:  return "ROT13"
        case .atbash: return "Atbash"
        case .t9:     return "T9 Multitap"
        }
    }

    /// A short, honest description for the UI. These are toys, not security.
    public var blurb: String {
        switch self {
        case .caesar: return "Shift every letter by a fixed amount."
        case .rot13:  return "Caesar fixed at 13 — its own inverse."
        case .atbash: return "Mirror the alphabet: A↔Z, B↔Y…"
        case .t9:     return "Old-school phone keypad multitap."
        }
    }

    /// SF Symbol used to represent this cipher in the UI.
    public var symbolName: String {
        switch self {
        case .caesar: return "arrow.left.arrow.right"
        case .rot13:  return "arrow.triangle.2.circlepath"
        case .atbash: return "arrow.left.and.right.righttriangle.left.righttriangle.right"
        case .t9:     return "phone.fill"
        }
    }

    /// Whether this cipher reads the Caesar shift setting.
    public var usesShift: Bool { self == .caesar }

    /// Construct the concrete cipher. `caesarShift` is ignored by non-Caesar kinds.
    public func make(caesarShift: Int = 3) -> any Cipher {
        switch self {
        case .caesar: return CaesarCipher(shift: caesarShift)
        case .rot13:  return ROT13Cipher()
        case .atbash: return AtbashCipher()
        case .t9:     return T9Cipher()
        }
    }
}
