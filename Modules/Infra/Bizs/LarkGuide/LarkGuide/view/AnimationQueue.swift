//
//  AnimationQueue.swift
//  LarkUIKit
//
//  Created by lichen on 2017/8/13.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

public protocol AnimationItemProtocol: AnyObject {
    func startAnimation()
    func stopAnimation()
    var isRunning: Bool { get }
    var callbackQueueBlock: (() -> Void)? { get set }
}

public final class AnimationQueue {
    private var animations: [AnimationItemProtocol] = []
    private var finishCallback: ((_ cancel: Bool) -> Void)?
    private(set) var isCanceled: Bool = false

    public func add(_ animation: AnimationItemProtocol) -> AnimationQueue {
        self.animations.append(animation)
        return self
    }

    public func add(group groupAnimations: [AnimationItemProtocol]) -> AnimationQueue {
        return self.add(BaseAnimationGroupItem(animations: groupAnimations))
    }

    // start 之后就不可以再添加 animation item
    @discardableResult
    public func start() -> AnimationQueue {
        self.isCanceled = false
        if self.animations.isEmpty {
            return self
        }
        if !self.isRunning() {
            self.runAnimations(self.animations)
        }
        return self
    }

    public func finishCallback(_ callback: ((_ cancel: Bool) -> Void)?) -> AnimationQueue {
        self.finishCallback = callback
        return self
    }

    public func cancel() {
        self.isCanceled = true
        self.animations.forEach { (animation) in
            animation.callbackQueueBlock = nil
            animation.stopAnimation()
        }
        self.finishCallback?(true)
    }

    public func isRunning() -> Bool {
        for animation in self.animations where animation.isRunning {
            return true
        }
        return false
    }

    private func runAnimations(_ animations: [AnimationItemProtocol]) {
        guard let first = animations.first else {
            if !self.isCanceled {
                self.finishCallback?(false)
            }
            return
        }
        var otherAnimations = animations
        otherAnimations.remove(at: 0)
        first.callbackQueueBlock = { [weak first] in
            if !self.isCanceled {
                self.runAnimations(otherAnimations)
            }
            first?.callbackQueueBlock = nil
        }
        first.startAnimation()
    }

    public init() {}
}

public class BaseAnimationItem: AnimationItemProtocol {
    public var callbackQueueBlock: (() -> Void)?

    let animationBlock: (_ finishBlock: @escaping () -> Void) -> Void

    public init(_ animationBlock: @escaping (_ finishBlock: @escaping () -> Void) -> Void) {
        self.animationBlock = animationBlock
    }

    public var isRunning: Bool {
        if finished {
            return false
        }
        return self._isRunning
    }

    private var finished: Bool = false
    private var _isRunning: Bool = false

    public func startAnimation() {
        self.finished = false
        self._isRunning = true
        self.animationBlock({ [weak self] in
            self?.stopAnimation()
            self?._isRunning = false
        })
    }

    public func stopAnimation() {
        if !self.finished {
            self.finished = true
            self.callbackQueueBlock?()
        }
    }
}

public final class BaseAnimationGroupItem: BaseAnimationItem {
    private let animations: [AnimationItemProtocol]

    init(animations: [AnimationItemProtocol]) {
        self.animations = animations
        super.init { (callback) in
            if animations.isEmpty {
                callback()
            }

            let group = DispatchGroup()
            animations.forEach({ (animation) in
                group.enter()
                animation.callbackQueueBlock = {
                    group.leave()
                }
                animation.startAnimation()
            })

            group.notify(queue: DispatchQueue.main, execute: {
                callback()
            })
        }
    }

    public override func stopAnimation() {
        super.stopAnimation()
        animations.forEach({ (animation) in
            animation.stopAnimation()
        })
    }
}
