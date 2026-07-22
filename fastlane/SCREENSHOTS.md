# Automated App Store screenshots (fastlane snapshot)

A UI test (`CipherKeysUITests`) drives the app through its tabs and captures a
screenshot at each one, on every device size, in one command.

## One-time setup

`snapshot` needs a helper file that defines `setupSnapshot()` / `snapshot()`. Generate
it once and place it in the UI-test target:

```bash
brew install fastlane          # if not already installed
cd /path/to/CipherKeys
fastlane snapshot init         # creates fastlane/SnapshotHelper.swift (and a Snapfile)

# Move the helper into the UI-test target's folder, then regenerate the project:
mv fastlane/SnapshotHelper.swift CipherKeysUITests/SnapshotHelper.swift
rm -f fastlane/Snapfile        # we configure snapshot in the Fastfile instead
xcodegen generate
```

(`CipherKeysUITests/` is a source path for the test target, so dropping
`SnapshotHelper.swift` there is enough — no manual Xcode wiring needed. Until this file
is present, the UI-test target will not compile.)

## Capture

```bash
fastlane screenshots           # writes PNGs to fastlane/screenshots/<lang>/
```

Open `fastlane/screenshots/screenshots.html` to review them. The captures are produced
at native device resolution (e.g. iPhone 16 Pro Max → 1320×2868, the 6.9" size).

## Upload

```bash
# Requires the App Store Connect API key env vars (see Fastfile header):
#   ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH
fastlane screenshots_upload
```

## Notes

- Edit the `devices:` list in the `screenshots` lane to match the sizes you want. If you
  switch the app to **iPhone-only**, remove the iPad device.
- `override_status_bar: true` gives a clean 9:41 / full-battery status bar.
- To make a screen show specific text, extend `CipherKeysUITests.swift` to type into the
  preview field before calling `snapshot(...)`.
