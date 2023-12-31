//
//  RenameTextField.swift
//  ByteView
//
//  Created by kiri on 2023/1/10.
//

import Foundation
import UniverseDesignInput
import ByteViewNetwork

final class RenameTextField: UDTextField {
    private let number: Int = 64

    var enableUpdator: ((Bool) -> Void)?
    private var lastText: String?
    private let handler = RenameTextFieldHandler()

    lazy var endEditingTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onEndEditingTap(_:)))

    init() {
        super.init(config: UDTextFieldUIConfig(isShowBorder: true))
        self.delegate = self.handler
        self.handler.owner = self
        self.input.addTarget(handler, action: #selector(RenameTextFieldHandler.textFieldChanged(_:)), for: .editingChanged)
        _ = self.endEditingTapGestureRecognizer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.endEditingTapGestureRecognizer.isEnabled = false
    }

    @objc private func onEndEditingTap(_ gr: UITapGestureRecognizer) {
        self.endEditing(true)
    }
}

private  class RenameTextFieldHandler: NSObject, UDTextFieldDelegate {
    private let number: Int = 64
    private var text: String?

    weak var owner: RenameTextField?

    @objc func textFieldChanged(_ textField: UITextField) {
        guard textField.markedTextRange == nil else { return }
        guard text != textField.text else { return }
        if let procText = textField.text?.trimmingCharacters(in: CharacterSet.controlCharacters).prefix(number) {
            text = String(procText)
            textField.text = text
            owner?.enableUpdator?(!procText.isEmpty)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
