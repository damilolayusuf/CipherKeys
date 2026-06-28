import XCTest
@testable import CipherCore

final class AtbashCipherTests: XCTestCase {

    func testKnownEncoding() {
        // A↔Z, B↔Y … so "abc" → "zyx", "ABC" → "ZYX".
        XCTAssertEqual(AtbashCipher().encode("abc"), "zyx")
        XCTAssertEqual(AtbashCipher().encode("ABC"), "ZYX")
        XCTAssertEqual(AtbashCipher().encode("Hello"), "Svool")
    }

    func testSelfInverse() {
        let text = "Atbash Is Symmetric! 99"
        XCTAssertEqual(AtbashCipher().encode(AtbashCipher().encode(text)), text)
        XCTAssertEqual(AtbashCipher().encode(text), AtbashCipher().decode(text))
    }

    func testNonLettersUntouched() {
        XCTAssertEqual(AtbashCipher().encode("a1! é"), "z1! é")
    }
}
