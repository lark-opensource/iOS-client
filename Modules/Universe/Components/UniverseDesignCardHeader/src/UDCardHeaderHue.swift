//
//  UDCardHeaderHue.swift
//  UniverseDesignCardHeader
//
//  Created by Siegfried on 2021/8/26.
//

import Foundation
import UIKit

/// 消息卡片颜色
///
/// UDCardHeaderHue中包含了背景颜色、文字颜色和蒙版图片颜色，预设了13种组合供业务方使用
///
/// - parameters:
///   - color: 卡片背景颜色
///   - textColor: 文字颜色
///   - maskColor: 背景上椭圆蒙版颜色
public struct UDCardHeaderHue {
    /// 创建自定义的颜色主题
    public init(color: UIColor,textColor: UIColor = UDCardHeaderColorScheme.udtokenMessageCardTextBlue,maskColor: UIColor = UDCardHeaderColorScheme.udtokenMessageCardBgMaskGeneral) {
        self.color = color
        self.textColor = textColor
        self.maskColor = maskColor
    }

    /// 消息卡片背景颜色
    public var color: UIColor
    /// 消息卡片文字颜色
    public var textColor: UIColor
    /// 消息卡片椭圆蒙版颜色
    public var maskColor: UIColor = UDCardHeaderColorScheme.udtokenMessageCardBgMaskGeneral


    /// 蓝色
    public static var blue = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgBlue,
                                             textColor: UDCardHeaderColorScheme.udtokenMessageCardTextBlue)
    /// 浅蓝色
    public static var wathet = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgWathet,
                                               textColor: UDCardHeaderColorScheme.udtokenMessageCardTextWathet)
    /// 绿松石
    public static var turquoise = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgTurquoise,
                                                  textColor: UDCardHeaderColorScheme.udtokenMessageCardTextTurquoise)
    /// 绿色
    public static var green = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgGreen,
                                              textColor: UDCardHeaderColorScheme.udtokenMessageCardTextGreen)
    /// 青柠绿
    public static var lime = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgLime,
                                             textColor: UDCardHeaderColorScheme.udtokenMessageCardTextLime)
    /// 黄色
    public static var yellow = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgYellow,
                                               textColor: UDCardHeaderColorScheme.udtokenMessageCardTextYellow)
    /// 橘色
    public static var orange = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgOrange,
                                               textColor: UDCardHeaderColorScheme.udtokenMessageCardTextOrange)
    /// 红色
    public static var red = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgRed,
                                            textColor: UDCardHeaderColorScheme.udtokenMessageCardTextRed)
    /// 胭脂红
    public static var carmine = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgCarmine,
                                                textColor: UDCardHeaderColorScheme.udtokenMessageCardTextCarmine)
    /// 紫罗兰
    public static var violet = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgViolet,
                                               textColor: UDCardHeaderColorScheme.udtokenMessageCardTextViolet)
    /// 紫色
    public static var purple = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgPurple,
                                               textColor: UDCardHeaderColorScheme.udtokenMessageCardTextPurple)
    /// 靛蓝色
    public static var indigo = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgIndigo,
                                               textColor: UDCardHeaderColorScheme.udtokenMessageCardTextIndigo)
    /// 灰色
    public static var neural = UDCardHeaderHue(color: UDCardHeaderColorScheme.udtokenMessageCardBgNeural,
                                               textColor: UDCardHeaderColorScheme.udtokenMessageCardTextDeepNeural,
                                               maskColor: UDCardHeaderColorScheme.udtokenMessageCardBgMaskSpecial)
}



