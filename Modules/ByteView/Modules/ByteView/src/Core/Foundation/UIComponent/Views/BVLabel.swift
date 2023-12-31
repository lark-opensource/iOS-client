//
//  BVLabel.swift
//  ByteView
//
//  Created by yangfukai on 2020/11/13.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

class BVLabel: UILabel {
    var textContainerInset: UIEdgeInsets = .zero

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height += textContainerInset.top + textContainerInset.bottom
        size.width += textContainerInset.left + textContainerInset.right
        return size
    }

    override func draw(_ rect: CGRect) {
        super.drawText(in: rect.inset(by: textContainerInset))
    }

    override var bounds: CGRect {
        didSet {
            preferredMaxLayoutWidth = bounds.width - (textContainerInset.left + textContainerInset.right)
        }
    }

}
