//
//  PointerInfo.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/12/14.
//

import Foundation
import UIKit

/// 指针效果信息
public final class PointerInfo {
    /// 指针效果种类
    public enum Effect {
        /// 自动效果
        case automatic
        /// 提起效果
        case lift
        /// 高亮效果
        case highlight
        /// 悬停效果，参数可以省略
        case hover(tintMode: HoverTintMode = .overlay,
                   shadow: Bool = false,
                   scaledContent: Bool = true)

        /// UIPointerEffect.TintMode 映射
        public enum HoverTintMode {
            /// 没有悬停效果
            case none
            /// 悬停效果在 View 上层
            case overlay
            /// 悬停效果在 View 下层
            case underlay
        }
    }

    /// 指针大小，圆角
    public typealias ShapeSizeInfo = (CGSize, CGFloat)

    /// 指针大小，圆角
    public typealias ShapeRectInfo = (CGRect, CGFloat)

    /// 高亮效果边距，正向内，负向外
    public struct PointerInsets {
        public static let zero = PointerInsets()

        public var horizontalInsets: CGFloat
        public var verticalInsets: CGFloat

        /// - Parameter edges: 四边边距
        public init(edges: CGFloat = 0) {
            horizontalInsets = edges
            verticalInsets = edges
        }

        /// - Parameters:
        ///   - horizontal: 水平边距
        ///   - vertical: 垂直边距
        public init(horizontal: CGFloat, vertical: CGFloat) {
            horizontalInsets = horizontal
            verticalInsets = vertical
        }
    }

    /// 指针效果种类
    public var effect: PointerInfo.Effect
    /// 指针形状
    public var shape: (_ origin: CGSize) -> PointerInfo.ShapeSizeInfo
    /// Preview 的容器 View
    /// - Note: 参数为 Pointer 所在 View，返回值是期望的容器 View
    public var targetView: ((UIView) -> UIView?)?

    private var _accessories: Any?

    /// 指针周围的附件（如箭头），最多支持 4 个
    @available(iOS 15, *)
    public var accessories: PointerAccessories {
        get { _accessories as? PointerAccessories ?? .default }
        set { _accessories = newValue }
    }

    /// 指针效果
    /// - Parameters:
    ///   - effect: 指针效果类型
    ///   - insets: （高亮）指针效果边距
    ///   - cornerRadius: （高亮）指针效果圆角
    ///   - targetView: Preview 的容器 View
    @available(*, deprecated, message: "请直接使用 .automatic / .lift / .highlight / .hover 来初始化")
    public convenience init(effect: PointerInfo.Effect = .highlight,
                            insets: PointerInsets = .zero,
                            cornerRadius: CGFloat = .zero,
                            targetView: ((UIView) -> UIView)? = nil
    ) {
        let shape: (CGSize) -> PointerInfo.ShapeSizeInfo = { originSize in
            let size = CGSize(width: originSize.width - insets.horizontalInsets * 2,
                              height: originSize.height - insets.verticalInsets * 2)
            return (size, cornerRadius)
        }
        self.init(effect: effect, shape: shape, targetView: targetView)
    }

    /// 指针效果
    /// - Parameters:
    ///   - effect: 指针效果类型
    ///   - shape: 指针效果形状
    ///   - targetView: Preview 的容器 View
    @available(*, deprecated, message: "请直接使用 .automatic / .lift / .highlight / .hover 来初始化")
    public init(
        effect: PointerInfo.Effect,
        shape: @escaping (_ origin: CGSize) -> PointerInfo.ShapeSizeInfo,
        targetView: ((UIView) -> UIView)? = nil
    ) {
        self.effect = effect
        self.shape = shape
        self.targetView = targetView
    }

    @available(iOS 13.4, *)
    public var style: PointerStyle {
        let effectInfo: PointerEffect
        switch effect {
        case .automatic:
            effectInfo = PointerEffect.automatic
        case .highlight:
            effectInfo = PointerEffect.highlight
        case .lift:
            effectInfo = PointerEffect.lift
        case .hover(tintMode: let tintMode,
                    shadow: let shadow,
                    scaledContent: let scaledContent):
            let uiTintMode: UIPointerEffect.TintMode
            switch tintMode {
            case .none:
                uiTintMode = .none
            case .overlay:
                uiTintMode = .overlay
            case .underlay:
                uiTintMode = .underlay
            }
            effectInfo = PointerEffect.hover(preferredTintMode: uiTintMode,
                                             prefersShadow: shadow,
                                             prefersScaledContent: scaledContent)
        }

        let shape = self.shape
        let shapeInfo: PointerShape
        if case .highlight = effect {
            shapeInfo = PointerShape.roundedSize { (interaction, _) -> PointerInfo.ShapeSizeInfo in
                guard let view = interaction.view else {
                    return (.zero, 0)
                }
                return shape(view.bounds.size)
            }
        } else {
            shapeInfo = .default
        }

        let targetProvider: PointerTargetProvider
        if let targetView = targetView {
            targetProvider = .targetView(targetView)
        } else {
            targetProvider = .default
        }

        var style = PointerStyle(
            effect: effectInfo,
            shape: shapeInfo,
            targetProvider: targetProvider
        )
        if #available(iOS 15, *) {
            style.accessories = accessories
        }
        return style
    }
}

/// 公共接口（语法糖接口）
public extension PointerInfo {
    /// 自动效果
    static let automatic = PointerInfo(effect: .automatic)
    /// 提起效果
    static let lift = PointerInfo(effect: .lift)
    /// 高亮效果
    static let highlight = PointerInfo(effect: .highlight)
    /// 悬停效果
    static let hover = PointerInfo(effect: .hover())

    /// 高亮效果
    /// - Parameters:
    ///   - insets: 指针效果边距
    ///   - cornerRadius: 指针效果圆角
    static func highlight(insets: PointerInsets = .zero,
                          cornerRadius: CGFloat = .zero) -> PointerInfo {
        return PointerInfo(effect: .highlight, insets: insets, cornerRadius: cornerRadius)
    }

    /// 高亮效果
    /// - Parameters:
    ///   - shape: 指针效果形状
    static func highlight(shape: @escaping (_ origin: CGSize) -> PointerInfo.ShapeSizeInfo) -> PointerInfo {
        return PointerInfo(effect: .highlight, shape: shape)
    }

    /// 悬停效果
    /// - Parameters:
    ///   - tintMode: Hover 的效果叠加层次
    ///   - shadow: Hover 是否需要加上默认的阴影
    ///   - scaledContent: Hover 时，内容是否要缩放
    static func hover(tintMode: Effect.HoverTintMode = .overlay,
                      shadow: Bool = false,
                      scaledContent: Bool = true) -> PointerInfo {
        return PointerInfo(effect: .hover(tintMode: tintMode,
                                          shadow: shadow,
                                          scaledContent: scaledContent))
    }

    /// 修改 TargetView（Preview 的容器 View，参数为 Pointer 所在 View，返回值是期望的容器 View）
    /// - Parameter targetView: Preview 的容器 View，参数为 Pointer 所在 View，返回值是期望的容器 View
    func targetView(_ targetView: @escaping ((UIView) -> UIView?)) -> Self {
        self.targetView = targetView
        return self
    }
}
