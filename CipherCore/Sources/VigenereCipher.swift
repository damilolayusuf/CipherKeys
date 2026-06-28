import Foundation

/// Vigenère cipher: a keyword defines a repeating sequence of Caesar shifts, one per
/// letter. Only ASCII A–Z / a–z are shifted; every other character passes through
/// untouched and does NOT advance the keyword position (so punctuation/spacing don't
/// desync the key). An empty/letterless keyword is the identity.
///
/// Still a classic, fully-reversible cipher — the keyword is shared openly, not a
/// secret key in any cryptographic sense.
public struct VigenereCipher: Cipher {
    public let keyword: String

    public var id: String { "vigenere" }
    public var name: String { "Vigenère (\(keyword))" }

    /// Per-letter shifts (0..<26) derived from the keyword's letters.
    private let shifts: [Int]

    public init(keyword: String) {
        self.keyword = keyword
        self.shifts = keyword.lowercased().unicodeScalars.compactMap { scalar in
            (97...122).contains(scalar.value) ? Int(scalar.value - 97) : nil
        }
    }

    public func encode(_ text: String) -> String { transform(text, decoding: false) }
    public func decode(_ text: String) -> String { transform(text, decoding: true) }

    /// Shared engine: `decoding` flips the shift direction so decode inverts encode.
    func transform(_ text: String, decoding: Bool) -> String {
        guard !shifts.isEmpty else { return text }
        var view = String.UnicodeScalarView()
        view.reserveCapacity(text.unicodeScalars.count)
        var keyIndex = 0
        for scalar in text.unicodeScalars {
            let base: UInt32?
            switch scalar.value {
            case 65...90:  base = 65
            case 97...122: base = 97
            default:       base = nil
            }
            if let base {
                let shift = shifts[keyIndex % shifts.count] * (decoding ? -1 : 1)
                let offset = ((Int(scalar.value - base) + shift) % 26 + 26) % 26
                view.append(Unicode.Scalar(base + UInt32(offset))!)
                keyIndex += 1
            } else {
                view.append(scalar)
            }
        }
        return String(view)
    }
}
