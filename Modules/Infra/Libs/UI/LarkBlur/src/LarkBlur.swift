//
//  LarkBlur.swift
//  LarkBlur
//
//  Created by Saafo on 2021/5/11.
//

import UIKit
import FigmaKit

public typealias LarkBlurEffectView = VisualBlurView

public extension LarkBlurEffectView {

    /// Tint color.
    public var colorTint: UIColor? {
        get { fillColor }
        set { fillColor = newValue }
    }

    /// Tint color alpha.
    public var colorTintAlpha: CGFloat {
        get { fillOpacity }
        set { fillOpacity = newValue }
    }
}
