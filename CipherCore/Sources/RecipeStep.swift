import Foundation

/// One invertible step in a Tier-2 cipher recipe. Every case MUST be reversible:
/// applying with `decoding: true` exactly undoes `decoding: false`. That invariant is
/// what lets `RecipeCipher` guarantee `decode(encode(x)) == x` for any pipeline.
public enum RecipeStep: Codable, Equatable, Hashable {
    case caesar(shift: Int)
    case rot13
    case atbash
    case reverse
    case vigenere(keyword: String)

    /// Apply this step. `decoding == true` runs the inverse transform.
    public func apply(_ text: String, decoding: Bool) -> String {
        switch self {
        case .caesar(let shift):
            // Inverse of a Caesar shift is the negative shift.
            return CaesarCipher(shift: decoding ? -shift : shift).encode(text)
        case .rot13:
            return ROT13Cipher().encode(text)        // self-inverse
        case .atbash:
            return AtbashCipher().encode(text)        // self-inverse
        case .reverse:
            return String(text.reversed())            // self-inverse (reverses by grapheme)
        case .vigenere(let keyword):
            return VigenereCipher(keyword: keyword).transform(text, decoding: decoding)
        }
    }

    // MARK: - Authoring helpers (used by the recipe builder UI)

    /// The step kinds a user can add, with default parameters.
    public static var palette: [RecipeStep] {
        [.caesar(shift: 3), .rot13, .atbash, .reverse, .vigenere(keyword: "key")]
    }

    public var kindName: String {
        switch self {
        case .caesar:   return "Caesar"
        case .rot13:    return "ROT13"
        case .atbash:   return "Atbash"
        case .reverse:  return "Reverse"
        case .vigenere: return "Vigenère"
        }
    }

    /// Short one-line summary including parameters, e.g. "Caesar +3", "Vigenère “key”".
    public var summary: String {
        switch self {
        case .caesar(let shift):    return "Caesar +\(shift)"
        case .rot13:                return "ROT13"
        case .atbash:               return "Atbash"
        case .reverse:              return "Reverse"
        case .vigenere(let keyword): return "Vigenère “\(keyword)”"
        }
    }

    public var symbolName: String {
        switch self {
        case .caesar:   return "arrow.left.arrow.right"
        case .rot13:    return "arrow.triangle.2.circlepath"
        case .atbash:   return "arrow.left.and.right.righttriangle.left.righttriangle.right"
        case .reverse:  return "arrow.uturn.left"
        case .vigenere: return "key.fill"
        }
    }
}
