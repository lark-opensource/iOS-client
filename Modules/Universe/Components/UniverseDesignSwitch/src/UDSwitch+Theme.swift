//
//  UDSwitch+Theme.swift
//  UniverseDesignSwitch
//
//  Created by CJ on 2020/11/19.
//

import UIKit
import Foundation
import UniverseDesignColor

// swiftlint:disable all
/// UDColor Name Extension
public extension UDColor.Name {
    static let switchOnThumbColor = UDColor.Name("switch-on-thumb-color")
    static let switchOnTrackColor = UDColor.Name("switch-on-track-color")
    static let switchOnDisabledThumbColor = UDColor.Name("switch-on-disabled-thumb-color")
    static let switchOnDisabledTrackColor = UDColor.Name("switch-on-disabled-track-color")
    static let switchOnLoadingThumbColor = UDColor.Name("switch-on-loading-thumb-color")
    static let switchOnLoadingTrackColor = UDColor.Name("switch-on-loading-track-color")
    static let switchOnLoadingIconColor = UDColor.Name("switch-on-loading-icon-color")
    static let switchOffThumbColor = UDColor.Name("switch-off-thumb-color")
    static let switchOffTrackColor = UDColor.Name("switch-off-track-color")
    static let switchOffDisabledThumbColor = UDColor.Name("switch-off-disabled-thumb-color")
    static let switchOffDisabledTrackColor = UDColor.Name("switch-off-disabled-track-color")
    static let switchOffLoadingThumbColor = UDColor.Name("switch-off-loading-thumb-color")
    static let switchOffLoadingTrackColor = UDColor.Name("switch-off-loading-track-color")
    static let switchOffLoadingIconColor = UDColor.Name("switch-off-loading-icon-color")
}

/// Switch Color Theme
public struct UDSwitchColorTheme {
    /// Switch thumb normal background  olor when is on,  Default color: UDColor.primaryOnPrimaryFill
    public static var switchOnThumbColor: UIColor {
        return UDColor.getValueByKey(.switchOnThumbColor) ?? UDColor.primaryOnPrimaryFill
    }
    /// Switch track normal background color when is on,  Default color: UDColor.primaryContentDefault
    public static var switchOnTrackColor: UIColor {
        return UDColor.getValueByKey(.switchOnTrackColor) ?? UDColor.primaryFillDefault
    }
    /// Switch thumb disabled background color when is on,  Default color: UDColor.udtokenSlidingBlockBgDisabledLoading
    public static var switchOnDisabledThumbColor: UIColor {
        return UDColor.getValueByKey(.switchOnDisabledThumbColor) ?? UDColor.udtokenSlidingBlockBgDisabledLoading
    }
    /// Switch track disabled background color when is on,  Default color: UDColor.primaryFillSolid03
    public static var switchOnDisabledTrackColor: UIColor {
        return UDColor.getValueByKey(.switchOnDisabledTrackColor) ?? UDColor.primaryFillSolid03
    }
    /// Switch thumb loading background color when is on,  Default color: UDColor.udtokenSlidingBlockBgDisabledLoading
    public static var switchOnLoadingThumbColor: UIColor {
        return UDColor.getValueByKey(.switchOnLoadingThumbColor) ?? UDColor.udtokenSlidingBlockBgDisabledLoading
    }
    /// Switch track loading background color when is on,  Default color: UDColor.primaryFillSolid03
    public static var switchOnLoadingTrackColor: UIColor {
        return UDColor.getValueByKey(.switchOnLoadingTrackColor) ?? UDColor.primaryFillSolid03
    }
    /// Switch icon loading background color when is on,  Default color: UDColor.primaryFillSolid03
    public static var switchOnLoadingIconColor: UIColor {
        return UDColor.getValueByKey(.switchOnLoadingIconColor) ?? UDColor.primaryFillSolid03
    }
    /// Switch thumb normal background  olor when is off,  Default color: UDColor.primaryOnPrimaryFill
    public static var switchOffThumbColor: UIColor {
        return UDColor.getValueByKey(.switchOffThumbColor) ?? UDColor.primaryOnPrimaryFill
    }
    /// Switch track normal background  olor when is off,  Default color: UDColor.lineBorderComponent
    public static var switchOffTrackColor: UIColor {
        return UDColor.getValueByKey(.switchOffTrackColor) ?? UDColor.lineBorderComponent
    }
    /// Switch thumb disabled background  olor when is off,  Default color: UDColor.udtokenSlidingBlockBgDisabledLoading
    public static var switchOffDisabledThumbColor: UIColor {
        return UDColor.getValueByKey(.switchOffDisabledThumbColor) ?? UDColor.udtokenSlidingBlockBgDisabledLoading
    }
    /// Switch track disabled background  olor when is off,  Default color: UDColor.lineBorderCard
    public static var switchOffDisabledTrackColor: UIColor {
        return UDColor.getValueByKey(.switchOffDisabledTrackColor) ?? UDColor.lineBorderCard
    }
    /// Switch thumb loading background  olor when is off,  Default color: UDColor.udtokenSlidingBlockBgDisabledLoading
    public static var switchOffLoadingThumbColor: UIColor {
        return UDColor.getValueByKey(.switchOffLoadingThumbColor) ?? UDColor.udtokenSlidingBlockBgDisabledLoading
    }
    /// Switch track loading background  olor when is off,  Default color: UDColor.lineBorderCard
    public static var switchOffLoadingTrackColor: UIColor {
        return UDColor.getValueByKey(.switchOffLoadingTrackColor) ?? UDColor.lineBorderCard
    }
    /// Switch icon loading background  olor when is off,  Default color: UDColor.lineBorderCard
    public static var switchOffLoadingIconColor: UIColor {
        return UDColor.getValueByKey(.switchOffLoadingIconColor) ?? UDColor.lineBorderCard
    }
}
// swiftlint:enable all
