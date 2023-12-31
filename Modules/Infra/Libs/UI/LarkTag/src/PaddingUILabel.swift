//
//  PaddingUILabel.swift
//  LarkUIKit
//
//  Created by 刘晚林 on 2016/12/16.
//  Copyright © 2016年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

/// 显示Title的Label
open class PaddingUILabel: UILabel {

    private var padding = UIEdgeInsets.zero

    open var cornerRadius: CGFloat = 0
    open var color = UIColor.ud.colorfulRed {
        didSet {
            backgroundColor = color
        }
    }

    /// iOS 12及以前的版本上，如果UILabel被添加到Cell上，当cell处于高亮状态的时候，UILabel的背景颜色会被置为.clear
    open override var backgroundColor: UIColor? {
        didSet {
            if backgroundColor != color {
                backgroundColor = color
            }
        }
    }

    open var paddingLeft: CGFloat {
        get { return padding.left }
        set { padding.left = newValue }
    }

    open var paddingRight: CGFloat {
        get { return padding.right }
        set { padding.right = newValue }
    }

    open var paddingTop: CGFloat {
        get { return padding.top }
        set { padding.top = newValue }
    }

    open var paddingBottom: CGFloat {
        get { return padding.bottom }
        set { padding.bottom = newValue }
    }

    override open func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: padding))
    }

    override open func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insets = self.padding
        var rect = super.textRect(forBounds: bounds.inset(by: insets), limitedToNumberOfLines: numberOfLines)
        rect.origin.x -= insets.left
        rect.origin.y -= insets.top
        rect.size.width += (insets.left + insets.right)
        rect.size.height += (insets.top + insets.bottom)
        return rect
    }
}
