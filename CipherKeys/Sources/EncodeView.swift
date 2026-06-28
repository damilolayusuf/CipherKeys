import SwiftUI
import CipherCore

/// "Encode" tab: choose the cipher (built-in or recipe) that drives the keyboard, and
/// see a live preview as you type. The selection here is what the CipherKeys keyboard
/// and the Decode action extension use by default.
struct EncodeView: View {
    @EnvironmentObject private var model: SettingsModel
    @State private var sample = "hello world"

    private var encoded: String {
        model.currentCipher.encode(sample)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SelectionPicker(selection: $model.selection,
                                    caesarShift: $model.caesarShift,
                                    recipes: model.recipes)
                } header: {
                    Text("Keyboard cipher")
                } footer: {
                    Text("This is the cipher the CipherKeys keyboard uses, and the default for the Decode action.")
                }

                Section("Live preview") {
                    TextField("Type to preview…", text: $sample, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    LabeledOutput(title: "Encoded", text: encoded)
                }

                Section {
                    DisclaimerBanner()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("CipherKeys")
        }
    }
}

/// Read-only output row with a copy button.
struct LabeledOutput: View {
    let title: String
    let text: String

    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button {
                    UIPasteboard.general.string = text
                    withAnimation { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    Label(copied ? "Copied" : "Copy",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
                .disabled(text.isEmpty)
            }
            Text(text.isEmpty ? " " : text)
                .font(.body.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}
