//
//  FeedPresentProcessor.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/9.
//

import Foundation

final class FeedPresentProcessor: NSObject {

    weak var delegate: FeedPresentProcessorDelegate?
    var isAnimating = false
    var currentType: PresentType?
    var currentPresentVC: FeedPresentAnimationViewController?

    /// 一些processor内部的dismiss通知处理（如点击popoverVC以外的区域引起的dismiss)
    /// 调用时传入当前dismiss的presentType类型
    var innerTriggerDismissHandler: ((PresentType?) -> Void)?

    /// 触发下一类型的PresentType
    ///
    /// 互斥的presentVC通过此方法将切换逻辑交给FeedPresentProcessor处理
    /// 在进入时会检测，如果在show/dismiss动画中会对状态进行加锁，此时本次调用失败
    /// * 如果当前没有进行show/dismiss动画，则会进入状态（PresentType）切换流程，在开始和结束会分别触发preProcess和postProcess
    /// * 如果上一状态和下一状态相同，则会dismiss并清空状态
    /// * 如果上一状态已经有Present在显示了，则会先dismiss上一状态，然后再present新的状态
    /// * 如果上一状态为空，则会直接present新的状态
    ///
    /// - Parameters:
    ///   - type: PresentType状态的类型
    ///   - preProcess: 切换状态前的hook
    ///   - postProcess: 切换状态后的hook
    func processIfNeeded(type: PresentType,
                         source: PopoverSource? = nil,
                         preProcess: ((PresentType?) -> Void)? = nil,
                         postProcess: (() -> Void)? = nil) {
        guard !isAnimating else { return }
        FeedTracker.Navigation.Click.Plus()

        isAnimating = true
        // 这里估计没写错，设计的就是传入上一次记录的type，preProcess不是指当前type，而是针对currentType（这里的currentType表示已经展示出来的，其实也是lastType）
        preProcess?(currentType)

        let showCompletion: (FeedPresentAnimationViewController?) -> Void = { [weak self] presentVC in
            guard let self = self else { return }
            self.currentType = type
            self.currentPresentVC = presentVC
            self.isAnimating = false

            postProcess?()
        }

        let hideCompletion: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.currentType = nil
            self.currentPresentVC = nil
            self.isAnimating = false

            postProcess?()
        }

        if currentPresentVC != nil {
            if currentType == type {  // 相同type，做收起逻辑
                hideCurrentViewController(completion: hideCompletion)
            } else {
                // 不同type，先收起旧的，在展开新的
                hideCurrentViewController { [weak self] in
                    self?.showPresent(for: type, source: source, completion: showCompletion)
                }
            }
        } else {
            // 原来状态为空，显示新的
            showPresent(for: type, source: source, completion: showCompletion)
        }
    }

    func dismissCurrentIfNeeded(animate: Bool = false,
                                checkType: PresentType? = nil,
                                handleInnerTriggerDismiss: Bool = false,
                                completion: (() -> Void)? = nil) {
        guard !isAnimating else { return }

        if let checkType = checkType, let currentType = currentType {
            assert(checkType == currentType)
            // 此处log异常，但不阻塞dismiss，保证presentVC可被dismiss
        }

        isAnimating = true

        hideCurrentViewController(animate: animate) { [weak self] in
            guard let self = self else { return }
            let type = self.currentType
            self.currentType = nil
            self.currentPresentVC = nil
            self.isAnimating = false
            completion?()
            if handleInnerTriggerDismiss {
                self.innerTriggerDismissHandler?(type)
            }
        }
    }

    private func hideCurrentViewController(animate: Bool = false, completion: @escaping () -> Void) {
        if let currentVC = currentPresentVC {
            // 为了支持VC自定义的消失动画先执行，然后再取消掉VC自己
            currentVC.hideAnimation(animated: false) { [weak self] in
                self?.dismissCurrentVC(animate: animate, completion: completion) ?? completion()
            }
        } else {
            completion()
        }
    }

    private func dismissCurrentVC(animate: Bool = false, completion: @escaping () -> Void) {
        if let currentVC = currentPresentVC, currentVC.presentingViewController != nil, !currentVC.isBeingDismissed {
            currentVC.dismiss(animated: animate, completion: completion)
        } else {
            completion()
        }
    }

    private func showPresent(for type: PresentType,
                             source: PopoverSource?,
                             completion: @escaping (FeedPresentAnimationViewController) -> Void) {
        delegate?.showPresent(for: type, source: source) { presentVC in
            presentVC.showAnimation {
                completion(presentVC)
            }
        }
    }
}
