import Foundation

/// Classic Caesar shift: rotate the ASCII letters A–Z and a–z by `shift` positions,
/// wrapping within each case. Everything else — digits, punctuation, whitespace,
/// emoji, accented/non-Latin characters — passes through untouched.
///
/// `decode` is simply `encode` with the opposite shift. The shift is reduced modulo
/// 26, so a shift of 0 or 26 is the identity and negative shifts wrap correctly.
public struct CaesarCipher: Cipher {
    public let shift: Int

    public var id: String { CipherKind.caesar.rawValue }
    public var name: String { "Caesar (shift \(normalizedShift))" }

    /// Shift folded into 0..<26 so the rotation math is always valid.
    private var normalizedShift: Int { ((shift % 26) + 26) % 26 }

    public init(shift: Int) {
        self.shift = shift
    }

    public func encode(_ text: String) -> String {
        rotate(text, by: normalizedShift)
    }

    public func decode(_ text: String) -> String {
        rotate(text, by: (26 - normalizedShift) % 26)
    }

    private func rotate(_ text: String, by amount: Int) -> String {
        guard amount != 0 else { return text }
        var view = String.UnicodeScalarView()
        view.reserveCapacity(text.unicodeScalars.count)
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 65...90:  // A–Z
                view.append(shiftScalar(scalar.value, base: 65, by: amount))
            case 97...122: // a–z
                view.append(shiftScalar(scalar.value, base: 97, by: amount))
            default:
                view.append(scalar)
            }
        }
        return String(view)
    }

    private func shiftScalar(_ value: UInt32, base: UInt32, by amount: Int) -> Unicode.Scalar {
        let offset = Int(value - base)
        let shifted = (offset + amount) % 26
        return Unicode.Scalar(base + UInt32(shifted))!
    }
}
