//
//  UILabelWithInset.swift
//  Calendar
//
//  Created by jiayi zou on 2018/5/24.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import CalendarFoundation
final class UILabelWithInset: UILabel {
    private let insets: UIEdgeInsets
    init(insets: UIEdgeInsets = .zero) {
        self.insets = insets
        super.init(frame: CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        if size.width > 0 && size.height > 0 {
            size.height += (insets.top + insets.bottom)
            size.width += (insets.left + insets.right)
        }
        return size
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }
}
