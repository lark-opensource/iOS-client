//
//  UDProgressViewUIConfig.swift
//  UniversalDesignProgressView
//
//  Created by CJ on 2020/12/23.
//

import UIKit
import Foundation
/// progress view type
public enum UDProgressViewType {
    /// linear
    case linear
    /// circular
    case circular
}

/// progress view metrics
public enum UDProgressViewBarMetrics {
    /// default，height is 4px
    case `default`
    /// regular，height is 12px
    case regular
}

/// progress view dayout direction
public enum UDProgressViewLayoutDirection {
    /// horizontal
    case horizontal
    /// vertical
    case vertical
}

/// progress view theme color
public struct UDProgressViewThemeColor {
    let textColor: UIColor
    let bgColor: UIColor
    let indicatorColor: UIColor
    let successIndicatorColor: UIColor
    let errorIndicatorColor: UIColor
    /// init
    /// - Parameters:
    ///   - textColor: value label textColor
    ///   - bgColor: progress  bgColor
    ///   - indicatorColor: progress  indicator color
    ///   - successIndicatorColor: progress success indicator color
    ///   - errorIndicatorColor: progress error indicator color
    public init(textColor: UIColor = UDProgressViewColorTheme.progressLinearTextColor,
                bgColor: UIColor = UDProgressViewColorTheme.progressLinearBgColor,
                indicatorColor: UIColor = UDProgressViewColorTheme.progressLinearIndicatorProgressingColor,
                successIndicatorColor: UIColor = UDProgressViewColorTheme.progressLinearIndicatorSuccessColor,
                errorIndicatorColor: UIColor = UDProgressViewColorTheme.progressLinearIndicatorErrorColor
    ) {
        self.textColor = textColor
        self.bgColor = bgColor
        self.indicatorColor = indicatorColor
        self.successIndicatorColor = successIndicatorColor
        self.errorIndicatorColor = errorIndicatorColor
    }
    /// mask theme colorf
    public static var maskThemeColor: UDProgressViewThemeColor {
        return UDProgressViewThemeColor(textColor: UDProgressViewColorTheme.progressCircularDarkTextColor,
                          bgColor: UDProgressViewColorTheme.progressCircularDarkBgColor,
                          indicatorColor: UDProgressViewColorTheme.progressCircularDarkIndicatorProgressingColor)
    }
}

/// UDProgressView UI Config
public struct UDProgressViewUIConfig {
    /// progress view type, default linear
    public let type: UDProgressViewType
    /// progress view metrics
    public let barMetrics: UDProgressViewBarMetrics
    /// progress view dayout direction, default horizontal
    public let layoutDirection: UDProgressViewLayoutDirection
    /// themeColor
    public let themeColor: UDProgressViewThemeColor
    /// whether to display  progress value, default false
    public let showValue: Bool
    /// init
    /// - Parameters:
    ///   - type: progress view type
    ///   - barMetrics: progress view metrics
    ///   - layoutDirection: progress view dayout direction
    ///   - themeColor: themeColor
    ///   - showValue: showValue
    public init(type: UDProgressViewType = .linear,
                barMetrics: UDProgressViewBarMetrics = .default,
                layoutDirection: UDProgressViewLayoutDirection = .horizontal,
                themeColor: UDProgressViewThemeColor = UDProgressViewThemeColor(),
                showValue: Bool = false) {
        self.type = type
        self.barMetrics = barMetrics
        self.layoutDirection = layoutDirection
        self.themeColor = themeColor
        self.showValue = showValue
    }
}

/// ProgressView Layout Config
public struct UDProgressViewLayoutConfig {
    let linearSmallCornerRadius: CGFloat
    let linearBigCornerRadius: CGFloat
    let linearProgressDefaultHeight: CGFloat
    let linearProgressRegularHeight: CGFloat
    let linearHorizontalMargin: CGFloat
    let linearVerticalMargin: CGFloat
    let valueLabelWidth: CGFloat
    let valueLabelHeight: CGFloat
    let circleProgressWidth: CGFloat
    let circleProgressLineWidth: CGFloat
    let circularHorizontalMargin: CGFloat
    let circularverticalMargin: CGFloat

    public init(linearSmallCornerRadius: CGFloat = 2,
                linearBigCornerRadius: CGFloat = 4,
                linearProgressDefaultHeight: CGFloat = 4,
                linearProgressRegularHeight: CGFloat = 12,
                linearHorizontalMargin: CGFloat = 12,
                linearVerticalMargin: CGFloat = 4,
                valueLabelWidth: CGFloat = 40,
                valueLabelHeight: CGFloat = 20,
                circleProgressWidth: CGFloat = 48,
                circleProgressLineWidth: CGFloat = 2,
                circularHorizontalMargin: CGFloat = 8,
                circularverticalMargin: CGFloat = 4) {
        self.linearSmallCornerRadius = linearSmallCornerRadius
        self.linearBigCornerRadius = linearBigCornerRadius
        self.linearProgressDefaultHeight = linearProgressDefaultHeight
        self.linearProgressRegularHeight = linearProgressRegularHeight
        self.linearHorizontalMargin = linearHorizontalMargin
        self.linearVerticalMargin = linearVerticalMargin
        self.valueLabelWidth = valueLabelWidth
        self.valueLabelHeight = valueLabelHeight
        self.circleProgressWidth = circleProgressWidth
        self.circleProgressLineWidth = circleProgressLineWidth
        self.circularHorizontalMargin = circularHorizontalMargin
        self.circularverticalMargin = circularverticalMargin
    }
}
