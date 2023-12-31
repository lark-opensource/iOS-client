//
//  BaseTextField.swift
//  Lark
//
//  Created by 刘晚林 on 2017/1/8.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit

@IBDesignable
open class SKTextField: SKBaseTextField {

    @IBInspectable var insetX: CGFloat = 0
    @IBInspectable var insetY: CGFloat = 0
    @IBInspectable var maxLength: Int = Int.max
    @IBInspectable var exitOnReturn: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        self.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        self.addTarget(self, action: #selector(editingDidEndOnExit), for: .editingDidEndOnExit)
    }

    // placeholder position
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        var insetX = self.insetX
        if let leftView = self.leftView {
            insetX += leftView.bounds.width
        }
        return bounds.insetBy(dx: insetX, dy: insetY)
    }

    // text position
    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var insetX = self.insetX
        if let leftView = self.leftView {
            insetX += leftView.bounds.width
        }
        return bounds.insetBy(dx: insetX, dy: insetY)
    }

    @objc
    fileprivate func editingChanged() {
        guard let text = self.text else {
            return
        }

        if text.count > self.maxLength {
            self.text = String(text[..<text.index(text.startIndex, offsetBy: self.maxLength)])
        }
    }

    @objc
    fileprivate func editingDidEndOnExit() {
        if self.exitOnReturn {
            self.endEditing(true)
        }
    }

}
