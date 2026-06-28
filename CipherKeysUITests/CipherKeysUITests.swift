import XCTest

/// UI test that drives CipherKeys through its tabs and captures an App Store
/// screenshot at each one, via fastlane `snapshot`.
///
/// NOTE: this file needs `SnapshotHelper.swift` (which defines `setupSnapshot` and
/// `snapshot`) in the same target. Generate it once with `fastlane snapshot init`,
/// move the produced `fastlane/SnapshotHelper.swift` into this `CipherKeysUITests/`
/// folder, then re-run `xcodegen generate`. See fastlane/SCREENSHOTS.md.
final class CipherKeysUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // Encode tab — with default settings the live preview shows
        // "hello world" → "khoor zruog".
        snapshot("01-Encode")

        let tabBar = app.tabBars.firstMatch
        tap(tabBar, "Decode", then: "02-Decode")
        tap(tabBar, "Recipes", then: "03-Recipes")
        tap(tabBar, "Setup", then: "04-Setup")
    }

    /// Tap a tab by its label (if present) and snapshot it.
    private func tap(_ tabBar: XCUIElement, _ tabLabel: String, then name: String) {
        let button = tabBar.buttons[tabLabel]
        guard button.waitForExistence(timeout: 5) else { return }
        button.tap()
        snapshot(name)
    }
}
