//
//  UDShadowType.swift
//  UniverseDesignShadow
//
//  Created by Siegfried on 2021/9/10.
//

import UIKit
import UniverseDesignColor

/// UDShadowType
///
/// 组件阴影类型，预设为五种强度，四种方向
///
/// - Parameters:
///   - x: 阴影横向偏移
///   - y: 阴影纵向偏移
///   - blur: 阴影模糊半径
///   - spread: 阴影扩散半径
///   - color: 阴影颜色
///   - alpha: 阴影透明度
public struct UDShadowType {
    /// 阴影横向偏移
    public var x: CGFloat
    /// 阴影纵向偏移
    public var y: CGFloat
    /// 阴影模糊半径
    public var blur: CGFloat
    /// 阴影扩散半径
    public var spread: CGFloat
    /// 阴影颜色
    public var color: UIColor
    /// 阴影透明度
    public var alpha: Float

    /// 自定义阴影
    public init(x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat, color: UIColor, alpha: Float) {
        self.x = x
        self.y = y
        self.blur = blur
        self.spread = spread
        self.color = color
        self.alpha = alpha
    }

    /// 强度1级，方向朝上
    public static var s1Up: UDShadowType = UDShadowType(x: 0, y: -2, blur: 4, spread: 0, color: UDShadowColorTheme.s1UpColor, alpha: 0.06)
    /// 2级强度，方向朝上
    public static var s2Up: UDShadowType = UDShadowType(x: 0, y: -2, blur: 6, spread: 0, color: UDShadowColorTheme.s2UpColor, alpha: 0.08)
    /// 3级强度，方向朝上
    public static var s3Up: UDShadowType = UDShadowType(x: 0, y: -4, blur: 8, spread: 0, color: UDShadowColorTheme.s3UpColor, alpha: 0.09)
    /// 4级强度，方向朝上
    public static var s4Up: UDShadowType = UDShadowType(x: 0, y: -6, blur: 16, spread: 0, color: UDShadowColorTheme.s4UpColor, alpha: 0.1)
    /// 5级强度，方向朝上
    public static var s5Up: UDShadowType = UDShadowType(x: 0, y: -8, blur: 36, spread: 0, color: UDShadowColorTheme.s5UpColor, alpha: 0.1)

    /// 强度1级，方向朝下
    public static var s1Down: UDShadowType = UDShadowType(x: 0, y: 2, blur: 4, spread: 0, color: UDShadowColorTheme.s1DownColor, alpha: 0.06)
    /// 2级强度，方向朝下
    public static var s2Down: UDShadowType = UDShadowType(x: 0, y: 2, blur: 6, spread: 0, color: UDShadowColorTheme.s2DownColor, alpha: 0.08)
    /// 3级强度，方向朝下
    public static var s3Down: UDShadowType = UDShadowType(x: 0, y: 4, blur: 8, spread: 0, color: UDShadowColorTheme.s3DownColor, alpha: 0.09)
    /// 4级强度，方向朝下
    public static var s4Down: UDShadowType = UDShadowType(x: 0, y: 6, blur: 16, spread: 0, color: UDShadowColorTheme.s4DownColor, alpha: 0.1)
    /// 5级强度，方向朝下
    public static var s5Down: UDShadowType = UDShadowType(x: 0, y: 8, blur: 36, spread: 0, color: UDShadowColorTheme.s5DownColor, alpha: 0.1)

    /// 1级强度，方向朝下，蓝色
    public static var s1DownPri: UDShadowType = UDShadowType(x: 0, y: 2, blur: 4, spread: 0, color: UDShadowColorTheme.s1DownPriColor, alpha: 0.12)
    /// 2级强度，方向朝下，蓝色
    public static var s2DownPri: UDShadowType = UDShadowType(x: 0, y: 2, blur: 6, spread: 0, color: UDShadowColorTheme.s2DownPriColor, alpha: 0.16)
    /// 3级强度，方向朝下，蓝色
    public static var s3DownPri: UDShadowType = UDShadowType(x: 0, y: 4, blur: 8, spread: 0, color: UDShadowColorTheme.s3DownPriColor, alpha: 0.18)
    /// 4级强度，方向朝下，蓝色
    public static var s4DownPri: UDShadowType = UDShadowType(x: 0, y: 6, blur: 16, spread: 0, color: UDShadowColorTheme.s4DownPriColor, alpha: 0.2)
    /// 5级强度，方向朝下，蓝色
    public static var s5DownPri: UDShadowType = UDShadowType(x: 0, y: 8, blur: 36, spread: 0, color: UDShadowColorTheme.s5DownPriColor, alpha: 0.24)

    /// 1级强度，方向朝左
    public static var s1Left: UDShadowType = UDShadowType(x: -2, y: 0, blur: 4, spread: 0, color: UDShadowColorTheme.s1LeftColor, alpha: 0.06)
    /// 2级强度，方向朝左
    public static var s2Left: UDShadowType = UDShadowType(x: -2, y: 0, blur: 6, spread: 0, color: UDShadowColorTheme.s2LeftColor, alpha: 0.08)
    /// 3级强度，方向朝左
    public static var s3Left: UDShadowType = UDShadowType(x: -4, y: 0, blur: 8, spread: 0, color: UDShadowColorTheme.s3LeftColor, alpha: 0.09)
    /// 4级强度，方向朝左
    public static var s4Left: UDShadowType = UDShadowType(x: -6, y: 0, blur: 16, spread: 0, color: UDShadowColorTheme.s4LeftColor, alpha: 0.1)
    /// 5级强度，方向朝左
    public static var s5Left: UDShadowType = UDShadowType(x: -8, y: 0, blur: 36, spread: 0, color: UDShadowColorTheme.s5LeftColor, alpha: 0.1)

    /// 1级强度，方向朝右
    public static var s1Right: UDShadowType = UDShadowType(x: 2, y: 0, blur: 4, spread: 0, color: UDShadowColorTheme.s1RightColor, alpha: 0.06)
    /// 2级强度，方向朝右
    public static var s2Right: UDShadowType = UDShadowType(x: 2, y: 0, blur: 6, spread: 0, color: UDShadowColorTheme.s2RightColor, alpha: 0.08)
    /// 3级强度，方向朝右
    public static var s3Right: UDShadowType = UDShadowType(x: 4, y: 0, blur: 8, spread: 0, color: UDShadowColorTheme.s3RightColor, alpha: 0.09)
    /// 4级强度，方向朝右
    public static var s4Right: UDShadowType = UDShadowType(x: 6, y: 0, blur: 16, spread: 0, color: UDShadowColorTheme.s4RightColor, alpha: 0.1)
    /// 5级强度，方向朝右
    public static var s5Right: UDShadowType = UDShadowType(x: 8, y: 0, blur: 36, spread: 0, color: UDShadowColorTheme.s5RightColor, alpha: 0.1)
}
