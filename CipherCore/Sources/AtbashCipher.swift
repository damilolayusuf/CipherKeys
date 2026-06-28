import Foundation

/// Atbash: reflect the alphabet so A↔Z, B↔Y, C↔X … Each case is mirrored
/// independently and every non-letter passes through untouched. Like ROT13 it is
/// self-inverse, so `decode` just calls `encode`.
///
/// Scope note: only ASCII A–Z / a–z are reflected. Accented or non-Latin letters
/// (é, ñ, я, あ) are intentionally left untouched — there is no canonical Atbash
/// mirror for them. See README for the rationale.
public struct AtbashCipher: Cipher {
    public var id: String { CipherKind.atbash.rawValue }
    public var name: String { "Atbash" }

    public init() {}

    public func encode(_ text: String) -> String {
        var view = String.UnicodeScalarView()
        view.reserveCapacity(text.unicodeScalars.count)
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 65...90:  // A–Z → Z - (c - A)
                view.append(Unicode.Scalar(90 - (scalar.value - 65))!)
            case 97...122: // a–z → z - (c - a)
                view.append(Unicode.Scalar(122 - (scalar.value - 97))!)
            default:
                view.append(scalar)
            }
        }
        return String(view)
    }

    /// Atbash is its own inverse.
    public func decode(_ text: String) -> String { encode(text) }
}
