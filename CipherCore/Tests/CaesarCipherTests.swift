import XCTest
@testable import CipherCore

final class CaesarCipherTests: XCTestCase {

    func testKnownEncoding() {
        // The acceptance-criteria example: shift 3, "hello world" → "khoor zruog".
        XCTAssertEqual(CaesarCipher(shift: 3).encode("hello world"), "khoor zruog")
        XCTAssertEqual(CaesarCipher(shift: 3).decode("khoor zruog"), "hello world")
    }

    func testCasePreservedAndWrapped() {
        // 'z' + 1 wraps to 'a', 'Z' + 1 wraps to 'A'.
        XCTAssertEqual(CaesarCipher(shift: 1).encode("xyz XYZ"), "yza YZA")
    }

    func testNonLettersUntouched() {
        let input = "abc 123 !?# 🙂 é"
        // Only a,b,c shift; everything else is identical.
        XCTAssertEqual(CaesarCipher(shift: 1).encode(input), "bcd 123 !?# 🙂 é")
    }

    func testShiftZeroAndTwentySixAreIdentity() {
        let input = "Identity Check 42!"
        XCTAssertEqual(CaesarCipher(shift: 0).encode(input), input)
        XCTAssertEqual(CaesarCipher(shift: 26).encode(input), input)
        XCTAssertEqual(CaesarCipher(shift: 52).encode(input), input)
    }

    func testNegativeShiftMatchesForwardComplement() {
        // shift -1 is the same as shift 25.
        XCTAssertEqual(CaesarCipher(shift: -1).encode("abc"),
                       CaesarCipher(shift: 25).encode("abc"))
    }

    func testDecodeIsEncodeWithNegativeShift() {
        let text = "Sphinx of black quartz"
        for shift in [-5, 0, 4, 13, 30] {
            let cipher = CaesarCipher(shift: shift)
            XCTAssertEqual(cipher.decode(cipher.encode(text)), text)
            // decode(x) must equal encoding with the opposite shift.
            XCTAssertEqual(cipher.decode(text), CaesarCipher(shift: -shift).encode(text))
        }
    }
}
