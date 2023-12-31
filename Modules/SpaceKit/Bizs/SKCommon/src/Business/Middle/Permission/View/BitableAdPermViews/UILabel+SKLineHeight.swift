//
//  UILabel+SKLineHeight.swift
//  SKCommon
//
//  Created by zhysan on 2022/8/3.
//

import UIKit
import UniverseDesignColor
import UniverseDesignFont

extension UILabel {
    
    /// 为 UILabel 设置多行文本，根据预期行高设置行间距
    /// - Parameters:
    ///   - text: 文本内容
    ///   - expectedLineHeight: 预期行高
    ///   - font: 文本字体
    ///   - textColor: 文本颜色
    func sk_setText(
        _ text: String,
        expectedLineHeight: CGFloat = 20.0,
        font: UIFont = UIFont.ud.body2,
        textColor: UIColor = UIColor.ud.textCaption
    ) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = max(0, expectedLineHeight - font.lineHeight)
        let attributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.paragraphStyle: style,
            NSAttributedString.Key.foregroundColor: textColor
        ]
        numberOfLines = 0
        attributedText = NSAttributedString(string: text, attributes: attributes)
    }
}
