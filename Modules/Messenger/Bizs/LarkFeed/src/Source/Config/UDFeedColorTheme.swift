//
//  UDFeedColorTheme.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/4/28.
//

import UIKit
import Foundation
import UniverseDesignColor

public extension UDColor.Name {
    static let imFeedBgBody = UDColor.Name("imtoken-feed-bg-body")
    static let imFeedTextPriSelected = UDColor.Name("imtoken-feed-text-pri-selected")
    static let imFeedIconPriSelected = UDColor.Name("imtoken-feed-icon-pri-selected")
    static let imFeedFeedFillActive = UDColor.Name("imtoken-feed-fill-active")
}

/// UDMenu Color Theme
public struct UDMessageColorTheme {
    public static var imFeedBgBody: UIColor {
        return UDColor.getValueByKey(.imFeedBgBody) ?? UDColor.N00 & UDColor.N500
    }
    public static var imFeedTextPriSelected: UIColor {
        return UDColor.getValueByKey(.imFeedTextPriSelected) ?? UDColor.B600 & UDColor.N1000
    }
    public static var imFeedIconPriSelected: UIColor {
        return UDColor.getValueByKey(.imFeedIconPriSelected) ?? UDColor.B600 & UDColor.N1000
    }
    public static var imFeedFeedFillActive: UIColor {
        return UDColor.getValueByKey(.imFeedFeedFillActive) ?? UIColor.ud.rgb(0x3385FF).withAlphaComponent(0.12) & UIColor.ud.fillActive
    }
}

public struct UDMessageBizColor: UDBizColor {
    public func getValueByToken(_ token: String) -> UIColor? {
        let tokenName = UDColor.Name(token)
        switch tokenName {
        case .imFeedBgBody: return UDMessageColorTheme.imFeedBgBody
        case .imFeedTextPriSelected: return UDMessageColorTheme.imFeedTextPriSelected
        case .imFeedIconPriSelected: return UDMessageColorTheme.imFeedIconPriSelected
        case .imFeedFeedFillActive: return UDMessageColorTheme.imFeedFeedFillActive
        default: return nil
        }
    }
}
