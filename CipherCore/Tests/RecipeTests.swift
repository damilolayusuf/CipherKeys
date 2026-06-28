import XCTest
@testable import CipherCore

final class RecipeTests: XCTestCase {

    func testRecipeRoundTripsOverAllSamples() {
        // A deliberately mixed pipeline exercising every step kind.
        let recipe = CipherRecipe(name: "Spy Mix", steps: [
            .caesar(shift: 3),
            .reverse,
            .atbash,
            .vigenere(keyword: "secret"),
            .rot13,
            .caesar(shift: -7),
        ])
        let cipher = RecipeCipher(recipe)
        for sample in RoundTripTests.samples {
            XCTAssertEqual(cipher.decode(cipher.encode(sample)), sample,
                           "recipe failed to round-trip \(String(reflecting: sample))")
        }
    }

    func testEmptyRecipeIsIdentity() {
        let cipher = RecipeCipher(CipherRecipe(name: "Nothing", steps: []))
        XCTAssertEqual(cipher.encode("Hello, World! 123 🙂"), "Hello, World! 123 🙂")
    }

    func testStepOrderMatters() {
        // Caesar and Atbash don't commute (a shift then a reflection ≠ the reverse),
        // so the order genuinely changes the ciphertext — while each still round-trips.
        let a = RecipeCipher(CipherRecipe(name: "A", steps: [.caesar(shift: 1), .atbash]))
        let b = RecipeCipher(CipherRecipe(name: "B", steps: [.atbash, .caesar(shift: 1)]))
        XCTAssertNotEqual(a.encode("abc"), b.encode("abc"))
        XCTAssertEqual(a.decode(a.encode("abc")), "abc")
        XCTAssertEqual(b.decode(b.encode("abc")), "abc")
    }

    func testReverseStepHandlesGraphemes() {
        XCTAssertEqual(RecipeStep.reverse.apply("abc 🙂", decoding: false), "🙂 cba")
        XCTAssertEqual(RecipeStep.reverse.apply("🙂 cba", decoding: true), "abc 🙂")
    }

    // MARK: - Vigenère

    func testVigenereKnownVector() {
        // Classic: keyword LEMON, "attackatdawn" → "lxfopvefrnhr".
        XCTAssertEqual(VigenereCipher(keyword: "lemon").encode("attackatdawn"), "lxfopvefrnhr")
    }

    func testVigenereRoundTripAndCasePunctuation() {
        let v = VigenereCipher(keyword: "Key")
        for sample in RoundTripTests.samples {
            XCTAssertEqual(v.decode(v.encode(sample)), sample)
        }
    }

    func testVigenereEmptyKeywordIsIdentity() {
        XCTAssertEqual(VigenereCipher(keyword: "  !! ").encode("hello"), "hello")
    }

    // MARK: - Sharing

    func testShareURLRoundTrip() {
        let recipe = CipherRecipe(name: "Decoder Ring", steps: [.caesar(shift: 5), .reverse, .vigenere(keyword: "moon")])
        guard let url = RecipeShare.url(for: recipe) else { return XCTFail("nil url") }
        XCTAssertEqual(url.scheme, "cipherkeys")
        guard let restored = RecipeShare.recipe(from: url) else { return XCTFail("nil recipe") }
        XCTAssertEqual(restored.id, recipe.id)
        XCTAssertEqual(restored.name, recipe.name)
        XCTAssertEqual(restored.steps, recipe.steps)
    }

    func testShareRejectsForeignURL() {
        XCTAssertNil(RecipeShare.recipe(from: URL(string: "https://example.com/recipe?d=abc")!))
        XCTAssertNil(RecipeShare.recipe(from: URL(string: "cipherkeys://other?d=abc")!))
    }

    // MARK: - Selection storage

    func testSelectionStorageRoundTrip() {
        XCTAssertEqual(CipherSelection(storageString: CipherSelection.builtin(.atbash).storageString),
                       .builtin(.atbash))
        let id = UUID()
        XCTAssertEqual(CipherSelection(storageString: CipherSelection.recipe(id).storageString),
                       .recipe(id))
        XCTAssertNil(CipherSelection(storageString: "garbage"))
    }
}
