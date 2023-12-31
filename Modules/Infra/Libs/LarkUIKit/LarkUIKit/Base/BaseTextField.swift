//
//  BaseTextField.swift
//  Lark
//
//  Created by 刘晚林 on 2017/1/8.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
open class BaseTextField: UITextField {
    @IBInspectable open var contentInset: UIEdgeInsets = .zero
    @IBInspectable open var maxLength: Int = Int.max
    @IBInspectable open var exitOnReturn: Bool = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    open func commonInit() {
        self.clipsToBounds = true
        self.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        self.addTarget(self, action: #selector(editingDidEndOnExit), for: .editingDidEndOnExit)
    }

    // 无需特殊处理 left & right view, super已经处理
    // placeholder position
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: bounds).inset(by: contentInset)
    }

    // 无需特殊处理 left & right view, super已经处理
    // text position
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.editingRect(forBounds: bounds).inset(by: contentInset)
    }

    open func cut(_ text: String) -> (Bool, String) {
        var chCount = 0
        var bytesCount = 0
        var lengthExceed = false
        for ch in text {
            let chBytes = "\(ch)".lengthOfBytes(using: String.Encoding.utf8) >= 3 ? 2 : 1
            if bytesCount + chBytes > self.maxLength {
                lengthExceed = true
                break
            }
            chCount += 1
            bytesCount += chBytes
        }
        return (lengthExceed, String(text[..<text.index(text.startIndex, offsetBy: chCount)]))
    }

    @objc
    fileprivate func editingChanged() {
        guard let text = self.text else {
            return
        }

        let (lengthExceed, result) = cut(text)
        if lengthExceed {
            self.text = result
        }
    }

    @objc
    fileprivate func editingDidEndOnExit() {
        if self.exitOnReturn {
            self.endEditing(true)
        }
    }
}
