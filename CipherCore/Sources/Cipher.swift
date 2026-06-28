import Foundation

/// A reversible text transform. Every cipher CipherKeys ships conforms to this so
/// the app and keyboard can treat them uniformly and new ciphers drop in by adding
/// a single type + a `CipherKind` case.
///
/// IMPORTANT: these are CLASSIC ciphers — fun and nostalgic, **not** secure. Every
/// transform here is publicly reversible by design. Ciphertext produced by these is
/// not confidential; do not treat it as such. There are deliberately no keys, no key
/// exchange, and no networking anywhere in this framework.
public protocol Cipher: Identifiable {
    /// Stable identifier. Matches the corresponding `CipherKind.rawValue`.
    var id: String { get }

    /// Human-readable name for display in the UI.
    var name: String { get }

    /// Transform plaintext → ciphertext.
    func encode(_ text: String) -> String

    /// Transform ciphertext → plaintext. Must satisfy `decode(encode(x)) == x`.
    func decode(_ text: String) -> String
}
