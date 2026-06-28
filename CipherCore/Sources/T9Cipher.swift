import Foundation

/// T9 / Nokia multitap encoder.
///
/// Each ASCII letter maps to the key you'd press, repeated by its position on that
/// key: a=2, b=22, c=222, d=3 … s=7777, w=9, z=9999. Multitap is ambiguous without
/// separators ("22" could be "aa" or "b"), so this encoder emits an explicit,
/// fully reversible grammar.
///
/// FORMAT (documented so `decode` can parse it back exactly):
///   • Tokens are joined by a single space.
///   • A lowercase letter  → its digit run, e.g. `c` → "222".
///   • An uppercase letter → "+" + digit run, e.g. `C` → "+222" (case preserved).
///   • A single space between words → "/" — the distinct word delimiter.
///   • Any other character (punctuation, digits, emoji, accented / non-Latin) →
///     "*" + that grapheme's Unicode scalar value(s) in hex, dot-separated, e.g.
///     "!" → "*21", "🙂" → "*1F642", "👨‍💻" → "*1F468.200D.1F4BB".
///
/// Because every non-letter is "*"-escaped, a literal digit in the plaintext (e.g.
/// "2") never collides with a letter run (also "2") — it encodes as "*32".
///
/// Example: "hi there" → "44 444 / 8 44 33 777 33".
///
/// Scope note: accented / non-Latin letters are treated as "other" characters and
/// preserved verbatim via the "*" escape rather than mapped to keypad digits —
/// classic multitap keypads had no keys for them. See README.
public struct T9Cipher: Cipher {
    public var id: String { CipherKind.t9.rawValue }
    public var name: String { "T9 Multitap" }

    public init() {}

    /// a → "2", b → "22", … z → "9999".
    private static let letterToRun: [Character: String] = {
        let groups: [(digit: Character, letters: [Character])] = [
            ("2", ["a", "b", "c"]),
            ("3", ["d", "e", "f"]),
            ("4", ["g", "h", "i"]),
            ("5", ["j", "k", "l"]),
            ("6", ["m", "n", "o"]),
            ("7", ["p", "q", "r", "s"]),
            ("8", ["t", "u", "v"]),
            ("9", ["w", "x", "y", "z"]),
        ]
        var map: [Character: String] = [:]
        for group in groups {
            for (index, letter) in group.letters.enumerated() {
                map[letter] = String(repeating: group.digit, count: index + 1)
            }
        }
        return map
    }()

    /// Inverse of `letterToRun`: "222" → "c".
    private static let runToLetter: [String: Character] = {
        var map: [String: Character] = [:]
        for (letter, run) in letterToRun { map[run] = letter }
        return map
    }()

    public func encode(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        var tokens: [String] = []
        tokens.reserveCapacity(text.count)
        for character in text {
            if character == " " {
                tokens.append("/")
            } else if let run = run(for: character) {
                tokens.append(run)
            } else {
                tokens.append(escape(character))
            }
        }
        return tokens.joined(separator: " ")
    }

    public func decode(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        var result = ""
        for token in text.components(separatedBy: " ") where !token.isEmpty {
            if token == "/" {
                result.append(" ")
            } else if token.hasPrefix("*") {
                result.append(unescape(token))
            } else if token.hasPrefix("+") {
                let run = String(token.dropFirst())
                if let letter = T9Cipher.runToLetter[run] {
                    result.append(Character(letter.uppercased()))
                } else {
                    result.append(token) // unknown token — preserve rather than lose data
                }
            } else if let letter = T9Cipher.runToLetter[token] {
                result.append(letter)
            } else {
                result.append(token)
            }
        }
        return result
    }

    /// Digit run for an ASCII letter, with a "+" marker for uppercase. `nil` for
    /// anything that isn't an A–Z / a–z letter.
    private func run(for character: Character) -> String? {
        guard character.isASCII, character.isLetter else { return nil }
        let lowered = Character(character.lowercased())
        guard let run = T9Cipher.letterToRun[lowered] else { return nil }
        return character.isUppercase ? "+" + run : run
    }

    /// "*" + hex scalar value(s), dot-separated, for any non-letter grapheme.
    private func escape(_ character: Character) -> String {
        let hex = character.unicodeScalars
            .map { String($0.value, radix: 16, uppercase: true) }
            .joined(separator: ".")
        return "*" + hex
    }

    /// Reverse of `escape`: parse "*1F468.200D.1F4BB" back into its grapheme.
    private func unescape(_ token: String) -> String {
        var view = String.UnicodeScalarView()
        for part in token.dropFirst().split(separator: ".") {
            if let value = UInt32(part, radix: 16), let scalar = Unicode.Scalar(value) {
                view.append(scalar)
            }
        }
        return String(view)
    }
}
