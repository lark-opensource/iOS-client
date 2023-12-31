//
//  Style.swift
//  TangramComponent
//
//  Created by 袁平 on 2021/3/23.
//

import TangramLayoutKit
import UniverseDesignTheme

// MARK: - Style Protocol

// RenderComponent & LayoutComponent Style
public protocol Style {
    var width: TCValue { get set }
    var height: TCValue { get set }
    var maxWidth: TCValue { get set }
    var maxHeight: TCValue { get set }
    var minWidth: TCValue { get set }
    var minHeight: TCValue { get set }
    var growWeight: Int { get set }
    var shrinkWeight: Int { get set }
    var aspectRatio: CGFloat { get set }
    var display: Display { get set } // TODO: 处理displayNone的逻辑，不参与布局计算
    var alignSelf: Align { get set }

    func clone() -> Self
    func equalTo(_ old: Style) -> Bool
}

extension Style {
    public func sync(to node: TLNodeRef) {
        TLNodeSetStyleWidth(node, self.width.tlValue)
        TLNodeSetStyleHeight(node, self.height.tlValue)
        TLNodeSetStyleMaxWidth(node, self.maxWidth.tlValue)
        TLNodeSetStyleMaxHeight(node, self.maxHeight.tlValue)
        TLNodeSetStyleMinWidth(node, self.minWidth.tlValue)
        TLNodeSetStyleMinHeight(node, self.minHeight.tlValue)
        TLNodeSetStyleGrowWeight(node, Int32(self.growWeight))
        TLNodeSetStyleShrinkWeight(node, Int32(self.shrinkWeight))
        TLNodeSetStyleAspectRatio(node, Float(self.aspectRatio))
        TLNodeSetStyleDisplay(node, display.value)
        TLNodeSetStyleAlignSelf(node, alignSelf.value)
    }
}

// MARK: - Layout

public struct LayoutComponentStyle: Style {
    public var width: TCValue = .undefined
    public var height: TCValue = .undefined
    public var maxWidth: TCValue = .undefined
    public var maxHeight: TCValue = .undefined
    public var minWidth: TCValue = .undefined
    public var minHeight: TCValue = .undefined
    public var growWeight: Int = 0
    public var shrinkWeight: Int = 0
    public var aspectRatio: CGFloat = 0
    public var display: Display = .display
    public var alignSelf: Align = .undefined

    public init() {}

    public func clone() -> LayoutComponentStyle {
        return self
    }

    public func equalTo(_ old: Style) -> Bool {
        guard let old = old as? LayoutComponentStyle else { return false }
        return width == old.width &&
            height == old.height &&
            maxWidth == old.maxWidth &&
            maxHeight == old.maxHeight &&
            minWidth == old.minWidth &&
            minHeight == old.minHeight &&
            growWeight == old.growWeight &&
            shrinkWeight == old.shrinkWeight &&
            aspectRatio == old.aspectRatio &&
            display == old.display &&
            alignSelf == old.alignSelf
    }
}

// MARK: - Render

// 减少业务方实现RenderComponentProps equalTo的成本，提取一些公共UI属性
final public class RenderComponentStyle: Style {
    public var width: TCValue = .undefined
    public var height: TCValue = .undefined
    public var maxWidth: TCValue = .undefined
    public var maxHeight: TCValue = .undefined
    public var minWidth: TCValue = .undefined
    public var minHeight: TCValue = .undefined
    public var growWeight: Int = 0
    public var shrinkWeight: Int = 0
    public var aspectRatio: CGFloat = 0
    public var display: Display = .display
    public var alignSelf: Align = .undefined

    public var backgroundColor: UIColor? = UIColor.clear
    public var borderWidth: CGFloat = 0
    public var borderColor: UIColor?
    public var cornerRadius: CGFloat = 0
    public var alpha: CGFloat = 1
    public var isHidden: Bool = false // TODO: isHidden参与剪枝
    public var clipsToBounds: Bool = false
    public var gradientStyle: GradientStyle?

    public init() {}

    public func clone() -> RenderComponentStyle {
        let clone = RenderComponentStyle()
        clone.width = width
        clone.height = height
        clone.maxWidth = maxWidth
        clone.maxHeight = maxHeight
        clone.minWidth = minWidth
        clone.minHeight = minHeight
        clone.growWeight = growWeight
        clone.shrinkWeight = shrinkWeight
        clone.aspectRatio = aspectRatio
        clone.display = display
        clone.alignSelf = alignSelf

        clone.backgroundColor = backgroundColor?.copy() as? UIColor
        clone.borderWidth = borderWidth
        clone.borderColor = borderColor?.copy() as? UIColor
        clone.cornerRadius = cornerRadius
        clone.alpha = alpha
        clone.isHidden = isHidden
        clone.clipsToBounds = clipsToBounds
        clone.gradientStyle = gradientStyle?.clone()
        return clone
    }

    public func equalTo(_ old: Style) -> Bool {
        guard let old = old as? RenderComponentStyle else { return false }
        var gradientStyleEqual = false
        if var new = gradientStyle, let old = old.gradientStyle {
            gradientStyleEqual = new.equalTo(old)
        } else if gradientStyle == nil, old.gradientStyle == nil {
            gradientStyleEqual = true
        }
        return backgroundColor == old.backgroundColor &&
            width == old.width &&
            height == old.height &&
            maxWidth == old.maxWidth &&
            maxHeight == old.maxHeight &&
            minWidth == old.minWidth &&
            minHeight == old.minHeight &&
            growWeight == old.growWeight &&
            shrinkWeight == old.shrinkWeight &&
            aspectRatio == old.aspectRatio &&
            display == old.display &&
            alignSelf == old.alignSelf &&
            borderWidth == old.borderWidth &&
            borderColor == old.borderColor &&
            cornerRadius == old.cornerRadius &&
            alpha == old.alpha &&
            isHidden == old.isHidden &&
            clipsToBounds == old.clipsToBounds &&
            gradientStyleEqual
    }

    public func applyToView(_ view: UIView) {
        assert(Thread.isMainThread, "must be on main thread")

        view.backgroundColor = backgroundColor
        view.layer.borderWidth = borderWidth
        if let borderColor = borderColor {
            view.layer.ud.setBorderColor(borderColor)
        } else {
            view.layer.borderColor = nil
        }
        view.layer.cornerRadius = cornerRadius
        view.alpha = alpha
        view.isHidden = isHidden
        view.clipsToBounds = clipsToBounds
        gradientStyle?.applyToView(view)
    }
}

public protocol RenderStyle {
    mutating func applyToView(_ view: UIView)
    mutating func clone() -> Self
    mutating func equalTo(_ old: Self) -> Bool
}

private let _gradientLayerKey = "TangramComponent_gradientLayerKey"
public struct GradientStyle: RenderStyle {
    public var colors: [UIColor] = []
    public var startPoint: CGPoint = .init(x: 0.5, y: 0.0)
    public var endPoint: CGPoint = .init(x: 0.5, y: 1.0)
    public var locations: [NSNumber]? = nil
    public var type: CAGradientLayerType = .axial
    public var maskedCorners: CACornerMask? = nil
    public var masksToBounds: Bool = false

    public init() {}

    /// @return: CAGradientLayer - create by GradientStyle
    public mutating func getGradientLayer(_ view: UIView) -> CAGradientLayer? {
        let layer = view.layer.sublayers?.first(where: { $0.name == _gradientLayerKey })
        return layer as? CAGradientLayer
    }

    /// @return:
    ///     - true: if view has a GradientLayer created by GradientStyle and remove success
    ///     - false: if view has no GradientLayer created by GradientStyle
    @discardableResult
    public mutating func removeGradientLayer(_ view: UIView) -> Bool {
        if let layer = getGradientLayer(view) {
            layer.removeFromSuperlayer()
            return true
        }
        return false
    }

    public mutating func applyToView(_ view: UIView) {
        removeGradientLayer(view)
        let gradient = CAGradientLayer()
        // 调用ud.setColors时，darkmode需要取到layer所在view，因此需要提前insertSublayer
        // 否则ud.setColors不生效
        view.layer.insertSublayer(gradient, at: 0)
        gradient.name = _gradientLayerKey
        gradient.ud.setColors(colors)
        gradient.startPoint = startPoint
        gradient.endPoint = endPoint
        gradient.locations = locations
        gradient.type = type
        if let maskedCorners = maskedCorners {
            gradient.maskedCorners = maskedCorners
        }
        gradient.masksToBounds = masksToBounds
        gradient.frame = view.bounds
    }

    public mutating func clone() -> GradientStyle {
        var copy = GradientStyle()
        copy.colors = colors.map { $0.copy() as? UIColor ?? $0 }
        copy.startPoint = startPoint
        copy.endPoint = endPoint
        copy.locations = locations?.map { $0.copy() as? NSNumber ?? $0 }
        copy.type = type
        copy.maskedCorners = maskedCorners
        copy.masksToBounds = masksToBounds
        return copy
    }

    public mutating func equalTo(_ old: GradientStyle) -> Bool {
        return colors == old.colors &&
            startPoint == old.startPoint &&
            endPoint == old.endPoint &&
            locations == old.locations &&
            type == old.type &&
            maskedCorners == old.maskedCorners &&
            masksToBounds == old.masksToBounds
    }
}
