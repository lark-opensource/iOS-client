//
//  UILabel+Lark.swift
//  Lark
//
//  Created by 齐鸿烨 on 2016/12/20.
//  Copyright © 2016年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkCompatible
import UIKit
import UniverseDesignColor
import UniverseDesignTheme

public extension LarkUIKitExtension where BaseType == UILabel {
    func setLineHeight(_ lineHeight: CGFloat) {
        guard let text = self.base.text else {
            return
        }

        let attributeString = NSMutableAttributedString(string: text)
        let style = NSMutableParagraphStyle()

        style.lineSpacing = lineHeight

        attributeString.addAttribute(NSAttributedString.Key.paragraphStyle,
                                     value: style, range: NSRange(location: 0, length: text.count))
        self.base.attributedText = attributeString
    }

    /// 初始化Label
    @discardableResult
    func setProps(fontSize: CGFloat = 12,
                  numberOfLine: Int = 0,
                  textColor: UIColor = UIColor.ud.N900) -> BaseType {
        self.base.font = UIFont.systemFont(ofSize: fontSize)
        self.base.numberOfLines = numberOfLine
        self.base.text = ""
        self.base.textColor = textColor
        self.base.sizeToFit()
        self.base.backgroundColor = UIColor.clear
        return self.base
    }

    /// 初始化Bold Label
    @discardableResult
    func setProps(boldFontSize: CGFloat = 12,
                  numberOfLine: Int = 0,
                  textColor: UIColor = UIColor.ud.N900) -> UILabel {
        self.setProps(fontSize: boldFontSize, numberOfLine: numberOfLine, textColor: textColor)
        self.base.font = UIFont.systemFont(ofSize: boldFontSize, weight: .medium)
        return self.base
    }

    class func labelWith(fontSize: CGFloat,
                         textColor: UIColor,
                         text: String? = nil,
                         bold: Bool = false) -> UILabel {
        let label = UILabel()
        label.font = bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
        label.textColor = textColor
        label.text = text
        return label
    }
}
