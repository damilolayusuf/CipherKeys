import XCTest
@testable import CipherCore

final class ROT13CipherTests: XCTestCase {

    func testKnownEncoding() {
        XCTAssertEqual(ROT13Cipher().encode("Hello, World!"), "Uryyb, Jbeyq!")
    }

    func testSelfInverse() {
        // encode and decode are identical for ROT13.
        let text = "The Quick Brown Fox 123"
        XCTAssertEqual(ROT13Cipher().encode(text), ROT13Cipher().decode(text))
        XCTAssertEqual(ROT13Cipher().encode(ROT13Cipher().encode(text)), text)
    }

    func testMatchesCaesar13() {
        let text = "matches caesar"
        XCTAssertEqual(ROT13Cipher().encode(text), CaesarCipher(shift: 13).encode(text))
    }
}
