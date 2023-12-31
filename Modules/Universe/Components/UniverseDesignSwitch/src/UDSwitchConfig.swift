//
//  UDSwitchConfig.swift
//  UniverseDesignSwitch
//
//  Created by CJ on 2020/11/6.
//

import UIKit
import Foundation

/// UDSwitch UI Config
public struct UDSwitchUIConfig {
    /// UDSwicthTheme Color
    /// Contains tintColor, thumbColor, loadingColor
    public struct ThemeColor {
        let tintColor: UIColor
        let thumbColor: UIColor
        let loadingColor: UIColor
        /// ThemeColor init
        /// - Parameters:
        ///   - tintColor: tint Color
        ///   - thumbColor: thumb Color
        ///   - loadingColor: loading Color
        public init(tintColor: UIColor,
                    thumbColor: UIColor = UDSwitchColorTheme.switchOnThumbColor,
                    loadingColor: UIColor = UDSwitchColorTheme.switchOffLoadingIconColor) {
            self.tintColor = tintColor
            self.thumbColor = thumbColor
            self.loadingColor = loadingColor
        }
        /// default normal theme when switch is on
        public static var defaultOnNormalTheme: ThemeColor {
            return ThemeColor(tintColor: UDSwitchColorTheme.switchOnTrackColor,
                              thumbColor: UDSwitchColorTheme.switchOnThumbColor,
                              loadingColor: UDSwitchColorTheme.switchOnThumbColor)
        }
        /// default disable theme when switch is on
        public static var defaultOnDisableTheme: ThemeColor {
            return ThemeColor(tintColor: UDSwitchColorTheme.switchOnDisabledTrackColor,
                              thumbColor: UDSwitchColorTheme.switchOnDisabledThumbColor,
                              loadingColor: UDSwitchColorTheme.switchOnDisabledThumbColor)
        }
        /// default loading theme when switch is on
        public static var defaultonOnLoadingTheme: ThemeColor {
            return ThemeColor(tintColor: UDSwitchColorTheme.switchOnLoadingTrackColor,
                              thumbColor: UDSwitchColorTheme.switchOnLoadingThumbColor,
                              loadingColor: UDSwitchColorTheme.switchOnLoadingIconColor)
        }
        /// default normal theme when switch is off
        public static var defaultOffNormalTheme: ThemeColor {
            return ThemeColor(tintColor: UDSwitchColorTheme.switchOffTrackColor,
                              thumbColor: UDSwitchColorTheme.switchOffThumbColor,
                              loadingColor: UDSwitchColorTheme.switchOffThumbColor)
        }
        /// default disable theme when switch is off
        public static var defaultonOffDisableTheme: ThemeColor {
            return ThemeColor(tintColor: UDSwitchColorTheme.switchOffDisabledTrackColor,
                              thumbColor: UDSwitchColorTheme.switchOffDisabledThumbColor,
                              loadingColor: UDSwitchColorTheme.switchOffDisabledThumbColor)
        }
        /// default loading theme when switch is off
        public static var defaultonOffLoadingTheme: ThemeColor {
            return ThemeColor(tintColor: UDSwitchColorTheme.switchOffLoadingTrackColor,
                              thumbColor: UDSwitchColorTheme.switchOffLoadingThumbColor,
                              loadingColor: UDSwitchColorTheme.switchOffLoadingIconColor)
        }
    }
    /// UDSwitchUIConfig init
    /// - Parameters:
    ///   - onNormalTheme: switch normal theme color when is on
    ///   - onDisableTheme: switch disable theme color when is on
    ///   - onLoadingTheme: switch loading theme color when is on
    ///   - offNormalTheme: switch normal theme color when is off
    ///   - offDisableTheme: switch disable theme color when is off
    ///   - offLoadingTheme: switch loading theme color when is off
    public init(onNormalTheme: ThemeColor,
                onDisableTheme: ThemeColor? = nil,
                onLoadingTheme: ThemeColor? = nil,
                offNormalTheme: ThemeColor? = nil,
                offDisableTheme: ThemeColor? = nil,
                offLoadingTheme: ThemeColor? = nil) {
        self.onNormalTheme = onNormalTheme
        if let onDisableTheme = onDisableTheme {
            self.onDisableTheme = onDisableTheme
        } else {
            self.onDisableTheme = ThemeColor(tintColor: onNormalTheme.tintColor.withAlphaComponent(0.5),
                                             thumbColor: onNormalTheme.thumbColor,
                                             loadingColor: onNormalTheme.loadingColor.withAlphaComponent(0.5))
        }
        if let onLoadingTheme = onLoadingTheme {
            self.onLoadingTheme = onLoadingTheme
        } else {
            self.onLoadingTheme = ThemeColor(tintColor: onNormalTheme.tintColor.withAlphaComponent(0.5),
                                             thumbColor: onNormalTheme.thumbColor,
                                             loadingColor: onNormalTheme.tintColor.withAlphaComponent(0.5))
        }
        self.offNormalTheme = offNormalTheme ?? ThemeColor.defaultOffNormalTheme
        self.offDisableTheme = offDisableTheme ?? ThemeColor.defaultonOffDisableTheme
        self.offLoadingTheme = offLoadingTheme ?? ThemeColor.defaultonOffLoadingTheme
    }
    /// Switch normal theme color when is on
    public var onNormalTheme: ThemeColor
    /// Switch disable theme color when is on
    public var onDisableTheme: ThemeColor
    /// Switch loading theme color when is on
    public var onLoadingTheme: ThemeColor
    /// Switch normal theme color when is off
    public var offNormalTheme: ThemeColor
    /// Switch disable theme color when is off
    public var offDisableTheme: ThemeColor
    /// Switch loading theme color when is off
    public var offLoadingTheme: ThemeColor
    /// Default switch ui config
    public static var defaultConfig: UDSwitchUIConfig {
        return UDSwitchUIConfig(onNormalTheme: ThemeColor.defaultOnNormalTheme,
                                onDisableTheme: ThemeColor.defaultOnDisableTheme,
                                onLoadingTheme: ThemeColor.defaultonOnLoadingTheme,
                                offNormalTheme: ThemeColor.defaultOffNormalTheme,
                                offDisableTheme: ThemeColor.defaultonOffDisableTheme,
                                offLoadingTheme: ThemeColor.defaultonOffLoadingTheme)
    }
}
