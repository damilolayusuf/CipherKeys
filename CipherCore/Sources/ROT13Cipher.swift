import Foundation

/// ROT13: Caesar with a fixed shift of 13. Because 13 is exactly half of 26, ROT13
/// is its own inverse — `encode` and `decode` produce identical results. The classic
/// choice for hiding spoilers and punchlines.
public struct ROT13Cipher: Cipher {
    public var id: String { CipherKind.rot13.rawValue }
    public var name: String { "ROT13" }

    private let caesar = CaesarCipher(shift: 13)

    public init() {}

    public func encode(_ text: String) -> String { caesar.encode(text) }
    public func decode(_ text: String) -> String { caesar.decode(text) }
}
