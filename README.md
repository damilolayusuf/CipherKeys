# CipherKeys

A native iOS app with a custom keyboard that transforms text in **any** app
(iMessage, WhatsApp, Notes, anywhere with a text field) using classic ciphers.
Type a message, switch to the CipherKeys keyboard, tap **Encode**, and the text in
the field is replaced with ciphertext. **Decode** reverses it.

> ⚠️ **This is a fun / nostalgia toy, not real security.** Every cipher here is a
> classic, publicly reversible transform — Caesar, ROT13, Atbash, T9 multitap. There
> are no keys, no key exchange, and no networking anywhere. Anyone can reverse the
> output. Don't use it for anything that needs to stay private.

## Project layout

Three targets in one Xcode project (generated from `project.yml` by
[XcodeGen](https://github.com/yonaskolb/XcodeGen)):

| Target | Type | What it is |
| --- | --- | --- |
| `CipherCore` | static framework | The cipher engine + recipes + unit tests. The math, written once, compiled into the app and both extensions. |
| `CipherKeys` | iOS app (SwiftUI) | Onboarding, cipher picker + Caesar shift, live preview, standalone decode box, and the recipe builder/sharing. |
| `CipherKeysKeyboard` | keyboard extension | The transform bar: Encode / Decode / globe + inline cipher picker (built-ins + recipes). `RequestsOpenAccess = NO`. |
| `CipherKeysAction` | action extension | "Decode with CipherKeys" in the Share sheet — decode text you can't edit (received messages, web pages, PDFs). |

The app and the extension communicate **only** through an App Group shared
`UserDefaults` suite (`group.com.xkabiir.cipherkeys`). No other IPC.

## Building

```bash
brew install xcodegen        # one-time
xcodegen generate            # regenerate CipherKeys.xcodeproj from project.yml
open CipherKeys.xcodeproj
```

The generated `.xcodeproj` is **not** checked in — `project.yml` is the source of
truth. Re-run `xcodegen generate` after pulling changes to it.

### Running the tests

```bash
xcodegen generate
xcodebuild test -scheme CipherCore \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Signing / App Group (read before running on a device)

The project ships with placeholder identifiers under the `com.xkabiir` prefix and an
**empty** `DEVELOPMENT_TEAM`. That's enough to build and run in the Simulator.

To run on a **device** or to share the App Group between the app and keyboard with
real provisioning:

1. Set your Apple Developer **Team ID** in `project.yml` (`settings.base.DEVELOPMENT_TEAM`) and re-generate.
2. Change the bundle prefix from `com.xkabiir` to your own reverse-DNS prefix in
   `project.yml`, the two `.entitlements` files, and `CipherSettings.appGroupID`.
3. Enable the **App Groups** capability for both the app and the extension targets,
   using the same group identifier in both.

> App Groups require a real Team ID. On some accounts the free "Personal Team" cannot
> create App Groups — a paid Apple Developer Program membership may be required.

## Cipher format notes

- **Caesar / ROT13 / Atbash** only transform ASCII `A–Z` / `a–z`. Digits,
  punctuation, whitespace, emoji, and accented / non-Latin characters pass through
  untouched.
- **T9 multitap** uses an explicit, fully reversible grammar (documented in
  `T9Cipher.swift`): letters → keypad digit runs, `+` marks uppercase, `/` separates
  words, and any other character is `*`-escaped by Unicode scalar. Accented /
  non-Latin letters are preserved verbatim rather than mapped to keypad digits.

## Custom recipes (build your own cipher) & sharing

A **recipe** is a named pipeline of invertible steps — Caesar, ROT13, Atbash, Reverse,
Vigenère — that you chain in the **Recipes** tab (e.g. `Caesar +3 → Reverse → Vigenère
"moon"`). Encoding runs the steps top-to-bottom; decoding runs them bottom-to-top,
inverting each, so the round-trip always holds (see `RecipeTests`). Recipes are stored
in the App Group alongside the built-ins, so the keyboard and the Decode action can use
them too.

**Sharing** a recipe produces a `cipherkeys://recipe?...` deep link (also rendered as a
QR). A friend taps the link (or scans the QR with the Camera app) and the recipe is
imported into their app and selected. This shares the *recipe*, not a secret — anyone
with the link can decode. These remain classic ciphers, **not** encryption; there is no
key exchange and no confidentiality claim.

## Decoding text you can't edit

The keyboard can only transform the *currently focused editable field*. To decode a
received message (which lives in a read-only bubble), either copy it into an editable
field and tap Decode, paste it into the app's Decode tab, or select it and use
**Share → Decode with CipherKeys** (the action extension), which shows the plaintext
with one-tap copy.

## Known limitation

The keyboard transforms `documentContextBeforeInput` — the text **before the
cursor**. iOS may only hand the extension the recent portion of a very long field, so
CipherKeys works best on short messages. After a transform the cursor sits at the end
of the field.
