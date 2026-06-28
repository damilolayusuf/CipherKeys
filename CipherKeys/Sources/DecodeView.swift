import SwiftUI
import CipherCore

/// "Decode" tab: the standalone decode box. Paste ciphertext you received, pick the
/// cipher (or recipe) it was made with, and read the plaintext — useful for the
/// recipient even if they never install the keyboard.
struct DecodeView: View {
    @EnvironmentObject private var model: SettingsModel
    @State private var selection: CipherSelection = CipherSettings.shared.selection
    @State private var caesarShift = CipherSettings.shared.caesarShift
    @State private var input = ""

    private var decoded: String {
        cipher.decode(input)
    }

    private var cipher: any Cipher {
        switch selection {
        case .builtin(let kind): return kind.make(caesarShift: caesarShift)
        case .recipe(let id):
            if let recipe = model.recipes.first(where: { $0.id == id }) { return RecipeCipher(recipe) }
            return CaesarCipher(shift: caesarShift)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cipher used") {
                    SelectionPicker(selection: $selection,
                                    caesarShift: $caesarShift,
                                    recipes: model.recipes)
                }

                Section("Ciphertext") {
                    TextField("Paste the message you received…", text: $input, axis: .vertical)
                        .lineLimit(3...8)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.monospaced())
                }

                Section("Plaintext") {
                    LabeledOutput(title: "Decoded", text: decoded)
                }
            }
            .navigationTitle("Decode")
        }
    }
}
