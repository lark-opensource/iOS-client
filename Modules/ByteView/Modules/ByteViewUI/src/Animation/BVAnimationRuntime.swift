//
//  BVAnimationRuntime.swift
//  ByteViewUI
//
//  Created by chenyizhuo on 2022/11/22.
//

import UIKit

protocol BVAnimator {
    func render(time: TimeInterval)
}

public final class BVAnimationRuntime {
    public static let shared = BVAnimationRuntime()

    private lazy var displayLink = CADisplayLink(target: self, selector: #selector(render(_:)))
    private var animations: [WeakViewWrapper: [String: CustomFrameAnimator]] = [:]

    private init() {
        displayLink.isPaused = true
        displayLink.add(to: RunLoop.main, forMode: .common)
    }

    private func updateDisplayLink() {
        animations = animations.filter({ pair in
            pair.key.view != nil
        })
        let paused = animations.isEmpty
        if displayLink.isPaused != paused {
            displayLink.isPaused = paused
        }
    }

    /// 调用方保证在主线程调用
    public func add(_ animation: CustomFrameAnimator, on view: UIView, for key: String) {
        assertMain()
        let viewKey = WeakViewWrapper(view: view)
        var dict: [String: CustomFrameAnimator]
        if let currentDict = animations[viewKey] {
            dict = currentDict
        } else {
            dict = [:]
        }
        let original = dict[key]
        // original 需要延迟释放，因为 original 在释放时会调用 onCompletion，
        // 而业务方在一个动画的 completion 回调里可能直接创建另一个动画，此时会有对 animations 字典的抢占式访问
        withExtendedLifetime(original, {
            dict[key] = animation
            animations[viewKey] = dict
            updateDisplayLink()
        })
    }

    /// 调用方保证在主线程调用
    public func removeAnimation(on view: UIView, for key: String) {
        assertMain()
        let viewKey = WeakViewWrapper(view: view)
        var dict = animations[viewKey]
        let original = dict?[key]
        withExtendedLifetime(original, {
            dict?.removeValue(forKey: key)
            if dict == nil || dict!.isEmpty {
                animations.removeValue(forKey: viewKey)
            } else {
                animations[viewKey] = dict
            }
            updateDisplayLink()
        })
    }

    @objc
    private func render(_ link: CADisplayLink) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for dict in animations.values {
            for animator in dict.values {
                animator.render(time: link.targetTimestamp)
            }
        }
        updateDisplayLink()

        CATransaction.commit()
    }
}

private class WeakViewWrapper: Hashable {
    weak var view: UIView?
    private let viewHashValue: Int
    init(view: UIView) {
        self.view = view
        self.viewHashValue = view.hashValue
    }

    static func == (lhs: WeakViewWrapper, rhs: WeakViewWrapper) -> Bool {
        lhs.view != nil && lhs.view == rhs.view
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(viewHashValue)
    }
}
