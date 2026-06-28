import UIKit
import CipherCore

/// CipherKeys custom keyboard — the "transform bar" design.
///
/// This is intentionally NOT a full QWERTY. The user types their message on the
/// normal keyboard, switches to CipherKeys, and taps Encode/Decode to transform the
/// text already in the field. The mechanism is pure local math (no networking, no
/// Full Access): read the text before the cursor, delete it, insert the transform.
final class KeyboardViewController: UIInputViewController {

    // Settings come exclusively from the App Group suite the main app writes to.
    private let settings = CipherSettings.shared
    private var selection: CipherSelection = .builtin(.caesar)
    private var caesarShift: Int = CipherSettings.defaultCaesarShift
    private var selections: [CipherSelection] = []

    // UI
    private let titleLabel = UILabel()
    private let hintLabel = UILabel()
    private let chipRow = UIStackView()
    private var chipButtons: [UIButton] = []
    private let nextKeyboardButton = UIButton(type: .system)
    private let feedback = UIImpactFeedbackGenerator(style: .medium)

    private let accent = UIColor(red: 0.286, green: 0.337, blue: 0.851, alpha: 1)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSettings()
        buildUI()        // keep cheap — first launch is the most memory-fragile moment
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Re-read so a cipher/recipe/shift change made in the app takes effect now.
        loadSettings()
        rebuildChips()
        updateSelectionUI()
        nextKeyboardButton.isHidden = !needsInputModeSwitchKey
    }

    // MARK: - Settings

    private func loadSettings() {
        selection = settings.selection
        caesarShift = settings.caesarShift
        selections = settings.availableSelections()
    }

    private func currentCipher() -> any Cipher {
        settings.cipher(for: selection)
    }

    // MARK: - UI

    private func buildUI() {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        container.layoutMargins = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        container.isLayoutMarginsRelativeArrangement = true
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Row 1: current cipher name + globe (next-keyboard) button.
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        nextKeyboardButton.setImage(UIImage(systemName: "globe"), for: .normal)
        nextKeyboardButton.tintColor = .label
        nextKeyboardButton.addTarget(self, action: #selector(advanceTapped), for: .touchUpInside)
        nextKeyboardButton.setContentHuggingPriority(.required, for: .horizontal)

        let header = UIStackView(arrangedSubviews: [titleLabel, nextKeyboardButton])
        header.axis = .horizontal
        header.spacing = 8
        header.alignment = .center
        container.addArrangedSubview(header)

        // Row 2: scrollable cipher chips (built-ins + recipes).
        container.addArrangedSubview(makeChipBar())

        // Row 3: Encode / Decode.
        let encode = makeActionButton(title: "Encode", symbol: "lock.fill",
                                      action: #selector(encodeTapped), filled: true)
        let decode = makeActionButton(title: "Decode", symbol: "lock.open.fill",
                                      action: #selector(decodeTapped), filled: false)
        let actions = UIStackView(arrangedSubviews: [encode, decode])
        actions.axis = .horizontal
        actions.spacing = 10
        actions.distribution = .fillEqually
        container.addArrangedSubview(actions)

        // Row 4: honest hint about scope/limitations.
        hintLabel.font = .preferredFont(forTextStyle: .caption2)
        hintLabel.textColor = .secondaryLabel
        hintLabel.numberOfLines = 0
        hintLabel.text = "Transforms text before the cursor. Fun, not secure."
        container.addArrangedSubview(hintLabel)

        // Keyboards must declare their own height.
        let height = view.heightAnchor.constraint(equalToConstant: 230)
        height.priority = UILayoutPriority(999)
        height.isActive = true

        rebuildChips()
        updateSelectionUI()
        nextKeyboardButton.isHidden = !needsInputModeSwitchKey
    }

    private func makeChipBar() -> UIScrollView {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false

        chipRow.axis = .horizontal
        chipRow.spacing = 8
        chipRow.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(chipRow)

        NSLayoutConstraint.activate([
            chipRow.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            chipRow.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            chipRow.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            chipRow.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            chipRow.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor),
        ])
        scroll.heightAnchor.constraint(equalToConstant: 36).isActive = true
        return scroll
    }

    /// Rebuild chips from the current selections (built-ins + any saved recipes).
    private func rebuildChips() {
        chipButtons.forEach { $0.removeFromSuperview() }
        chipButtons.removeAll()

        for (index, selection) in selections.enumerated() {
            var config = UIButton.Configuration.plain()
            config.title = settings.displayName(for: selection)
            config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            config.background.cornerRadius = 14
            config.background.strokeWidth = 1
            config.background.strokeColor = .separator

            let chip = UIButton(configuration: config)
            chip.tag = index
            chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            chipButtons.append(chip)
            chipRow.addArrangedSubview(chip)
        }
    }

    private func makeActionButton(title: String, symbol: String,
                                  action: Selector, filled: Bool) -> UIButton {
        var config = filled ? UIButton.Configuration.filled() : UIButton.Configuration.gray()
        config.title = title
        config.image = UIImage(systemName: symbol)
        config.imagePadding = 8
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        config.baseBackgroundColor = filled ? accent : .secondarySystemBackground
        config.baseForegroundColor = filled ? .white : accent
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .preferredFont(forTextStyle: .headline)
            return outgoing
        }

        let button = UIButton(configuration: config)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func updateSelectionUI() {
        if case .builtin(let kind) = selection, kind.usesShift {
            titleLabel.text = "\(kind.displayName) · shift \(caesarShift)"
        } else {
            titleLabel.text = settings.displayName(for: selection)
        }
        let selectedIndex = selections.firstIndex(of: selection)
        for (index, chip) in chipButtons.enumerated() {
            let isSelected = index == selectedIndex
            chip.configuration?.background.backgroundColor = isSelected ? accent : .clear
            chip.configuration?.baseForegroundColor = isSelected ? .white : .label
            chip.configuration?.background.strokeColor = isSelected ? accent : .separator
        }
    }

    // MARK: - Actions

    @objc private func advanceTapped() {
        advanceToNextInputMode()
    }

    @objc private func chipTapped(_ sender: UIButton) {
        guard selections.indices.contains(sender.tag) else { return }
        selection = selections[sender.tag]
        settings.selection = selection   // persist so the app reflects the change too
        updateSelectionUI()
        feedback.impactOccurred(intensity: 0.5)
    }

    @objc private func encodeTapped() { applyTransform(encode: true) }
    @objc private func decodeTapped() { applyTransform(encode: false) }

    /// The one true mechanism: grab the text before the cursor, delete it, insert
    /// the transformed result. `documentContextBeforeInput` only returns text before
    /// the cursor and can truncate very long fields — fine for short messages.
    private func applyTransform(encode: Bool) {
        let proxy = textDocumentProxy
        guard let text = proxy.documentContextBeforeInput, !text.isEmpty else {
            feedback.impactOccurred(intensity: 0.3)   // nothing to transform
            return
        }
        let cipher = currentCipher()
        let result = encode ? cipher.encode(text) : cipher.decode(text)
        for _ in 0..<text.count { proxy.deleteBackward() }
        proxy.insertText(result)
        feedback.impactOccurred()
    }
}
