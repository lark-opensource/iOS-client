//
//  ShareScreenVerifyTextField.swift
//  ByteView
//
//  Created by helijian on 2021/8/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit

class ShareScreenVerifyTextField: UIView {

    typealias CodeBlock = (String) -> Void
    private let groupWidth: [UInt]
    private let groupKern: CGFloat
    static let maxInputNum = 9
    static let maxInputChar = 6
    var isCharacter = false

    private let selectCodeBlock: CodeBlock?
    private let confirmCodeBlock: CodeBlock?

    var text: String? {
        if isCharacter {
            return textFieldView.text?.uppercased()
        } else {
            return textFieldView.text
        }
    }

    init(groupWidth: [UInt] = [3],
         groupKern: CGFloat = 4.0,
         confirmCodeBlock: @escaping CodeBlock,
         selectCodeBlock: @escaping CodeBlock) {
        self.groupWidth = groupWidth
        self.groupKern = groupKern
        self.confirmCodeBlock = confirmCodeBlock
        self.selectCodeBlock = selectCodeBlock
        super.init(frame: .zero)
        setupInputViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var textFieldView: NoActionTextField = {
        let tf = NoActionTextField()
        tf.addTarget(self, action: #selector(handleTextChanged), for: .editingChanged)
        tf.textColor = UIColor.ud.textTitle
        tf.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        tf.autocorrectionType = .no
        tf.keyboardType = .alphabet
        tf.autoresizingMask = .flexibleWidth
        tf.autocapitalizationType = .allCharacters
        tf.delegate = self
        return tf
    }()

    lazy var bottomLine: UIView = {
        let bottomLine = UIView()
        bottomLine.backgroundColor = UIColor.ud.primaryContentDefault
        return bottomLine
    }()

    func setupInputViews() {
        addSubview(textFieldView)
        textFieldView.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(22)
        }
        addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.top.equalTo(textFieldView.snp.bottom).offset(3)
            make.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    @objc func handleTextChanged(_ textField: UITextField) {
        guard let text = text else { return }
        let selectedRange = textFieldView.selectedTextRange
        textFieldView.attributedText = convert(text: text)
        textFieldView.selectedTextRange = selectedRange
        callbackTextChange()
    }

    func convert(text: String) -> NSAttributedString {
        let attriStr = NSMutableAttributedString()
        let lastOffset = text.count - 1
        var previousOffset: Int = 0
        var groupIndex: Int = 0
        if groupWidth != [] {
            var currentWidth: UInt = groupWidth[groupIndex]
            for entry in text.enumerated() {
                if (entry.offset - previousOffset) % Int(currentWidth) == currentWidth - 1 && entry.offset != lastOffset {
                    attriStr.append(NSAttributedString(string: String(entry.element), attributes: [NSAttributedString.Key.kern: groupKern]))
                    groupIndex += 1
                    previousOffset = entry.offset + 1
                    if groupIndex < groupWidth.count {
                        currentWidth = groupWidth[groupIndex]
                    }
                } else {
                    attriStr.append(NSAttributedString(string: String(entry.element)))
                }
            }
        } else {
            for entry in text.enumerated() {
                attriStr.append(NSAttributedString(string: String(entry.element)))
            }
        }
        return attriStr
    }

    private func callbackTextChange() {
        self.selectCodeBlock?(text ?? "")
    }

    func beginEdit() {
        textFieldView.becomeFirstResponder()
    }

    func onError() {
        beginEdit()
    }
}

extension ShareScreenVerifyTextField: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var text = text ?? ""
        guard let strRange = Range<String.Index>(range, in: text) else { return false }
        text.replaceSubrange(strRange, with: string)
        if text.count == 1 {
            if text.allSatisfy({ $0.isLetter && $0.isASCII }) {
                isCharacter = true
                return true
            }
            if text.allSatisfy({ $0.isNumber && $0.isASCII }) {
                isCharacter = false
                return true
            }
            return false
        } else {
            if isCharacter {
                return text.count <= ShareScreenVerifyTextField.maxInputChar && text.allSatisfy { $0.isLetter && $0.isASCII }
            } else {
                return text.count <= ShareScreenVerifyTextField.maxInputNum && text.allSatisfy { $0.isNumber && $0.isASCII }
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let code = textField.text else {
            return false
        }
        if isCharacter {
            guard code.count == ShareScreenVerifyTextField.maxInputChar else { return false }
        } else {
            guard code.count == ShareScreenVerifyTextField.maxInputNum else { return false }
        }
        self.confirmCodeBlock?(code)
        return true
    }

    private class NoActionTextField: UITextField {
        override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            return false
        }
    }
}
