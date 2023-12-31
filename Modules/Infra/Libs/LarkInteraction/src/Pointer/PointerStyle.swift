//
//  PointerStyle.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/12/2.
//

import Foundation
import UIKit

@available(iOS 13.4, *)
public struct PointerTargetProvider {

    public static var `default`: PointerTargetProvider {
        return .init { (interaction, region) -> UITargetedPreview? in
            guard let view = interaction.view,
                  view.window != nil else {
                return nil
            }
            let parameters = UIPreviewParameters()
            return UITargetedPreview(view: view, parameters: parameters)
        }
    }

    public static func targetView(_ block: @escaping (UIView) -> UIView?) -> PointerTargetProvider {
        return  .init { (interaction, _) -> UITargetedPreview? in
            guard let view = interaction.view,
                  view.window != nil else {
                return nil
            }
            if let targetView = block(view) {
                let viewCenter = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
                let targetCenter = view.convert(viewCenter, to: targetView)
                let target = UIPreviewTarget(container: targetView, center: targetCenter)
                let parameters = UIPreviewParameters()
                return UITargetedPreview(view: view, parameters: parameters, target: target)
            } else {
                let parameters = UIPreviewParameters()
                return UITargetedPreview(view: view, parameters: parameters)
            }
        }
    }

    public static func targetView(_ block: @escaping (UIView) -> UIView) -> PointerTargetProvider {
        return .init { (interaction, region) -> UITargetedPreview? in
            guard let view = interaction.view,
                  view.window != nil else {
                return nil
            }
            let targetView = block(view)
            let viewCenter = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 2)
            let targetCenter = view.convert(viewCenter, to: targetView)
            let target = UIPreviewTarget(container: targetView, center: targetCenter)
            let parameters = UIPreviewParameters()

            return UITargetedPreview(
                view: view,
                parameters: parameters,
                target: target
            )
        }
    }

    public var handler: (UIPointerInteraction, UIPointerRegion) -> UITargetedPreview?

    public init(handler: @escaping (UIPointerInteraction, UIPointerRegion) -> UITargetedPreview?) {
        self.handler = handler
    }
}

@available(iOS 13.4, *)
public struct PointerEffect {
    public static var automatic: PointerEffect {
        return .init { (_, _, targetView) -> UIPointerEffect? in
            return .automatic(targetView)
        }
    }

    public static var lift: PointerEffect {
        return .init { (_, _, targetView) -> UIPointerEffect? in
            return .lift(targetView)
        }
    }

    public static var highlight: PointerEffect {
        return .init { (_, _, targetView) -> UIPointerEffect? in
            return .highlight(targetView)
        }
    }

    public static func hover(
        preferredTintMode: UIPointerEffect.TintMode = .overlay,
        prefersShadow: Bool = false,
        prefersScaledContent: Bool = true
    ) -> PointerEffect {
        return .init { (_, _, targetView) -> UIPointerEffect? in
            return .hover(
                targetView,
                preferredTintMode: preferredTintMode,
                prefersShadow: prefersShadow,
                prefersScaledContent: prefersScaledContent
            )
        }
    }

    public var handler: (UIPointerInteraction, UIPointerRegion, UITargetedPreview) -> UIPointerEffect?

    public init(handler: @escaping (UIPointerInteraction, UIPointerRegion, UITargetedPreview) -> UIPointerEffect?) {
        self.handler = handler
    }
}

@available(iOS 13.4, *)
public struct PointerShape {

    public static var `default`: PointerShape {
        return .init { (_, _, _) -> UIPointerShape? in
            return nil
        }
    }

    public static func roundedFrame(
        _ rectAndRadius: @escaping (UIPointerInteraction, UIPointerRegion) -> PointerInfo.ShapeRectInfo
    ) -> PointerShape {
        return .init { (interation, region, _) -> UIPointerShape? in
            let info = rectAndRadius(interation, region)
            return UIPointerShape.roundedRect(info.0, radius: info.1)
        }
    }

    public static func roundedBounds(
        _ rectAndRadius: @escaping (UIPointerInteraction, UIPointerRegion
    ) -> PointerInfo.ShapeRectInfo) -> PointerShape {
        return .init { (interation, region, targetPreview) -> UIPointerShape? in
            let info = rectAndRadius(interation, region)
            guard let view = interation.view else { return nil }
            let frame = view.convert(info.0, to: targetPreview?.target.container ?? view.superview)
            return UIPointerShape.roundedRect(frame, radius: info.1)
        }
    }

    public static func roundedSize(
        _ sizeAndRadius: @escaping (UIPointerInteraction, UIPointerRegion
    ) -> PointerInfo.ShapeSizeInfo) -> PointerShape {
        return .init { (interation, region, targetPreview) -> UIPointerShape? in
            let info = sizeAndRadius(interation, region)
            guard let view = interation.view else { return nil }
            let viewSize = view.bounds.size
            let shapeSize = info.0
            let rect = CGRect(
                origin: CGPoint(
                    x: (viewSize.width - shapeSize.width) / 2,
                    y: (viewSize.height - shapeSize.height) / 2),
                size: shapeSize
            )
            let frame = view.convert(rect, to: targetPreview?.target.container ?? view.superview)
            return UIPointerShape.roundedRect(frame, radius: info.1)
        }
    }

    public static func path(path: @escaping (UIPointerInteraction, UIPointerRegion) -> UIBezierPath) -> PointerShape {
        return .init { (interation, region, _) -> UIPointerShape? in
            return UIPointerShape.path(path(interation, region))
        }
    }

    public var handler: (UIPointerInteraction, UIPointerRegion, UITargetedPreview?) -> UIPointerShape?

    public init(handler: @escaping (UIPointerInteraction, UIPointerRegion, UITargetedPreview?) -> UIPointerShape?) {
        self.handler = handler
    }
}

@available(iOS 13.4, *)
public struct PointerAxis {

    public static var `default`: PointerAxis {
        return .init { (_, _) -> UIAxis? in
            return nil
        }
    }

    public var handler: (UIPointerInteraction, UIPointerRegion) -> UIAxis?

    public init(handler: @escaping (UIPointerInteraction, UIPointerRegion) -> UIAxis?) {
        self.handler = handler
    }
}

@available(iOS 15, *)
public struct PointerAccessories {

    public static var `default`: PointerAccessories {
        return .init { (_, _) -> [UIPointerAccessory] in
            return []
        }
    }

    public var handler: (UIPointerInteraction, UIPointerRegion) -> [UIPointerAccessory]

    public init(handler: @escaping (UIPointerInteraction, UIPointerRegion) -> [UIPointerAccessory]) {
        self.handler = handler
    }
}

/// 对 UIPointerStyle 的封装
@available(iOS 13.4, *)
public struct PointerStyle {
    public var effect: PointerEffect
    public var shape: PointerShape
    public var targetProvider: PointerTargetProvider
    public var axis: PointerAxis

    @available(iOS 15, *)
    public var accessories: PointerAccessories {
        get { _accessories as? PointerAccessories ?? .default }
        set { _accessories = newValue }
    }
    private var _accessories: Any?

    private enum InitMode {
        case effect
        case axis
        case hidden
        case system
    }
    private var initMode: InitMode

    public init(
        effect: PointerEffect,
        shape: PointerShape = .default,
        targetProvider: PointerTargetProvider = .default
    ) {
        self.effect = effect
        self.shape = shape
        self.targetProvider = targetProvider
        self.axis = .default
        self.initMode = .effect
    }

    public init(
        shape: PointerShape,
        axis: PointerAxis
    ) {
        self.effect = .automatic
        self.shape = shape
        self.targetProvider = .default
        self.axis = axis
        self.initMode = .axis
    }

    public static func hidden() -> Self {
        var style = PointerStyle(effect: .automatic)
        style.initMode = .hidden
        return style
    }

    @available(iOS 15, *)
    public static func system() -> Self {
        var style = PointerStyle(effect: .automatic)
        style.initMode = .system
        return style
    }

    @available(*, deprecated, message: "不能同时使用 effect 和 axis 初始化 PointerStyle")
    public init(
        effect: PointerEffect,
        shape: PointerShape = .default,
        targetProvider: PointerTargetProvider = .default,
        axis: PointerAxis = .default
    ) {
        self.effect = effect
        self.shape = shape
        self.targetProvider = targetProvider
        self.axis = axis
        self.initMode = .effect // 因为之前的代码逻辑，导致这个方法初始化的必然为 effect，之后将该方法删除
    }

    func style(
        interaction: UIPointerInteraction,
        styleFor region: UIPointerRegion
    ) -> UIPointerStyle? {
        var style: UIPointerStyle?
        switch initMode {
        case .effect:
            if let targetView = targetProvider.handler(interaction, region),
                     let effect = effect.handler(interaction, region, targetView) {
                let shape = self.shape.handler(interaction, region, targetView)
                style = UIPointerStyle(effect: effect, shape: shape)
           }
        case .axis:
            if let axis = self.axis.handler(interaction, region),
               let shape = self.shape.handler(interaction, region, nil) {
                style = UIPointerStyle(shape: shape, constrainedAxes: axis)
            }
        case .hidden:
            style = .hidden()
        case .system:
            if #available(iOS 15, *) {
                style = .system()
            }
        }
        if #available(iOS 15.0, *) {
            style?.accessories = accessories.handler(interaction, region)
        }
        return style
    }

    var buttonProvider: UIButton.PointerStyleProvider {
        return { (button, effect, default) -> UIPointerStyle? in
            guard let pointer = button.interactions.first(where: { (interaction) -> Bool in
                return interaction is UIPointerInteraction
            }) as? UIPointerInteraction else {
                return nil
            }
            return style(interaction: pointer, styleFor: UIPointerRegion(rect: button.bounds))
        }
    }
}
