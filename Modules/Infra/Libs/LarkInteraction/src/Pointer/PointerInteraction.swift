//
//  PointerInteraction.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/12/2.
//

import Foundation
import UIKit
import LKCommonsLogging

@available(iOS 13.4, *)
public final class PointerInteraction: NSObject, Interaction {

    static var logger = Logger.log(PointerInteraction.self, category: "Lark.Interaction")

    /// 动画相关配置
    public private(set) var animating: PointerAnimating = PointerAnimating()

    /// 是否进行响应, 以及响应区域
    public var handler: (
        UIPointerInteraction, UIPointerRegionRequest, UIPointerRegion
    ) -> UIPointerRegion? = { (_, _, region) -> UIPointerRegion? in
        return region
    }

    /// Poniter 样式
    public var style: PointerStyle

    public var uiInteraction: UIInteraction {
        return self.pointerInteraction
    }

    public var platforms: [UIUserInterfaceIdiom] {
        return [.pad]
    }

    public private(set) lazy var pointerInteraction: UIPointerInteraction = {
        let interaction = UIPointerInteraction(delegate: self)
        return interaction
    }()

    public init(style: PointerStyle) {
        self.style = style
        super.init()
    }

    public var isEnabled: Bool {
        set { pointerInteraction.isEnabled = newValue }
        get { return pointerInteraction.isEnabled }
    }
}

@available(iOS 13.4, *)
extension PointerInteraction: UIPointerInteractionDelegate {
    public func pointerInteraction(
        _ interaction: UIPointerInteraction,
        regionFor request: UIPointerRegionRequest,
        defaultRegion: UIPointerRegion
    ) -> UIPointerRegion? {
        #if DEBUG
        PointerInteraction.logger.debug("interactionRequest")
        #endif
        return handler(interaction, request, defaultRegion)
    }

    public func pointerInteraction(
        _ interaction: UIPointerInteraction,
        styleFor region: UIPointerRegion
    ) -> UIPointerStyle? {
        let pointerStyle = style.style(interaction: interaction, styleFor: region)
        var style = ""
        #if DEBUG
        style = String(describing: pointerStyle?.value(forKey: "effect"))
        #endif
        PointerInteraction.logger.debug("interactionStyle \(style)")
        return pointerStyle
    }

    public func pointerInteraction(
        _ interaction: UIPointerInteraction,
        willEnter region: UIPointerRegion,
        animator: UIPointerInteractionAnimating
    ) {
        PointerInteraction.logger.debug("willEnter")
        animator.addAnimations { [weak self] in
            self?.animating.willEnterAnimations.forEach({ (animation) in
                animation(interaction, region)
            })
        }
        animator.addCompletion { [weak self] (result) in
            self?.animating.willEnterCompletions.forEach({ (completion) in
                completion(interaction, region, result)
            })
        }
    }

    public func pointerInteraction(
        _ interaction: UIPointerInteraction,
        willExit region: UIPointerRegion,
        animator: UIPointerInteractionAnimating
    ) {
        PointerInteraction.logger.debug("willExit")
        animator.addAnimations { [weak self] in
            self?.animating.willExitAnimations.forEach({ (animation) in
                animation(interaction, region)
            })
        }
        animator.addCompletion { [weak self] (result) in
            self?.animating.willExitCompletions.forEach({ (completion) in
                completion(interaction, region, result)
            })
        }
    }
}

@available(iOS 13.4, *)
public final class PointerAnimating {

    public typealias PointerAnimation = (UIPointerInteraction, UIPointerRegion) -> Void
    public typealias PointerCompletion = (UIPointerInteraction, UIPointerRegion, Bool) -> Void

    var willEnterAnimations: [PointerAnimation] = []
    var willExitAnimations: [PointerAnimation] = []
    var willEnterCompletions: [PointerCompletion] = []
    var willExitCompletions: [PointerCompletion] = []

    public func addWillEnter(animation: @escaping PointerAnimation) {
        willEnterAnimations.append(animation)
    }

    public func addWillEnter(completion: @escaping PointerCompletion) {
        willEnterCompletions.append(completion)
    }

    public func addWillExit(animation: @escaping PointerAnimation) {
        willExitAnimations.append(animation)
    }

    public func addWillExit(completion: @escaping PointerCompletion) {
        willExitCompletions.append(completion)
    }

    public init() {
    }
}
