//
//  StyleHelpers.swift
//  LarkOpenPlatform
//
//  Created by lilun.ios on 2021/6/15.
//

import Foundation
import UniverseDesignColor

struct StyleHelpers {
    /// 从style dictionary中解析颜色配置
    static func parseColor(colorKey: String, style: [String: String]) -> UIColor? {
        if let tokenColorKey = style[(colorKey + "Token")],
           let tokenColor = UDColor.getValueByKey(UDColor.Name(tokenColorKey)) {
            return tokenColor
        }
        if let lightColorKey = style[colorKey] {
            if let darkColorKey = style[(colorKey + "DarkMode")] {
                return UIColor.ud.css(lightColorKey) & UIColor.ud.css(darkColorKey)
            }
            return UIColor.ud.css(lightColorKey)
        }
        return nil
    }
}
