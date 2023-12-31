//
//  Style.swift
//  LarkTag
//
//  Created by kongkaikai on 2019/6/16.
//

import UIKit
import Foundation
import UniverseDesignColor

/// Tag 样式： 文本颜色、 背景颜色
public struct Style {

    /// 文本颜色
    public private(set) var textColor: UIColor

    /// Tag 背景颜色
    public private(set) var backColor: UIColor

    /// 初始化方法
    ///
    /// - Parameters:
    ///   - textColor: 文本颜色
    ///   - backColor: Tag背景色
    public init(textColor: UIColor, backColor: UIColor) {
        self.textColor = textColor
        self.backColor = backColor
    }

    /// textColor: UIColor.clear, backColor: UIColor.clear
    public static let clear = Style(textColor: UIColor.clear, backColor: UIColor.clear)

    /// textColor: udtokenTagTextSBlue, backColor: udtokenTagBgBlue
    public static let blue = Style(textColor: UIColor.ud.udtokenTagTextSBlue, backColor: UIColor.ud.udtokenTagBgBlue)

    /// textColor: udtokenTagTextSPurple, backColor: udtokenTagBgPurple
    public static let purple = Style(textColor: UIColor.ud.udtokenTagTextSPurple,
                                     backColor: UIColor.ud.udtokenTagBgPurple)

    /// textColor: udtokenTagTextSRed, backColor: udtokenTagBgRed
    public static let orange = Style(textColor: UIColor.ud.udtokenTagTextSOrange, backColor: UIColor.ud.udtokenTagBgOrange)

    /// textColor: udtokenTagTextSRed, backColor: udtokenTagBgRed
    public static let red = Style(textColor: UIColor.ud.udtokenTagTextSRed, backColor: UIColor.ud.udtokenTagBgRed)

    /// textColor: udtokenTagTextSYellow, backColor: udtokenTagBgYellow
    public static let yellow = Style(textColor: UIColor.ud.udtokenTagTextSYellow,
                                     backColor: UIColor.ud.udtokenTagBgYellow)

    /// textColor: udtokenTagNeutralTextInverse, backColor: udtokenTagNeutralBgInverse
    public static let darkGrey = Style(textColor: UIColor.ud.udtokenTagNeutralTextInverse,
                                       backColor: UIColor.ud.udtokenTagNeutralBgInverse)

    /// textColor: udtokenTagNeutralTextNormal, backColor: udtokenTagNeutralBgNormal
    public static let lightGrey = Style(textColor: UIColor.ud.udtokenTagNeutralTextNormal,
                                        backColor: UIColor.ud.udtokenTagNeutralBgNormal)

    /// textColor: primaryOnPrimaryFill, backColor: UIColor.ud.primaryOnPrimaryFill * 0.2
    public static let white = Style(textColor: UIColor.ud.primaryOnPrimaryFill, backColor: UIColor.ud.primaryOnPrimaryFill * 0.2)

    /// textColor: udtokenTagTextSTurquoise, backColor: udtokenTagBgTurquoise
    public static let turquoise = Style(textColor: UIColor.ud.udtokenTagTextSTurquoise,
                                        backColor: UIColor.ud.udtokenTagBgTurquoise)

    /// textColor: UIColor.ud.N700, backColor: UIColor.white
    public static let secretColor = Style(textColor: UIColor.ud.N700.nonDynamic, backColor: UIColor.white)

    /// textColor: udtokenTagTextSGreen, backColor: udtokenTagBgGreen
    public static let readColor = Style(textColor: UIColor.ud.udtokenTagTextSGreen,
                                        backColor: UIColor.ud.udtokenTagBgGreen)

    /// textColor: udtokenTagNeutralTextNormal, backColor: udtokenTagNeutralBgNormal
    public static let unreadColor = Style(textColor: UIColor.ud.udtokenTagNeutralTextNormal,
                                          backColor: UIColor.ud.udtokenTagNeutralBgNormal)

    /// textColor: udtokenTagTextPurple, backColor: udtokenTagBgPurple
    public static let adminColor = Style(textColor: UIColor.ud.udtokenTagTextSPurple,
                                         backColor: UIColor.ud.udtokenTagBgPurple)

    public static let indigo = Style(textColor: UIColor.ud.udtokenTagTextIndigo,
                                         backColor: UIColor.ud.udtokenTagBgIndigo)

}

fileprivate extension UIColor {
    @inline(__always)
    static func * (lhs: UIColor, rhs: CGFloat) -> UIColor {
        lhs.withAlphaComponent(rhs)
    }
}
