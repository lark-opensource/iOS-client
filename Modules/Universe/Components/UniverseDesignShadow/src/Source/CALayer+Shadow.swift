//
//  CALayer+Shadow.swift
//  FigmaKit
//
//  Created by Hayden Wang on 2021/8/2.
//

import Foundation
import UIKit
import UniverseDesignTheme

// swiftlint:disable all
public extension UDComponentsExtension where BaseType == CALayer {
    /// 通过 UDShadowType 设置当前控件阴影
    ///
    /// Example:
    /// ```
    /// someView.layer.ud.setShadow(type: .s1Down)
    /// someView.layer.ud.setShadow(type: .s1Down, shouldRasterize: false )
    /// ```
    ///
    /// shouldRasterize:
    /// 光栅化会影响部分filter的显示效果，如果不合预期，可设置光栅化为false
    ///
    /// - Parameters:
    ///   - type: 阴影的强度及朝向
    ///   - shouldRasterize: 是否开启光栅化
    public func setShadow(type: UDShadowType, shouldRasterize: Bool = true) {
        base.udSetShadow(color: type.color,
                         alpha: type.alpha,
                         x: type.x,
                         y: type.y,
                         blur: type.blur,
                         spread: type.spread,
                         udShouldRasterize: shouldRasterize)
    }
}


fileprivate extension CALayer {
    /// 扩展的CALayer设置阴影方法
    ///
    /// - Parameters:
    ///   - color: 阴影颜色
    ///   - alpha: 阴影透明度
    ///   - x: 阴影横向偏移
    ///   - y: 阴影纵向偏移
    ///   - blur: 阴影模糊半径
    ///   - spread: 阴影扩散半径
    ///   - udShouldRasterize: 阴影是否光栅化
    ///   - path: 阴影投影路径
    func udSetShadow(color: UIColor = .black,
                     alpha: Float = 0.5,
                     x: CGFloat = 0,
                     y: CGFloat = 2,
                     blur: CGFloat = 4,
                     spread: CGFloat = 0,
                     udShouldRasterize: Bool,
                     path: UIBezierPath? = nil) {

        ud.setShadowColor(color, bindTo: rootView)
        shadowOpacity = alpha
        shadowRadius = blur / 2
        if let path = path {
            if spread == 0 {
                shadowOffset = CGSize(width: x, height: y)
            } else {
                let scaleX = (path.bounds.width + (spread * 2)) / path.bounds.width
                let scaleY = (path.bounds.height + (spread * 2)) / path.bounds.height

                path.apply(CGAffineTransform(translationX: x + -spread, y: y + -spread).scaledBy(x: scaleX, y: scaleY))
                shadowPath = path.cgPath
            }
        } else {
            shadowOffset = CGSize(width: x, height: y)
            if spread == 0 {
                shadowPath = nil
            } else {
                let dx = -spread
                let rect = bounds.insetBy(dx: dx, dy: dx)
                shadowPath = UIBezierPath(rect: rect).cgPath
            }
        }
        shouldRasterize = udShouldRasterize
        rasterizationScale = UIScreen.main.scale
    }

    /// 当前Layer所依附的根View
    var rootView: UIView? {
        var currentLayer: CALayer? = self
        while currentLayer?.delegate == nil, currentLayer?.superlayer != nil {
            currentLayer = currentLayer?.superlayer
        }
        return currentLayer?.delegate as? UIView
    }
}
// swiftlint:enable all
