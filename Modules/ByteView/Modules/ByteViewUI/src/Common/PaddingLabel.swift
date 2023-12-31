//
//  PaddingLabel.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/4/19.
//

import UIKit

open class PaddingLabel: UILabel {

    open var textInsets: UIEdgeInsets = .zero {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
            setNeedsLayout()
        }
    }

    open override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }

    open override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
}
