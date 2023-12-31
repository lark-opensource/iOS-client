//
//  BTInsetLabel.swift
//  SKBitable
//
//  Created by X-MAN on 2023/6/14.
//

import Foundation

class BTInsetLabel: UILabel {
    
    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
           let insetRect = bounds.inset(by: textInsets)
           let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
           let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                                             left: -textInsets.left,
                                             bottom: -textInsets.bottom,
                                             right: -textInsets.right)
           return textRect.inset(by: invertedInsets)
       }

    override func drawText(in rect: CGRect) {
           super.drawText(in: rect.inset(by: textInsets))
    }
}
