import XCTest

/// UI test that captures an App Store screenshot of each tab, via fastlane `snapshot`.
///
/// Navigation is done by relaunching the app with the `UITEST_TAB` launch environment
/// preselecting a tab (handled in RootView), rather than tapping the tab bar — that
/// keeps capture identical on iPhone and iPad, where TabView lays out differently.
///
/// NOTE: needs `SnapshotHelper.swift` (defines `setupSnapshot`/`snapshot`) in this
/// target — generated once via `fastlane snapshot init`. See fastlane/SCREENSHOTS.md.
@MainActor
final class CipherKeysUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureScreenshots() {
        // With default settings, the Encode preview shows "hello world" → "khoor zruog".
        capture(tab: "encode",  named: "01-Encode")
        capture(tab: "decode",  named: "02-Decode")
        capture(tab: "recipes", named: "03-Recipes")
        capture(tab: "setup",   named: "04-Setup")
    }

    private func capture(tab: String, named name: String) {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchEnvironment["UITEST_TAB"] = tab
        app.launch()
        snapshot(name)
        app.terminate()
    }
}
