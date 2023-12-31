//
//  PaddingTextField.swift
//  Todo
//
//  Created by wangwanxin on 2022/9/4.
//

import Foundation
import UniverseDesignDialog
import UniverseDesignFont

final class PaddingTextField: UITextField {

    override func borderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: .init(horizontal: 13, vertical: 13))
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: .init(horizontal: 13, vertical: 13))
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: .init(horizontal: 13, vertical: 13))
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: .init(horizontal: 13, vertical: 13))
    }

}

extension PaddingTextField {

    struct TextFieldInput {
        var text: String?
        var title: String
        var placeholder: String
    }

    struct Config {
        static let topMargin = 12.0
        static let leftMargin = 20.0
        static let bottomMargin = 20.0
        static let rightMargin = 24.0
    }

    static func showTextField(with input: TextFieldInput, from: UIViewController, completion: ((String?) -> Void)? = nil) {
        let textField: PaddingTextField = {
            let textField = PaddingTextField()
            textField.text = input.text
            textField.attributedPlaceholder = AttrText(
                string: input.placeholder,
                attributes: [
                    .foregroundColor: UIColor.ud.textPlaceholder,
                    .font: UDFont.systemFont(ofSize: 16, weight: .regular)
                ]
            )
            textField.layer.borderColor = UIColor.ud.N400.cgColor
            textField.layer.borderWidth = 1
            textField.layer.cornerRadius = 6
            textField.font = UDFont.systemFont(ofSize: 16)
            textField.textColor = UIColor.ud.textTitle
            return textField
        }()
        let uiConfig = UDDialogUIConfig(
            titleAlignment: .left,
            contentMargin: .init(
                top: Config.topMargin,
                left: Config.leftMargin,
                bottom: Config.bottomMargin,
                right: Config.rightMargin
            ))
        let dialog = UDDialog(config: uiConfig)
        dialog.setTitle(text: input.title)
        dialog.setContent(view: textField)
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: I18N.Todo_Task_Confirm, dismissCompletion:  { [weak textField] in
            completion?(textField?.text)
        })
        from.present(dialog, animated: true)
        // 需要到最后，不然长name的时候光标定位不到
        if #available(iOS 16.0, *) {
            textField.becomeFirstResponder()
        } else {
            DispatchQueue.main.async {
                textField.becomeFirstResponder()
            }
        }
    }
}
