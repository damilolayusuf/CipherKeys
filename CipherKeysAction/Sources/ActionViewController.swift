import UIKit
import SwiftUI
import UniformTypeIdentifiers
import CipherCore

/// Principal view controller for the "Decode with CipherKeys" action extension.
///
/// This is how you decode text you *can't* edit (a received message, a web page, a
/// PDF): select it → Share → Decode with CipherKeys. The extension reads the selected
/// text, decodes it with the chosen cipher/recipe (pulled from the shared App Group),
/// and shows the plaintext. Pure local math — same engine as the app and keyboard.
@objc(ActionViewController)
final class ActionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSelectedText { [weak self] text in
            guard let self else { return }
            let root = DecodeActionView(received: text ?? "") { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            }
            let host = UIHostingController(rootView: root)
            self.addChild(host)
            host.view.frame = self.view.bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(host.view)
            host.didMove(toParent: self)
        }
    }

    /// Pull the first plain-text attachment out of the share sheet's input items.
    private func loadSelectedText(completion: @escaping (String?) -> Void) {
        let textType = UTType.plainText.identifier
        for item in (extensionContext?.inputItems as? [NSExtensionItem] ?? []) {
            for provider in item.attachments ?? [] where provider.hasItemConformingToTypeIdentifier(textType) {
                provider.loadItem(forTypeIdentifier: textType, options: nil) { value, _ in
                    DispatchQueue.main.async {
                        completion(value as? String ?? (value as? NSAttributedString)?.string)
                    }
                }
                return
            }
        }
        completion(nil)
    }
}
