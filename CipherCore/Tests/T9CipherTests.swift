import XCTest
@testable import CipherCore

final class T9CipherTests: XCTestCase {

    func testKnownEncoding() {
        // Documented example from the format comment.
        XCTAssertEqual(T9Cipher().encode("hi there"), "44 444 / 8 44 33 777 33")
    }

    func testAcceptanceCriterionRoundTrip() {
        // "T9 encode of 'hi there' round-trips back to 'hi there'."
        let t9 = T9Cipher()
        XCTAssertEqual(t9.decode(t9.encode("hi there")), "hi there")
    }

    func testMultiWordRoundTrip() {
        let t9 = T9Cipher()
        let text = "the quick brown fox"
        XCTAssertEqual(t9.decode(t9.encode(text)), text)
    }

    func testCasePreserved() {
        let t9 = T9Cipher()
        XCTAssertEqual(t9.encode("Hi"), "+44 444")
        XCTAssertEqual(t9.decode("+44 444"), "Hi")
    }

    func testLiteralDigitsDoNotCollideWithLetterRuns() {
        // "2" the digit must not be confused with "a" (also "2").
        let t9 = T9Cipher()
        XCTAssertEqual(t9.encode("a2"), "2 *32")
        XCTAssertEqual(t9.decode(t9.encode("a2")), "a2")
    }

    func testPunctuationAndEmojiRoundTrip() {
        let t9 = T9Cipher()
        for sample in ["hi, there!", "call 911 now", "wow 🙂🎉", "x = y"] {
            XCTAssertEqual(t9.decode(t9.encode(sample)), sample, "failed: \(sample)")
        }
    }

    func testEmptyString() {
        let t9 = T9Cipher()
        XCTAssertEqual(t9.encode(""), "")
        XCTAssertEqual(t9.decode(""), "")
    }
}
