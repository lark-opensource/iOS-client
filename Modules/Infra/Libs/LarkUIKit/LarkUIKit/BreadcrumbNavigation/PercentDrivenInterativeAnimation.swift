//
//  PercentDrivenInteractiveAnimation.swift
//  PercentDriveInteractiveTransition
//
//  Created by SolaWing on 2020/12/14.
//

import Foundation
import UIKit

/// percent driven to manual control a animation progress, within the rootView by control it's local time
public final class PercentDrivenInterativeAnimation {
    public let rootView: UIView
    public init(root: UIView) {
        self.rootView = root
    }
    deinit {
        if self.state != .waiting {
            self.finish(success: false)
        }
    }

    var duration: CFTimeInterval = 0
    var startOffset: CFTimeInterval = 0 // use to keep local time and keep the already animation
    private var stopTimor: CADisplayLink?
    private var completion: ((Bool) -> Void)?
    public enum State {
        case waiting // 等待交互状态
        case interacting // 交互中，等待交互更新percent状态
        case stoping // 结束动画中
        case canceling // cancel动画中
    }
    public private(set) var state: State = .waiting {
        willSet {
            #if DEBUG // 状态转换断言
            switch newValue {
            case .waiting: break
            case .interacting:
                assert(state == .waiting)
            case .stoping, .canceling:
                assert(state == .interacting)
            }
            #endif
        }
    }

    var _percent: CGFloat = 0
    /// set percent to update animation progress
    public var percent: CGFloat {
        get { _percent }
        set {
            _percent = fmax(fmin(newValue, 1), 0)
            rootView.layer.timeOffset = startOffset + Double(_percent) * duration
        }
    }
    /// call this to transfer rootView animation time control
    /// before end(or cancel), shouldn't repeat call this function and will be ignored
    public func beginInteractiveAnimation(duration: CFTimeInterval) {
        guard state == .waiting else { return }
        state = .interacting
        self.duration = duration
        startOffset = rootView.layer.convertTime(CACurrentMediaTime(), from: nil)
        _percent = 0

        rootView.layer.speed = 0
        rootView.layer.timeOffset = startOffset // keep original local time
    }
    /// must call end or cancel for each begin call. or the view state not recover
    ///
    /// - Parameters:
    ///   - completion: called when finish, with success or cancel
    public func endInteractiveAnimation(completion: @escaping (Bool) -> Void) {
        state = .stoping
        self.completion = completion
        _animationComplete()
    }
    /// must call end or cancel for each begin call. or the view state not recover
    ///
    /// - Parameters:
    ///   - completion: called when finish, with success or cancel
    public func cancelInteractiveAnimation(completion: @escaping (Bool) -> Void) {
        state = .canceling
        self.completion = completion
        _animationComplete()
    }
    private func _animationComplete() {
        // retain cycle until finish
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.add(to: RunLoop.main, forMode: .common)
        self.stopTimor = link
    }

    @objc
    private func tick() {
        guard let link = stopTimor else { return }
        let change = link.duration / CFTimeInterval(duration)
        if state == .stoping {
            self.percent += CGFloat(change)
            if self.percent >= 1 {
                finish(success: true)
            }
        } else {
            self.percent -= CGFloat(change)
            if self.percent <= 0 {
                finish(success: false)
            }
        }
    }

    private func finish(success: Bool) {
        stopTimor?.invalidate()
        stopTimor = nil

        let layer = rootView.layer
        let offset = layer.timeOffset
        layer.speed = 1
        layer.timeOffset = 0
        layer.beginTime = 0
        let tp = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.beginTime = tp - offset

        let success = state == .stoping
        state = .waiting
        if let completion = self.completion {
            self.completion = nil
            completion(success)
        }
    }
}
