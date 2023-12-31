//
//  ContextAnimating.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/12/18.
//

import UIKit
import Foundation

/// contextMenuAnimating 支持定制 context 动画
@available(iOS 13.0, *)
public final class ContextMenuAnimating {

    public typealias Animation = (
        UIContextMenuInteraction,
        UIContextMenuConfiguration,
        UIViewController?
    ) -> Void

    var displayAnimations: [Animation] = []
    var displayCompletions: [Animation] = []

    var willPerformAnimations: [Animation] = []
    var willPerformCompletions: [Animation] = []

    var endAnimations: [Animation] = []
    var endCompletions: [Animation] = []

    public func addDisplay(animation: @escaping Animation) {
        displayAnimations.append(animation)
    }

    public func addDisplay(completion: @escaping Animation) {
        displayCompletions.append(completion)
    }

    public func addWillPerform(animation: @escaping Animation) {
        willPerformAnimations.append(animation)
    }

    public func addWillPerform(completion: @escaping Animation) {
        willPerformCompletions.append(completion)
    }

    public func addEnd(animation: @escaping Animation) {
        endAnimations.append(animation)
    }

    public func addEnd(completion: @escaping Animation) {
        endCompletions.append(completion)
    }

    public init() {
    }
}
