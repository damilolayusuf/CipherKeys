import SwiftUI
import CipherCore

/// Build/edit a recipe: name it, chain invertible steps (reorder + edit params), see a
/// live preview, and share it as a link or QR. Works on a local copy and calls
/// `onSave` only when the user taps Save.
struct RecipeEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var steps: [EditableStep]
    @State private var sample = "hello world"
    private let recipeID: UUID
    private let onSave: (CipherRecipe) -> Void

    init(recipe: CipherRecipe, onSave: @escaping (CipherRecipe) -> Void) {
        self.recipeID = recipe.id
        self._name = State(initialValue: recipe.name)
        self._steps = State(initialValue: recipe.steps.map(EditableStep.init))
        self.onSave = onSave
    }

    private var builtRecipe: CipherRecipe {
        CipherRecipe(id: recipeID, name: name.isEmpty ? "Untitled" : name,
                     steps: steps.map(\.step))
    }

    private var shareURL: URL? { RecipeShare.url(for: builtRecipe) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Recipe name", text: $name)
                }

                Section {
                    ForEach($steps) { $editable in
                        StepRow(step: $editable.step)
                    }
                    .onMove { steps.move(fromOffsets: $0, toOffset: $1) }
                    .onDelete { steps.remove(atOffsets: $0) }

                    Menu {
                        ForEach(Array(RecipeStep.palette.enumerated()), id: \.offset) { _, step in
                            Button {
                                steps.append(EditableStep(step: step))
                            } label: {
                                Label(step.kindName, systemImage: step.symbolName)
                            }
                        }
                    } label: {
                        Label("Add step", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Steps (run top-to-bottom to encode)")
                } footer: {
                    Text("Decode runs the same steps in reverse. Drag to reorder, swipe to delete.")
                }

                Section("Live preview") {
                    TextField("Sample text", text: $sample)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    LabeledOutput(title: "Encoded", text: RecipeCipher(builtRecipe).encode(sample))
                }

                if let shareURL {
                    Section {
                        ShareLink(item: shareURL) {
                            Label("Share recipe link", systemImage: "square.and.arrow.up")
                        }
                        if let qr = QRCode.image(from: shareURL.absoluteString) {
                            Image(uiImage: qr)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 180)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Share")
                    } footer: {
                        Text("Send the link or QR to a friend — tapping it imports this recipe so you both use the same scheme. Anyone with it can decode; this isn't encryption.")
                    }
                }
            }
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { onSave(builtRecipe); dismiss() }
                        .bold()
                }
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
        }
    }
}

/// Wrapper giving each step a stable identity for reordering/deleting in the editor.
struct EditableStep: Identifiable {
    let id = UUID()
    var step: RecipeStep
}

/// A single editable step row. Caesar shows a shift stepper, Vigenère a keyword field;
/// the parameter-less steps just show a label.
private struct StepRow: View {
    @Binding var step: RecipeStep

    var body: some View {
        switch step {
        case .caesar(let shift):
            Stepper(value: shiftBinding, in: 1...25) {
                Label("Caesar +\(shift)", systemImage: RecipeStep.caesar(shift: shift).symbolName)
            }
        case .vigenere(let keyword):
            HStack {
                Label("Vigenère", systemImage: RecipeStep.vigenere(keyword: keyword).symbolName)
                TextField("keyword", text: keywordBinding)
                    .multilineTextAlignment(.trailing)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        default:
            Label(step.kindName, systemImage: step.symbolName)
        }
    }

    private var shiftBinding: Binding<Int> {
        Binding(
            get: { if case .caesar(let s) = step { return s } else { return 3 } },
            set: { step = .caesar(shift: $0) }
        )
    }

    private var keywordBinding: Binding<String> {
        Binding(
            get: { if case .vigenere(let k) = step { return k } else { return "" } },
            set: { step = .vigenere(keyword: $0) }
        )
    }
}
