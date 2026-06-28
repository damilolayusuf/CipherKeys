import SwiftUI

/// "Setup" tab: how to enable the keyboard and how to use it. No Full Access is ever
/// required — the ciphers are pure local math.
struct EnableKeyboardView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Color.accentColor, in: Circle())
                            Text(step)
                        }
                        .padding(.vertical, 2)
                    }
                } header: {
                    Text("Enable the keyboard")
                } footer: {
                    Text("You do NOT need to grant “Allow Full Access.” CipherKeys never connects to the network — leaving Full Access off is expected.")
                }

                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("Open Settings", systemImage: "gear")
                    }
                }

                Section("Using it") {
                    Label("Type your message on the normal keyboard first.", systemImage: "keyboard")
                    Label("Tap the 🌐 globe key to switch to CipherKeys.", systemImage: "globe")
                    Label("Tap Encode to scramble, Decode to restore.", systemImage: "arrow.left.arrow.right")
                }

                Section {
                    DisclaimerBanner()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                } footer: {
                    Text("Heads-up: the keyboard transforms the text before the cursor. In very long fields the system may only hand it the recent part, so this works best on short messages.")
                }
            }
            .navigationTitle("Setup")
        }
    }

    private static let steps = [
        "Open Settings → General → Keyboard → Keyboards.",
        "Tap “Add New Keyboard…” and choose CipherKeys.",
        "That’s it — switch to it with the 🌐 globe key in any app.",
    ]
}
