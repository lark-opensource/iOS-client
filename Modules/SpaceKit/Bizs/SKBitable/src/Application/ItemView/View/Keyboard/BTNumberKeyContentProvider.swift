//
//  BTNumberKeyContentProvider.swift
//  SKBitable
//
//  Created by 曾浩泓 on 2022/4/14.
//  

import UIKit
import SKResource
import Foundation
import UniverseDesignColor
import UniverseDesignIcon

protocol BTNumberKeyContentProvider {
    func needShadowColor(_ key: BTNumberKeyboardKeyType) -> Bool
    func normalBgColor(_ key: BTNumberKeyboardKeyType) -> UIColor
    func highlightBgColor(_ key: BTNumberKeyboardKeyType) -> UIColor
    func title(_ key: BTNumberKeyboardKeyType) -> String?
    func titleColor(_ key: BTNumberKeyboardKeyType, enable: Bool) -> UIColor?
    func icon(_ key: BTNumberKeyboardKeyType, enable: Bool) -> UIImage?
    func iconColor(_ key: BTNumberKeyboardKeyType, enable: Bool) -> UIColor?
}
final class BTNumberKeyContentProviderImpl: BTNumberKeyContentProvider {
    
    func needShadowColor(_ key: BTNumberKeyboardKeyType) -> Bool {
        if case .function(.done) = key {
            return false
        }
        return true
    }
    func normalBgColor(_ key: BTNumberKeyboardKeyType) -> UIColor {
        let defaultColor = UDColor.bgBody
        switch key {
        case .function(let funcType):
            if case .delete = funcType {
                return UDColor.bgBase
            } else if case .done = funcType {
                return UDColor.bgPricolor
            }
            return defaultColor
        case .digital(_):
            return defaultColor
        }
    }
    func highlightBgColor(_ key: BTNumberKeyboardKeyType) -> UIColor {
        if case .function(.done) = key {
            return UDColor.textLinkPressed
        }
        return UDColor.fillPressed.withAlphaComponent(0.12)
    }
    func title(_ key: BTNumberKeyboardKeyType) -> String? {
        if case .digital(let num) = key {
            return "\(num)"
        } else if case .function(.point) = key {
            return "."
        }
        return nil
    }
    func titleColor(_ key: BTNumberKeyboardKeyType, enable: Bool) -> UIColor? {
        return enable ? UDColor.textTitle : UDColor.iconDisabled
    }
    func icon(_ key: BTNumberKeyboardKeyType, enable: Bool) -> UIImage? {
        guard case .function(let funcType) = key else {
            return nil
        }
        var img: UIImage?
        switch funcType {
        case .sign:
            img = UDIcon.sheetSignOutlined
        case .delete:
            img = UDIcon.deleteOutlined
        case .done:
            img = UDIcon.listCheckBoldOutlined
        case .point:
            break
        }
        if let color = iconColor(key, enable: enable) {
            img = img?.ud.withTintColor(color)
        }
        return img
    }
    func iconColor(_ key: BTNumberKeyboardKeyType, enable: Bool) -> UIColor? {
        guard case .function(let funcType) = key else {
            return nil
        }
        if !enable {
            return UDColor.iconDisabled
        }
        switch funcType {
        case .sign, .delete:
            return UDColor.textTitle
        case .done:
            return UDColor.primaryOnPrimaryFill
        case .point:
            return nil
        }
    }
}
