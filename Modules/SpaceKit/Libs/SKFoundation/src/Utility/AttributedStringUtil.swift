//
//  AttributedStringUtil.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/3/17.
//

import Foundation

/// 用于完成富文本算高等功能的富文本工具
public final class AttributedStringUtil {
    static let calculator: UITextView = {
        let tv = UITextView()
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        return tv
    }()

    /// 计算attributeString渲染后高度(注：计算结果为去除文字padding及内边距的，具体请了解textContainerInset及textContainer.lineFragmentPadding)
    public static func heightOf(_ attrStr: NSAttributedString, byWidth width: CGFloat) -> CGFloat {
        calculator.attributedText = attrStr
        let targetSize = calculator.sizeThatFits(CGSize(width: width, height: CGFloat.greatestFiniteMagnitude))
        return targetSize.height
    }
}
