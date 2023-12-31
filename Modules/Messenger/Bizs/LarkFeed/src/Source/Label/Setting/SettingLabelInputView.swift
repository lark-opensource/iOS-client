//
//  SettingLabelInputView.swift
//  LarkFeed
//
//  Created by aslan on 2022/4/19.
//

import Foundation
import LarkUIKit
import UniverseDesignColor
import UIKit

final class SettingLabelInputView: UIView, UITextFieldDelegate {
    private let textMaxLength: Int
    private let placeholder: String
    let textField = BaseTextField(frame: .zero)
    var textFieldDidChangeHandler: ((UITextField) -> Void)?
    var text: String? {
        get { return self.textField.text }
        set {
            self.textField.text = newValue
            inputViewTextFieldDidChange(self.textField)
        }
    }

    init(textMaxLength: Int, placeholder: String) {
        self.textMaxLength = textMaxLength
        self.placeholder = placeholder
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgFloat
        textField.delegate = self
        textField.exitOnReturn = true
        textField.textAlignment = .left
        textField.borderStyle = .none
        textField.textColor = UIColor.ud.textTitle
        textField.backgroundColor = UIColor.ud.bgFloat
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(inputViewTextFieldDidChange(_:)), for: .editingChanged)
        textField.placeholder = placeholder
        textField.maxLength = self.textMaxLength
        let placeholderAttr = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.ud.textPlaceholder
            ]
        )
        textField.attributedPlaceholder = placeholderAttr
        self.addSubview(textField)
        textField.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.right.equalToSuperview().offset(-7)
            make.height.equalTo(22)
            make.top.equalToSuperview().offset(13)
            make.bottom.equalToSuperview().offset(-13)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func inputViewTextFieldDidChange(_ textField: UITextField) {
        if let handler = self.textFieldDidChangeHandler {
            handler(textField)
        }
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
}
