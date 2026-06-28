import SwiftUI
import UIKit
import CipherCore

/// The action extension's UI: shows the received ciphertext, lets you pick the cipher
/// or recipe (defaulting to your current selection), and shows the decoded plaintext
/// with a one-tap copy.
struct DecodeActionView: View {
    let received: String
    let onDone: () -> Void

    @State private var selection: CipherSelection
    @State private var caesarShift: Int
    @State private var copied = false
    private let recipes: [CipherRecipe]

    init(received: String, onDone: @escaping () -> Void) {
        self.received = received
        self.onDone = onDone
        let stored = CipherSettings.shared
        _selection = State(initialValue: stored.selection)
        _caesarShift = State(initialValue: stored.caesarShift)
        self.recipes = stored.recipes
    }

    private var decoded: String {
        let cipher: any Cipher
        switch selection {
        case .builtin(let kind):
            cipher = kind.make(caesarShift: caesarShift)
        case .recipe(let id):
            cipher = recipes.first(where: { $0.id == id }).map(RecipeCipher.init)
                ?? CaesarCipher(shift: caesarShift)
        }
        return cipher.decode(received)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Received") {
                    Text(received.isEmpty ? "No text found in the selection." : received)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                }

                Section("Cipher") {
                    Picker("Cipher", selection: $selection) {
                        Section("Built-in") {
                            ForEach(CipherKind.allCases) { kind in
                                Label(kind.displayName, systemImage: kind.symbolName)
                                    .tag(CipherSelection.builtin(kind))
                            }
                        }
                        if !recipes.isEmpty {
                            Section("Your recipes") {
                                ForEach(recipes) { recipe in
                                    Label(recipe.name, systemImage: "wand.and.stars")
                                        .tag(CipherSelection.recipe(recipe.id))
                                }
                            }
                        }
                    }
                    .pickerStyle(.menu)

                    if case .builtin(let kind) = selection, kind.usesShift {
                        Stepper(value: $caesarShift, in: 1...25) {
                            Text("Shift: \(caesarShift)").monospacedDigit()
                        }
                    }
                }

                Section("Decoded") {
                    Text(decoded.isEmpty ? " " : decoded)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                    Button {
                        UIPasteboard.general.string = decoded
                        withAnimation { copied = true }
                    } label: {
                        Label(copied ? "Copied" : "Copy plaintext",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                    .disabled(decoded.isEmpty)
                }
            }
            .navigationTitle("Decode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done", action: onDone).bold()
                }
            }
        }
    }
}
