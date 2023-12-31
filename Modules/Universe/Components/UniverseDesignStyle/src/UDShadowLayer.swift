//
//  UDShadowLayer.swift
//  Pods-UniverseDesignStyleDev
//
//  Created by 强淑婷 on 2020/8/11.
//

import Foundation
import UIKit
import UniverseDesignColor

extension UIView {
    /// 阴影方向
    public enum ShadowType {
        /// 上
        case up
        /// 下
        case down
        /// 左
        case left
        /// 右
        case right
        /// 全部
        case all
    }

    /// Shadow-S 小投影, 主要应用于导航栏、菜单栏、工具栏、标题、悬浮按钮、模态层的模态抽屉等。
    public func smallShadow(_ type: ShadowType = .all) {
        addShadow(color: UIColor.ud.N900, opacity: 0.12, radius: 4, type: type, offset: 2)
    }

    /// Shadow-M 中投影, 主要应用于模态层的导航抽屉、操作栏等。
    public func middleShadow(_ type: ShadowType = .all) {
        addShadow(color: UIColor.ud.N900, opacity: 0.10, radius: 8, type: type, offset: 4)
    }

    /// Shadow-L 大投影, 主要应用于模态层的浮层、全局提示等。
    public func largeShadow(_ type: ShadowType = .all) {
        addShadow(color: UIColor.ud.N900, opacity: 0.08, radius: 24, type: type, offset: 6)
    }

    /// Shadow-M-blue 中投影-blue,- Toast- 悬浮按钮
    public func middleShadowBlue() {
        addShadow(color: UIColor.ud.N600, opacity: 0.08, radius: 8, type: .down, offset: 4)
    }

    /// 根据颜色，透明度，模糊，方向设置阴影
    /// - Parameters:
    ///   - color: 颜色
    ///   - opacity: 透明度
    ///   - radius: 模糊
    ///   - type: 类型ShadowType
    ///   - offset: 方向
    private func addShadow(color: UIColor, opacity: Float, radius: CGFloat, type: ShadowType, offset: CGFloat) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius

        switch type {
        case .up:
            layer.shadowOffset = CGSize(width: 0, height: -offset)
        case .down:
            layer.shadowOffset = CGSize(width: 0, height: offset)
        case .left:
            layer.shadowOffset = CGSize(width: -offset, height: 0)
        case .right:
            layer.shadowOffset = CGSize(width: offset, height: 0)
        case .all:
            layer.shadowOffset = CGSize(width: 0, height: 0)
        }
    }
}
