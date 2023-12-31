//
//  UIView+Highlightable.swift
//  Calendar
//
//  Created by harry zou on 2018/12/25.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit

open class HighlightableView: UIView {
    public var highlightColor: UIColor {
        return UIColor.ud.N300.withAlphaComponent(0.5)
    }
    private var originalBackgroundColor: UIColor?
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        originalBackgroundColor = self.backgroundColor
        self.backgroundColor = highlightColor
    }

    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = originalBackgroundColor
    }

    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.backgroundColor = originalBackgroundColor
    }

}
