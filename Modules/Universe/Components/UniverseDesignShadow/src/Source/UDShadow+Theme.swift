//
//  UDShadow+Theme.swift
//  UniverseDesignShadow
//
//  Created by Siegfried on 2021/9/10.
//

import UIKit
import Foundation
import UniverseDesignColor


public extension UDColor.Name {
    static let s1DownColor = UDColor.Name("shadow-s1-down-color")
    static let s2DownColor = UDColor.Name("shadow-s2-down-color")
    static let s3DownColor = UDColor.Name("shadow-s3-down-color")
    static let s4DownColor = UDColor.Name("shadow-s4-down-color")
    static let s5DownColor = UDColor.Name("shadow-s5-down-color")

    static let s1DownPriColor = UDColor.Name("shadow-s1-down-pri-color")
    static let s2DownPriColor = UDColor.Name("shadow-s2-down-pri-color")
    static let s3DownPriColor = UDColor.Name("shadow-s3-down-pri-color")
    static let s4DownPriColor = UDColor.Name("shadow-s4-down-pri-color")
    static let s5DownPriColor = UDColor.Name("shadow-s5-down-pri-color")

    static let s1UpColor = UDColor.Name("shadow-s1-up-color")
    static let s2UpColor = UDColor.Name("shadow-s2-up-color")
    static let s3UpColor = UDColor.Name("shadow-s3-up-color")
    static let s4UpColor = UDColor.Name("shadow-s4-up-color")
    static let s5UpColor = UDColor.Name("shadow-s5-up-color")

    static let s1LeftColor = UDColor.Name("shadow-s1-left-color")
    static let s2LeftColor = UDColor.Name("shadow-s2-left-color")
    static let s3LeftColor = UDColor.Name("shadow-s3-left-color")
    static let s4LeftColor = UDColor.Name("shadow-s4-left-color")
    static let s5LeftColor = UDColor.Name("shadow-s5-left-color")

    static let s1RightColor = UDColor.Name("shadow-s1-right-color")
    static let s2RightColor = UDColor.Name("shadow-s2-right-color")
    static let s3RightColor = UDColor.Name("shadow-s3-right-color")
    static let s4RightColor = UDColor.Name("shadow-s4-right-color")
    static let s5RightColor = UDColor.Name("shadow-s5-right-color")
}

/// 组件预设阴影颜色
public struct UDShadowColorTheme {
    // MARK: 阴影朝下
    /// 1级强度阴影 朝下
    public static var s1DownColor: UIColor {
        return UDColor.getValueByKey(.s1DownColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 2级强度阴影 朝下
    public static var s2DownColor: UIColor {
        return UDColor.getValueByKey(.s2DownColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 3级强度阴影 朝下
    public static var s3DownColor: UIColor {
        return UDColor.getValueByKey(.s3DownColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 4级强度阴影 朝下
    public static var s4DownColor: UIColor {
        return UDColor.getValueByKey(.s4DownColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 5级强度阴影 朝下
    public static var s5DownColor: UIColor {
        return UDColor.getValueByKey(.s5DownColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    // MARK: 阴影朝上
    /// 1级强度阴影 朝下
    public static var s1UpColor: UIColor {
        return UDColor.getValueByKey(.s1UpColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 2级强度阴影 朝下
    public static var s2UpColor: UIColor {
        return UDColor.getValueByKey(.s2UpColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 3级强度阴影 朝下
    public static var s3UpColor: UIColor {
        return UDColor.getValueByKey(.s3UpColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 4级强度阴影 朝下
    public static var s4UpColor: UIColor {
        return UDColor.getValueByKey(.s4UpColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 5级强度阴影 朝下
    public static var s5UpColor: UIColor {
        return UDColor.getValueByKey(.s5UpColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }

    // MARK: 阴影朝左
    /// 1级强度阴影 朝下
    public static var s1LeftColor: UIColor {
        return UDColor.getValueByKey(.s1LeftColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 2级强度阴影 朝下
    public static var s2LeftColor: UIColor {
        return UDColor.getValueByKey(.s2LeftColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 3级强度阴影 朝下
    public static var s3LeftColor: UIColor {
        return UDColor.getValueByKey(.s3LeftColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 4级强度阴影 朝下
    public static var s4LeftColor: UIColor {
        return UDColor.getValueByKey(.s4LeftColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 5级强度阴影 朝下
    public static var s5LeftColor: UIColor {
        return UDColor.getValueByKey(.s5LeftColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }

    // MARK: 阴影朝右
    /// 1级强度阴影 朝下
    public static var s1RightColor: UIColor {
        return UDColor.getValueByKey(.s1RightColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 2级强度阴影 朝下
    public static var s2RightColor: UIColor {
        return UDColor.getValueByKey(.s2RightColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 3级强度阴影 朝下
    public static var s3RightColor: UIColor {
        return UDColor.getValueByKey(.s3RightColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 4级强度阴影 朝下
    public static var s4RightColor: UIColor {
        return UDColor.getValueByKey(.s4RightColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }
    /// 5级强度阴影 朝下
    public static var s5RightColor: UIColor {
        return UDColor.getValueByKey(.s5RightColor) ?? UIColor.ud.rgb("#1F2329") & UIColor.ud.rgb("#000000")
    }

    // MARK: 阴影朝下 主题色
    /// 1级强度阴影 朝下 主题色
    public static var s1DownPriColor: UIColor {
        return UDColor.getValueByKey(.s1DownPriColor) ?? UIColor.ud.rgb("#245BDB") & UIColor.ud.rgb("#245BDB")
    }
    /// 2级强度阴影 朝下 主题色
    public static var s2DownPriColor: UIColor {
        return UDColor.getValueByKey(.s2DownPriColor) ?? UIColor.ud.rgb("#245BDB") & UIColor.ud.rgb("#245BDB")
    }
    /// 3级强度阴影 朝下 主题色
    public static var s3DownPriColor: UIColor {
        return UDColor.getValueByKey(.s3DownPriColor) ?? UIColor.ud.rgb("#245BDB") & UIColor.ud.rgb("#245BDB")
    }
    /// 4级强度阴影 朝下 主题色
    public static var s4DownPriColor: UIColor {
        return UDColor.getValueByKey(.s4DownPriColor) ?? UIColor.ud.rgb("#245BDB") & UIColor.ud.rgb("#245BDB")
    }
    /// 5级强度阴影 朝下 主题色
    public static var s5DownPriColor: UIColor {
        return UDColor.getValueByKey(.s5DownPriColor) ?? UIColor.ud.rgb("#245BDB") & UIColor.ud.rgb("#245BDB")
    }
}
