//
//  UDLoading+Theme.swift
//  UniverseDesignLoading
//
//  Created by Miaoqi Wang on 2020/11/19.
//

import UIKit
import Foundation
import UniverseDesignColor

/// UDLoading theme name
public extension UDColor.Name {
    /// Spin indicator color default colorfulBlue
    static let loadingSpinIndicatorPrimary = UDColor.Name("loading-spin-indicator-primary")
    /// Spin text color default N600
    static let loadingSpinTextPrimary = UDColor.Name("loading-spin-text-primary")
    /// Spin indicator color default N00
    static let loadingSpinIndicatorWhite = UDColor.Name("loading-spin-indicator-white")
    /// Spin text color default N00
    static let loadingSpinTextWhite = UDColor.Name("loading-spin-text-white")
    /// Spin indicator color default N400
    static let loadingSpinIndicatorGray = UDColor.Name("loading-spin-indicator-gray")
    /// Spin text color default N400
    static let loadingSpinTextGray = UDColor.Name("loading-spin-text-gray")

    /// Skeleton animation color start from default N200
    static let loadingSkeletionAnimationColor = UDColor.Name("loading-skeleton-animation-color")

    /// Loading Image VC Background Color default N00
    static let loadingImageVCBgColor = UDColor.Name("loading-image-bg-color")
}

/// UDLoading color theme
struct UDLoadingColorTheme {

    /// spin color
    /// - Parameter preset: preset style
    static func spinColor(preset: UDSpin.PresetColor) -> (UIColor, UIColor) {
        let pColor = preset.defaultColor()
        switch preset {
        case .primary:
            return (UDColor.getValueByKey(.loadingSpinIndicatorPrimary) ?? pColor.indicator,
                    UDColor.getValueByKey(.loadingSpinTextPrimary) ?? pColor.text)
        case .neutralGray:
            return (UDColor.getValueByKey(.loadingSpinIndicatorGray) ?? pColor.indicator,
                    UDColor.getValueByKey(.loadingSpinTextGray) ?? pColor.text)
        case .neutralWhite:
            return (UDColor.getValueByKey(.loadingSpinIndicatorWhite) ?? pColor.indicator,
                    UDColor.getValueByKey(.loadingSpinTextWhite) ?? pColor.text)
        }
    }

    static var skeletonColor: UIColor {
        UDColor.getValueByKey(.loadingSpinIndicatorPrimary) ?? UIColor.ud.neutralColor4
    }

    static var loadingImageVCBgColor: UIColor {
        UDColor.getValueByKey(.loadingImageVCBgColor) ?? UIColor.ud.neutralColor1
    }
}
