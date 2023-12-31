//
//  UDTabsViewTool.swift
//  UniverseDesignTabs
//
//  Created by 姚启灏 on 2020/12/8.
//

import Foundation
import UIKit

// swiftlint:disable all

public final class UDTabsViewTool {
    
    public static func interpolate<T: SignedNumeric & Comparable>(
        from: T, to: T, percent: T) -> T {
        let percent = max(0, min(1, percent))
        return from + (to - from) * percent
    }

    public static func interpolateColor(from: UIColor, to: UIColor, percent: CGFloat) -> UIColor {
        let udRed = interpolate(from: from.udRed, to: to.udRed, percent: percent)
        let udGreen = interpolate(from: from.udGreen, to: to.udGreen, percent: CGFloat(percent))
        let udBlue = interpolate(from: from.udBlue, to: to.udBlue, percent: CGFloat(percent))
        let udAlpha = interpolate(from: from.udAlpha, to: to.udAlpha, percent: CGFloat(percent))
        return UIColor(red: udRed, green: udGreen, blue: udBlue, alpha: udAlpha)
    }
}

private extension UIColor {
    var udRed: CGFloat {
        var udRed: CGFloat = 0
        getRed(&udRed, green: nil, blue: nil, alpha: nil)
        return udRed
    }

    var udGreen: CGFloat {
        var udGreen: CGFloat = 0
        getRed(nil, green: &udGreen, blue: nil, alpha: nil)
        return udGreen
    }

    var udBlue: CGFloat {
        var udBlue: CGFloat = 0
        getRed(nil, green: nil, blue: &udBlue, alpha: nil)
        return udBlue
    }

    var udAlpha: CGFloat {
        return cgColor.alpha
    }
}

// swiftlint:enable all
