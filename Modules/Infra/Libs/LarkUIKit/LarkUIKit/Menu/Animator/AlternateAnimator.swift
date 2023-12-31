//
//  AlternateAnimator.swift
//  animator
//
//  Created by 刘洋 on 2021/2/23.
//

import Foundation
import UIKit
import LarkFeatureGating

/// 动画器，负责多个UIView的轮换显示的动画
public final class AlternateAnimator {
    // 动画作用于的UIView
    private weak var targetView: UIView?

    /// 一次轮换的动画时长
    private let animationDuration: Double

    /// 需要轮换显示的UIView
    private var animateLists: [AlternateAnimatorViewWrapper] = []

    /// 当前正在动画的UIView
    public var currentAnimateViews: [UIView] {
        self.animateLists.compactMap {
            $0.view
        }
    }

    /// 动画是否开始
    private var hasStarted = false

    /// 当前动画中显示的UIView在数组中的位置
    private var currentAnimateIndex = 0
    /// 上次轮换结束后，上次UIView的透明度
    private var perviousAnimateLastKeyAlpha: CGFloat = 0.5

    /// 关键帧动画的关键时间点
    private let keyTime: [Double] = [0.1, 0.5, 0.8]
    /// 关键帧动画关键时间点的值
    private let keyValue: [CGFloat] = [0.8, 1, 0.8]

    /// 动画器
    private var animator: UIViewPropertyAnimator?

    /// 动画器的事件代理
    public weak var delegate: AlternateAnimatorDelegate?

    /// 检测目标View是否加载到屏幕
    private let detectWindowView = WindowDetectView(frame: .zero)

    /// 初始化轮换动画器
    /// - Parameters:
    ///   - targetView: 动画作用于的UIView
    ///   - animationDuration: 一次轮换动画的时长
    public init(targetView: UIView, animationDuration: Double) {
        self.targetView = targetView
        self.animationDuration = animationDuration

        listenTargetViewWindowChangeEvent()
    }

    /// 监听目标页面是否显示在屏幕上
    private func listenTargetViewWindowChangeEvent() {
        if self.animationRecoveryEnable() {
            detectWindowView.isUserInteractionEnabled = false
            targetView?.addSubview(detectWindowView)
            // 通过增加了一个子View的方式来监控，原因是xxx.window是计算属性，不能通过KVO监听。(子View的Frame为0,并且不能响应交互)
            detectWindowView.windowChangeCallback = { [weak self] hasWindow in
                guard let `self` = self else {
                    return
                }
                // 重新被添加到window上后，则尝试恢复动画
                if hasWindow && self.animator == nil {
                    self.animateForNext()
                }
            }
        }
    }

    /// 开始进行动画
    /// - Parameter lists: 开始动画时，需要轮换显示的UIView
    public func startAnimate() {
        // 确保现在没有开始动画
        guard !hasStarted else {
            return
        }
        // 确保动画时一定有要显示的UIView
        guard !self.animateLists.isEmpty else {
            return
        }
        guard let targetView = self.targetView else {
            return
        }

        /*
         cpu占用问题:https://bytedance.feishu.cn/docs/doccno5UBb9OCvKop7afn9IQxYg
         由于众多的视图对象对授权状态变化在监听，然后大部分并不显示在屏幕内。造成大量的动画开启，却不显示在屏幕上。
         
         动画视图的父视图不显示时，那么动画不开始
         
         可能会存在部分监听页面在此逻辑后又重新出现在显示区域中(通调用过Api)，正常用户逻辑理论不会出现
         */
        if LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.uikit.unvisible_animation_opt") { //Global 纯UI相关，成本比较大，先不改
            guard targetView.window != nil else {
                return
            }
        }

        hasStarted = true
        // 动画开始前，需要让动画作用于的targetView进行一些简单的操作，比如隐藏自己的内容等
        self.delegate?.animationWillStart(for: targetView)
        self.currentAnimateIndex = 0
        self.perviousAnimateLastKeyAlpha = 0

        self.animateForNext()
    }

    /// 进行一次轮换动画
    private func animateForNext() {
        // 确保动画已经开始
        guard hasStarted else {
            return
        }

        if self.animationRecoveryEnable() {
            guard self.animator == nil else {
                // 动画不能重复设置。在动画结束后，需要将开关置为nil
                return
            }
        }

        guard let targetView = self.targetView else {
            endAnimate()
            return
        }

        if LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.uikit.recursive_animation_opt") { //Global 纯UI相关，成本比较大，先不改
            // 产生问题的关键，当不在屏幕中的View被添加的动画后，动画并不会执行，且会直接调用completion回调，而回调会触发下一次的动画，相当于自己调用自己，直接将CPU打满
            // 单独开启这个开关可以解决问题，但是可能会存在动画无法恢复的问题，另一个开关openplatform.uikit.recursive_animation_opt_recovry用来解决这个问题
            guard self.targetView?.window != nil else {
                return
            }
        }

        // 获得当前轮换中需要显示的UIView
        let currentAnimatorIndexSafe = self.currentAnimateIndex % self.animateLists.count
        guard let currentAnimatorView = self.animateLists[currentAnimatorIndexSafe].view else {
            endAnimate()
            return
        }
        // 获取下次轮换中需要显示的UIView
        let nextAnimatorIndexSafe = (self.currentAnimateIndex + 1) % self.animateLists.count
        guard let nextAnimatorView = self.animateLists[nextAnimatorIndexSafe].view else {
            endAnimate()
            return
        }

        // 计算此次轮换结束后，显示UIView的透明度
        var animateLastKeyAlpha: CGFloat = 0
        // 如果当前UIView和下次的UIView是同一个，那么透明度变为0.5，否则为0，让其消失
        if currentAnimatorView === nextAnimatorView {
            animateLastKeyAlpha = 0.5
        }
        // 设置轮换开始前的UIView透明度
        currentAnimatorView.alpha = self.perviousAnimateLastKeyAlpha

        // 如果当前UIView 没有被添加到targetView则添加
        if currentAnimatorView.superview == nil {
            targetView.addSubview(currentAnimatorView)
            self.delegate?.animationDidAddSubView(for: targetView, subview: currentAnimatorView)
        }

        // 初始化动画器
        let animator = UIViewPropertyAnimator(duration: self.animationDuration, curve: .linear, animations: nil)

        // 设置关键帧动画
        animator.addAnimations {
            UIView.animateKeyframes(withDuration: self.animationDuration, delay: 0, options: .calculationModeLinear, animations: {
                var startTime: Double = 0
                for index in 0 ..< self.keyTime.count {
                    var durationTime: Double = 0
                    if index == 0 {
                        durationTime = self.keyTime[index]
                    } else {
                        durationTime = self.keyTime[index] - self.keyTime[index - 1]
                    }
                    UIView.addKeyframe(withRelativeStartTime: startTime, relativeDuration: durationTime, animations: {
                        currentAnimatorView.alpha = self.keyValue[index]
                    })
                    startTime = self.keyTime[index]
                }
                UIView.addKeyframe(withRelativeStartTime: startTime, relativeDuration: 1 - startTime, animations: {
                    currentAnimatorView.alpha = animateLastKeyAlpha
                })
            }, completion: nil)
        }

        // 添加动画完成的回调
        animator.addCompletion {[weak self] position in
            guard let `self` = self else {
                return
            }

            if self.animationRecoveryEnable() {
                self.animator = nil
            }

            self.animateComplete(with: position, currentView: currentAnimatorView, previousAlpha: animateLastKeyAlpha)
        }

        self.animator = animator
        // 开始动画
        animator.startAnimation()

    }

    /// 一轮动画完成之后的回调
    /// - Parameters:
    ///   - position: 动画完成的标志位
    ///   - currentView: 当前显示的UIView
    ///   - previousAlpha: 本轮结束时的UIView的透明度
    private func animateComplete(with position: UIViewAnimatingPosition, currentView: UIView, previousAlpha: CGFloat) {
        switch position {
        // 如果动画正常结束
        case .end:
            // 增加动画UIView的索引
            self.currentAnimateIndex += 1
            // 获取下次轮换中的动画UIView，因为有可能在此次轮换期间，动画的UIView数组被更新了，所以需要重新计算
            let nextAnimatorIndex = (self.currentAnimateIndex) % self.animateLists.count
            self.currentAnimateIndex = nextAnimatorIndex
            let nextAnimatorView = self.animateLists[nextAnimatorIndex].view
            // 如果当前显示的和下次显示的是一样的UIView，则将最后的透明度直接设置，以保证动画连贯性
            if nextAnimatorView === currentView {
                self.perviousAnimateLastKeyAlpha = previousAlpha
            } else {
                currentView.alpha = 0
                self.perviousAnimateLastKeyAlpha = 0
            }
            // 进行下次动画
            self.animateForNext()
        case .current:
            // 如果动画是中途被强制结束
            self.currentAnimateIndex = 0
            currentView.alpha = 0
            // 重置初始动画状态下的透明度
            self.perviousAnimateLastKeyAlpha = 0
        default:
            break
        }
    }

    /// 结束动画
    public func endAnimate() {
        // 确保动画已经开始
        guard hasStarted else {
            return
        }
        // 结束动画，改变标志位
        hasStarted = false
        // 如果此时动画正在运行，结束动画
        if let animator = self.animator, animator.isRunning {
            animator.stopAnimation(false)
            animator.finishAnimation(at: .current)
        }
        self.animator = nil
        _ = self.animateLists.map {
            $0.view
        }.compactMap {
            $0
        }.filter {
            $0.superview != nil
        }.map {
            $0.removeFromSuperview()
            if let targetView = self.targetView {
                self.delegate?.animationDidRemoveSubView(for: targetView, subview: $0)
            }
        }
        self.currentAnimateIndex = 0
        self.perviousAnimateLastKeyAlpha = 0
        // 动画结束后，需要让targetView恢复之前的状态
        if let targetView = self.targetView {
            self.delegate?.animationDidEnd(for: targetView)
        }
    }

    /// 更新动画使用的UIView
    /// - Parameter lists: 新的动画使用的UIView
    public func setAnimateLists(for lists: [UIView]) {
        // 确保动画已经开始
        guard hasStarted else {
            self.animateLists = lists.map {
                AlternateAnimatorViewWrapper(view: $0)
            }
            return
        }
        // 确保有UIView
        guard !lists.isEmpty else {
            return
        }
        // 获得当前动画使用的UIView
        let currentAnimatorIndex = self.currentAnimateIndex % self.animateLists.count
        let oldAnimateLists = self.animateLists
        // 如果新的UIView不包含正在动画的UIView，则重置动画，否责可以悄无声息的更新动画
        if let currentAnimatorView = self.animateLists[currentAnimatorIndex].view, let index = lists.firstIndex(of: currentAnimatorView) {
            // 更新索引
            // 更新UIView

            self.animateLists = lists.map {
                AlternateAnimatorViewWrapper(view: $0)
            }
            self.currentAnimateIndex = index
            oldAnimateLists.compactMap {
                $0.view
            }.filter {
                !lists.contains($0)
            }.filter {
                $0.superview != nil
            }.map {
                $0.removeFromSuperview()
                if let targetView = self.targetView {
                    self.delegate?.animationDidRemoveSubView(for: targetView, subview: $0)
                }
            }
        } else {
            // 重置动画,如果此时动画正在运行
            // 更新UIView
            if let animator = self.animator, animator.isRunning {
                animator.stopAnimation(false)
                animator.finishAnimation(at: .current)
            }

            self.animateLists = lists.map {
                AlternateAnimatorViewWrapper(view: $0)
            }

            oldAnimateLists.compactMap {
                $0.view
            }.filter {
                !lists.contains($0)
            }.filter {
                $0.superview != nil
            }.map {
                $0.removeFromSuperview()
                if let targetView = self.targetView {
                    self.delegate?.animationDidRemoveSubView(for: targetView, subview: $0)
                }
            }
            self.animator = nil
            animateForNext()
        }
    }

    private func animationRecoveryEnable() -> Bool {
        return !LarkFeatureGating.shared.getFeatureBoolValue(for: "openplatform.uikit.recursive_animation_opt_recovry")//Global 纯UI相关，成本比较大，先不改
    }
}

private final class WindowDetectView: UIView {
    var windowChangeCallback: ((Bool) -> Void)?

    // 重新方法是为了获取到被添加到window上的时机，当自身被添加到window上时，意味着父试图也被添加上去了;WindowDetectView本身无任何展示逻辑;
    override func didMoveToWindow() {
        super.didMoveToWindow()
        windowChangeCallback?(window != nil)
    }
}
