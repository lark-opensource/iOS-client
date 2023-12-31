//
//  UDColor+Deprecated.swift
//  UniverseDesignColor
//
//  Created by 姚启灏 on 2021/7/2.
//

import UIKit
import Foundation
import UniverseDesignTheme

/// UDColor Name Extension
public extension UDColor.Name {
    /// textDisable, Value: "text-disable"
    static let textDisable = UDColor.Name("text-disable")

    /// textLinkDisable, Value: "text-link-disable"
    static let textLinkDisable = UDColor.Name("text-link-disable")

    /// fillSelect, Value: "fill-select"
    static let fillSelect = UDColor.Name("fill-select")

    /// fillDisable, Value: "fill-disable"
    static let fillDisable = UDColor.Name("fill-disable")

    /// iconDisable, Value: "icon-disable"
    static let iconDisable = UDColor.Name("icon-disable")

    /// udtokenTagNeutralBgNormalPress, Value: "udtoken-tag-neutral-bg-normal-press"
    static let udtokenTagNeutralBgNormalPress = UDColor.Name("udtoken-tag-neutral-bg-normal-press")

    /// udtokenTableBgPress, Value: "udtoken-table-bg-press"
    static let udtokenTableBgPress = UDColor.Name("udtoken-table-bg-press")
}

/// UDColor Token
extension UDColor {
    @available(*, deprecated, renamed:"textDisabled")
    public static var textDisable: UIColor {
        return UDColor.getValueByKey(.textDisable) ?? UDColor.N400
    }

    @available(*, deprecated, renamed:"textLinkDisabled")
    public static var textLinkDisable: UIColor {
        return UDColor.getValueByKey(.textLinkDisable) ?? UDColor.N400
    }

    @available(*, deprecated, renamed:"fillSelected")
    public static var fillSelect: UIColor {
        return UDColor.getValueByKey(.fillSelect) ?? UDColor.primaryContentDefault.withAlphaComponent(0.08) & UDColor.primaryContentPressed.withAlphaComponent(0.15)
    }

    @available(*, deprecated, renamed:"fillSelected")
    public static var fillDisable: UIColor {
        return UDColor.getValueByKey(.fillDisabled) ?? UDColor.N400
    }

    @available(*, deprecated, renamed:"iconDisabled")
    public static var iconDisable: UIColor {
        return UDColor.getValueByKey(.iconDisabled) ?? UDColor.N400
    }

    @available(*, deprecated, renamed:"iconDisabled")
    public static var udtokenTagNeutralBgNormalPress: UIColor {
        return UDColor.getValueByKey(.udtokenTagNeutralBgNormalPressed) ?? UDColor.N900.withAlphaComponent(0.2) & UDColor.N900.withAlphaComponent(0.4)
    }

    @available(*, deprecated, renamed: "udtokenTableBgPressed")
    public static var udtokenTableBgPress: UIColor {
        return UDColor.getValueByKey(.udtokenTableBgPressed) ?? UDColor.N300 & UDColor.N400
    }
}

/// UDColor Name Extension
extension UDComponentsExtension where BaseType == UIColor {
    @available(*, deprecated, renamed: "textDisabled")
    public static var textDisable: UIColor { return UDColor.textDisable }

    @available(*, deprecated, renamed: "textLinkDisabled")
    public static var textLinkDisable: UIColor { return UDColor.textLinkDisable }

    @available(*, deprecated, renamed: "fillSelect")
    public static var fillSelect: UIColor { return UDColor.fillSelect }

    @available(*, deprecated, renamed: "fillDisabled")
    public static var fillDisable: UIColor { return UDColor.fillDisable }

    @available(*, deprecated, renamed: "udtokenTagNeutralBgNormalPressed")
    public static var udtokenTagNeutralBgNormalPress: UIColor { return UDColor.udtokenTagNeutralBgNormalPress }

    @available(*, deprecated, renamed: "udtokenTableBgPressed")
    public static var udtokenTableBgPress: UIColor { return UDColor.udtokenTableBgPressed }

    @available(*, deprecated, renamed: "iconDisabled")
    public static var iconDisable: UIColor { return UDColor.iconDisable }
}
