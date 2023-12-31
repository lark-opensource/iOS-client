//
//  SKHighlightButton.swift
//  SKUIKit
//
//  Created by Weston Wu on 2020/12/14.
//

import UIKit

// 点击高亮时，动态配置背景颜色
open class SKHighlightButton: DocsButton {
    open var highlightBackgroundColor: UIColor?
    open var disabledBackgroundColor: UIColor?
    open var normalBackgroundColor: UIColor? {
        didSet {
            backgroundColor = normalBackgroundColor
        }
    }
    open override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightBackgroundColor : normalBackgroundColor
        }
    }

    open override var isEnabled: Bool {
        didSet {
            backgroundColor = isEnabled ? disabledBackgroundColor : normalBackgroundColor
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        normalBackgroundColor = backgroundColor
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        normalBackgroundColor = backgroundColor
    }
}
