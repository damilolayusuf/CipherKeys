import XCTest
@testable import CipherCore

/// The core property every cipher must satisfy: `decode(encode(x)) == x` for a
/// representative spread of inputs (lower/upper/mixed case, spaces, punctuation,
/// numbers, emoji, and empty). Run once per cipher kind so coverage is uniform.
final class RoundTripTests: XCTestCase {

    /// Inputs every cipher must round-trip.
    static let samples: [String] = [
        "",                                   // empty
        "hello",                              // lowercase
        "HELLO",                              // uppercase
        "Hello World",                        // mixed case + space
        "hello world",                        // multi-word lowercase
        "The quick brown fox jumps over 13 lazy dogs.", // punctuation + numbers
        "Café déjà vu — naïve façade",        // accented / non-Latin
        "Привет мир",                          // Cyrillic
        "emoji 🙂 test 👨‍💻 done 🎉",            // emoji incl. ZWJ sequence
        "a.b,c!d?e:f;g'h\"i(j)k",             // dense punctuation
        "   leading and  double  spaces   ",  // whitespace runs
        "MiXeD 123 CaSe & symbols #@%",       // everything together
    ]

    private func assertRoundTrips(_ cipher: any Cipher, file: StaticString = #filePath, line: UInt = #line) {
        for sample in Self.samples {
            let restored = cipher.decode(cipher.encode(sample))
            XCTAssertEqual(restored, sample,
                           "\(cipher.name) failed to round-trip \(String(reflecting: sample))",
                           file: file, line: line)
        }
    }

    func testCaesarRoundTripsAcrossShifts() {
        for shift in [-30, -13, -1, 0, 1, 3, 13, 25, 26, 27, 52, 100] {
            assertRoundTrips(CaesarCipher(shift: shift))
        }
    }

    func testROT13RoundTrips() {
        assertRoundTrips(ROT13Cipher())
    }

    func testAtbashRoundTrips() {
        assertRoundTrips(AtbashCipher())
    }

    func testT9RoundTrips() {
        assertRoundTrips(T9Cipher())
    }

    /// Every cipher constructed via the registry must also round-trip.
    func testRegistryRoundTrips() {
        for kind in CipherKind.allCases {
            assertRoundTrips(kind.make(caesarShift: 5))
        }
    }
}
