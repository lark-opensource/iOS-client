//
//  NewEventContentView.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/4.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import CalendarFoundation

final class NewEventContentTextField: UITextField {

    var maxLength = 400
    init(inset: CGFloat) {
        self.inset = inset
        super.init(frame: .zero)
        self.addTarget(self, action: #selector(textChanged(textField:)), for: .editingChanged)
        self.tintColor = UIColor.ud.primaryContentDefault
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func textChanged(textField: UITextField) {
        if let filteredText = textField.filteredTextWithMaxLength(maxLength: self.maxLength, text: textField.text ?? "") {
            textField.text = filteredText
        }
    }

    var inset: CGFloat = 10

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        if self.shouldShowOriginalInsets() {
            return super.textRect(forBounds: bounds)
        }
        return bounds.insetBy(dx: inset, dy: 0)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        if self.shouldShowOriginalInsets() {
            return super.editingRect(forBounds: bounds)
        }
        return bounds.insetBy(dx: inset, dy: 0)
    }

    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        if self.shouldShowOriginalInsets() {
            return super.placeholderRect(forBounds: bounds)
        }
        return bounds.insetBy(dx: inset, dy: 0)
    }

    private func shouldShowOriginalInsets() -> Bool {
        return self.leftView != nil || self.rightView != nil || self.inset == 0
    }
}

private extension UITextInput {
    func filteredTextWithMaxLength(maxLength: Int, text: String) -> String? {
        let toBeString = text as NSString
        if let selectedRange = self.markedTextRange, self.position(from: selectedRange.start, offset: 0) != nil {
            return nil
        }
        if toBeString.length <= maxLength {
            return nil
        }
        let range = toBeString.rangeOfComposedCharacterSequence(at: maxLength)
        if range.length == 1 {// 普通字符
            return toBeString.substring(to: maxLength) as String
        } else {
            let desRange = toBeString.rangeOfComposedCharacterSequences(for: NSRange(location: 0, length: maxLength))
            return toBeString.substring(with: desRange) as String
        }
    }
}
