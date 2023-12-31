//
//  UDColor+Token.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/4/20.
//

import UniverseDesignColor
import UIKit

/// 业务线 Color token
extension UDColor {
    /// 我的常用-管理员推荐 标签背景色
    static var opTokenAppTagBg: UIColor {
        return UDColor.O100 & UDColor.O900
    }

    /// 我的常用-管理员推荐 文字色
    static var opTokenAppTagText: UIColor {
        return UDColor.O400 & UDColor.O500
    }

    /// 我的常用-Bot 标签背景色
    static var opTokenAppTagbotBg: UIColor {
        return UDColor.Y100 & UDColor.Y900
    }

    /// 我的常用-Bot 文字色
    static var opTokenAppTagbotText: UIColor {
        return UDColor.Y400 & UDColor.Y300
    }
}
