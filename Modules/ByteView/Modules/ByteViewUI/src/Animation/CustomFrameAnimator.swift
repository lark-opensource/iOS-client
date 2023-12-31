//
//  CustomFrameAnimator.swift
//  ByteViewUI
//
//  Created by chenyizhuo on 2022/11/22.
//

import UIKit

/// 与 UIKit 提供的动画的不同之处:
///     - 没有 removeOnCompletion 的设置，默认完成后移除
///     - 动画过程实际上会改变视图的属性
///     - 完成后视图的实际属性会根据设置实际更新为初始值或最终值
public final class CustomFrameAnimator: BVAnimator {
    public var duration: TimeInterval = 0
    public var repeatCount: Float = 1 {
        didSet {
            _isRepeatForever = repeatCount == .greatestFiniteMagnitude
        }
    }
    public var autoreverse = false
    public var completionMode: BVAnimatorCompletionMode = .final
    public var preferredFramesPerSecond: CGFloat = 60 {
        didSet {
            _preferredDeltaOfTime = 1.0 / preferredFramesPerSecond
        }
    }
    public var completionHandler: (() -> Void)?

    private static let epsilon: CGFloat = 1e-5
    private var properties: [BVAnimationProperty] = []
    private lazy var _preferredDeltaOfTime: CGFloat = 1.0 / CGFloat(preferredFramesPerSecond)
    private var _isInverse = false
    private var _completionCount = 0
    private var _isRepeatForever = false
    private var startTime: CFTimeInterval?
    private var animationStartTime = CACurrentMediaTime()
    private weak var view: UIView?
    private var key = UUID().uuidString

    public init() {
    }

    deinit {
        onCompletion()
    }

    public func add(_ property: BVAnimationProperty) {
        properties.append(property)
    }

    public func add(on view: UIView, for key: String? = nil) {
        if let current = self.view, current != view {
            BVAnimationRuntime.shared.removeAnimation(on: current, for: self.key)
        }

        let newKey = key ?? UUID().uuidString
        self.key = newKey
        BVAnimationRuntime.shared.add(self, on: view, for: newKey)
        self.view = view
        reset()
    }

    func apply(_ value: Any?, of type: BVAnimationPropertyType) {
        guard let view = view, let value = value else { return }
        switch type {
        case .none: break
        case .frame:
            if let value = value as? CGRect {
                view.frame = value
            }
        case .alpha:
            if let value = value as? CGFloat {
                view.alpha = value
            }
        case .origin:
            if let value = value as? CGPoint {
                view.frame.origin = value
            }
        case .x:
            if let value = value as? CGFloat {
                view.frame.origin.x = value
            }
        case .y:
            if let value = value as? CGFloat {
                view.frame.origin.y = value
            }
        case .size:
            if let value = value as? CGSize {
                view.frame.size = value
            }
        case .width:
            if let value = value as? CGFloat {
                view.frame.size.width = value
            }
        case .height:
            if let value = value as? CGFloat {
                view.frame.size.height = value
            }
        case .center:
            if let value = value as? CGPoint {
                view.frame.origin = CGPoint(x: value.x - view.frame.width / 2, y: value.y - view.frame.height / 2)
            }
        case .centerX:
            if let value = value as? CGFloat {
                view.frame.origin.x = value - view.frame.width / 2
            }
        case .centerY:
            if let value = value as? CGFloat {
                view.frame.origin.y = value - view.frame.height / 2
            }
        case .color:
            if let value = value as? UIColor {
                view.backgroundColor = value
            }
        }
    }

    func remove() {
        if let view = view {
            BVAnimationRuntime.shared.removeAnimation(on: view, for: key)
        }
    }

    private func reset() {
        animationStartTime = CACurrentMediaTime()
    }

    private func onCompletion() {
        let percentage: CGFloat = completionMode == .final ? 1.0 : 0.0
        for property in properties {
            let value = property.appliedValue(with: percentage)
            apply(value, of: property.type)
        }
        completionHandler?()
    }

    private var isCompleted: Bool {
        if _isRepeatForever { return false }
        return Float(autoreverse ? _completionCount / 2 : _completionCount) >= repeatCount
    }

    // MARK: - BVAnimator

    func render(time: TimeInterval) {
        guard view != nil else { return }

        if let startTime = startTime {
            let delta = time - startTime
            guard delta - _preferredDeltaOfTime >= -Self.epsilon else {
                return
            }
            self.startTime = time
        } else {
            startTime = time
            return
        }

        let percentage = min(max((time - animationStartTime) / duration, 0), 1)

        for property in properties {
            let value = property.appliedValue(with: percentage, inverse: _isInverse)
            apply(value, of: property.type)
        }

        if percentage >= 1 {
            _completionCount += 1
            if isCompleted {
                remove()
            }
            if autoreverse {
                _isInverse = !_isInverse
            }
            reset()
        }
    }
}

public enum BVAnimatorCompletionMode {
    case initial
    case final
}
