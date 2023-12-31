//
//  FlatTextField.swift
//  ByteView
//
//  Created by fakegourmet on 2020/8/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import UIKit
import UniverseDesignColor

extension FlatTextField {
    var placeHolder: String? {
        get { textFieldView.placeholder }
        set { textFieldView.placeholder = newValue }
    }
    var textFieldFont: UIFont? {
         get { textFieldView.font }
         set { textFieldView.font = newValue }
     }
    var returnKeyType: UIReturnKeyType {
        get { textFieldView.returnKeyType }
        set { textFieldView.returnKeyType = newValue }
    }
}

final class FlatTextField: UIView, UITextFieldDelegate {

    let pinyinSpace = "\u{2006}"

    func removeWhiteSpaceAndNewLines(_ text: String) -> String {
        let text = text.filter({ !$0.isWhitespace && !$0.isNewline })
        // replace pinyin space if has, usually happy when inputting email using pinyin
        return text.replacingOccurrences(of: pinyinSpace, with: "")
    }

    var currentText: String? {
        guard let text = textFieldView.text else {
            return nil
        }
        return removeWhiteSpaceAndNewLines(text)
    }

    lazy var textFieldView: UITextField = {
        let textView = AllowPasteTextField()
        textView.contentVerticalAlignment = .center
        textView.textColor = UIColor.ud.textTitle
        textView.tintColor = UIColor.ud.textTitle
        textView.clearButtonMode = .whileEditing
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.delegate = self
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.addTarget(
            self,
            action: #selector(textFieldEditingChanged),
            for: .editingChanged
        )
        textView.keyboardType = .asciiCapable
        return textView
    }()

    init() {
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        addSubview(borderView)
        addSubview(textFieldView)

        borderView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        textFieldView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(Layout.insetSpace)
            make.right.equalToSuperview().offset(-Layout.internalSpace)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }
    }

    override func becomeFirstResponder() -> Bool {
        return textFieldView.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        return textFieldView.resignFirstResponder()
    }

    @objc
    func textFieldEditingChanged(_ textView: UITextField) {

    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        borderView.update(highlight: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        borderView.update(highlight: false)
    }

    // MARK: border
    lazy var borderView: BorderView = {
        return BorderView()
    }()

}

extension FlatTextField {
    struct Layout {
        static let internalSpace: CGFloat = 6.0
        static let insetSpace: CGFloat = 12.0
    }
}
