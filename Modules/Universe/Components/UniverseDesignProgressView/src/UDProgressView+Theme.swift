//
//  UDProgressView+Theme.swift
//  UniversalDesignProgressView
//
//  Created by CJ on 2020/12/23.
//
// swiftlint:disable all

import UIKit
import Foundation
import UniverseDesignColor

/// UDColor Name Extension
public extension UDColor.Name {
    /// progressLinearTextColor
    static let progressLinearTextColor = UDColor.Name("progress-linear-text-color")
    
    /// progressLinearBgColor
    static let progressLinearBgColor = UDColor.Name("progress-linear-bg-color")
    
    /// progressLinearIndicatorProgressingColor
    static let progressLinearIndicatorProgressingColor = UDColor.Name("progress-linear-indicator-progressing-color")
    
    /// progressLinearIndicatorSuccessColor
    static let progressLinearIndicatorSuccessColor = UDColor.Name("progress-linear-indicator-success-color")
    
    /// progressLinearIndicatorErrorColor
    static let progressLinearIndicatorErrorColor = UDColor.Name("progress-linear-indicator-error-color")
    
    /// progressCircularTextColor
    static let progressCircularTextColor = UDColor.Name("progress-circular-text-color")
    
    /// progressCircularBgColor
    static let progressCircularBgColor = UDColor.Name("progress-circular-bg-color")
    
    /// progressCircularIndicatorProgressingColor
    static let progressCircularIndicatorProgressingColor = UDColor.Name("progress-circular-indicator-color")
    
    /// progressCircularDarkTextColor
    static let progressCircularDarkTextColor = UDColor.Name("progress-dark-circular-text-color")
    
    /// progressCircularDarkBgColor
    static let progressCircularDarkBgColor = UDColor.Name("progress-dark-circular-bg-color")
    
    /// progressCircularDarkIndicatorProgressingColor
    static let progressCircularDarkIndicatorProgressingColor = UDColor.Name("progress-dark-circular-indicator-color")
}

/// UDProgressView Color Theme
public struct UDProgressViewColorTheme {
    /// progressLinearTextColor, default color: UDColor.textPlaceholder
    public static var progressLinearTextColor: UIColor {
        return UDColor.getValueByKey(.progressLinearTextColor) ?? UDColor.textPlaceholder
    }
    
    /// progressLinearBgColor, default color: UDColor.udtokenProgressBg
    public static var progressLinearBgColor: UIColor {
        return UDColor.getValueByKey(.progressLinearBgColor) ?? UDColor.udtokenProgressBg
    }
    
    /// progressLinearIndicatorProgressingColor, default color: UDColor.primaryContentDefault
    public static var progressLinearIndicatorProgressingColor: UIColor {
        return UDColor.getValueByKey(.progressLinearIndicatorProgressingColor) ?? UDColor.primaryContentDefault
    }
    
    /// progressLinearIndicatorSuccessColor, default color: UDColor.functionSuccessContentDefault
    public static var progressLinearIndicatorSuccessColor: UIColor {
        return UDColor.getValueByKey(.progressLinearIndicatorSuccessColor) ?? UDColor.functionSuccessContentDefault
    }
    
    /// progressLinearIndicatorErrorColor, default color: UDColor.functionDangerContentDefault
    public static var progressLinearIndicatorErrorColor: UIColor {
        return UDColor.getValueByKey(.progressLinearIndicatorErrorColor) ?? UDColor.functionDangerContentDefault
    }
    
    /// progressCircularTextColor, default color: UDColor.textPlaceholder
    public static var progressCircularTextColor: UIColor {
        return UDColor.getValueByKey(.progressCircularTextColor) ?? UDColor.textPlaceholder
    }
    
    /// progressCircularBgColor, default color: UDColor.udtokenProgressBg
    public static var progressCircularBgColor: UIColor {
        return UDColor.getValueByKey(.progressCircularBgColor) ?? UDColor.udtokenProgressBg
    }
    
    /// progressCircularIndicatorProgressingColor, default color: UDColor.primaryContentDefault
    public static var progressCircularIndicatorProgressingColor: UIColor {
        return UDColor.getValueByKey(.progressCircularBgColor) ?? UDColor.primaryContentDefault
    }
    
    /// progressCircularDarkTextColor, default color: UDColor.primaryOnPrimaryFill
    public static var progressCircularDarkTextColor: UIColor {
        return UDColor.getValueByKey(.progressCircularDarkTextColor) ?? UDColor.primaryOnPrimaryFill
    }
    
    /// progressCircularDarkBgColor, default color: UDColor.N900, alpha 0.6
    public static var progressCircularDarkBgColor: UIColor {
        return UDColor.getValueByKey(.progressCircularDarkBgColor) ?? UDColor.N900.withAlphaComponent(0.6)
    }
    
    /// progressCircularDarkIndicatorProgressingColor, default color: UDColor.primaryOnPrimaryFill
    public static var progressCircularDarkIndicatorProgressingColor: UIColor {
        return UDColor.getValueByKey(.progressCircularDarkIndicatorProgressingColor) ?? UDColor.primaryOnPrimaryFill
    }
}
// swiftlint:enable all
