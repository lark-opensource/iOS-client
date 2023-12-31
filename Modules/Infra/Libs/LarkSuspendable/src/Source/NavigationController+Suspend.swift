//
//  NavigationController+Suspend.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/5.
//

import Foundation
import UIKit
import LarkUIKit
import Homeric
import LKCommonsTracker
import LarkTab
import LarkContainer
import LarkQuickLaunchInterface

// MARK: - 处理交互式关闭手势

extension UINavigationController {

    private struct AssociatedKeys {
        static var poppingVC = "AssociatedKeys_popingVC"
    }

    // swiftlint:disable all
    var poppingIdentifier: String? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.poppingVC) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.poppingVC, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    // swiftlint:enable all

    private static let onceToken = UUID().uuidString
    static func initializeSuspendOnce() {
        guard self == UINavigationController.self else { return }
        DispatchQueue.dispatchOnce(onceToken) {
            let swizzleSelectors = [
                NSSelectorFromString("_updateInteractiveTransition:"),
                NSSelectorFromString("_finishInteractiveTransition:transitionContext:"),
                NSSelectorFromString("_cancelInteractiveTransition:transitionContext:"),
                NSSelectorFromString("popViewControllerAnimated:"),
                NSSelectorFromString("pushViewController:animated:"),
                NSSelectorFromString("popToRootViewControllerAnimated:"),
                NSSelectorFromString("popToViewController:animated:")
            ]
            for selector in swizzleSelectors {
                let newSelector = ("swizzle_" + selector.description).replacingOccurrences(of: "__", with: "_")
                if let originalMethod = class_getInstanceMethod(self, selector),
                   let swizzledMethod = class_getInstanceMethod(self, Selector(newSelector)) {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }
            }
        }
    }

    @objc
    func swizzle_pushViewController(_ viewController: UIViewController, animated: Bool) {
        poppingIdentifier = nil
        swizzle_pushViewController(viewController, animated: animated)
    }

    @objc
    func swizzle_popViewControllerAnimated(_ animated: Bool) -> UIViewController? {
        // 页面支持手势侧划添加或者同时遵循Suspendable和TabCandidate协议都可以被添加到多任务栏
        if let suspendVC = topViewController as? ViewControllerSuspendable,
           suspendVC.isInteractive {
            // suspendVC.view.endEditing(true)
            poppingIdentifier = suspendVC.suspendID
        }
        return swizzle_popViewControllerAnimated(animated)
    }

    @objc
    func swizzle_popToRootViewControllerAnimated(_ animated: Bool) -> [UIViewController]? {
        // 页面支持手势侧划添加或者同时遵循Suspendable和TabCandidate协议都可以被添加到多任务栏
        if let suspendVC = topViewController as? ViewControllerSuspendable,
           suspendVC.isInteractive {
            // suspendVC.view.endEditing(true)
            poppingIdentifier = suspendVC.suspendID
        }
        return swizzle_popToRootViewControllerAnimated(animated)
    }

    @objc
    func swizzle_popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        // 页面支持手势侧划添加或者同时遵循Suspendable和TabCandidate协议都可以被添加到多任务栏
        if let suspendVC = topViewController as? ViewControllerSuspendable,
           suspendVC.isInteractive {
            // suspendVC.view.endEditing(true)
            poppingIdentifier = suspendVC.suspendID
        }
        return swizzle_popToViewController(viewController, animated: animated)
    }

    @objc
    func swizzle_updateInteractiveTransition(_ percentComplete: CGFloat) {
        swizzle_updateInteractiveTransition(percentComplete)
        guard SuspendManager.isSuspendEnabled else { return }
        guard let poppingid = poppingIdentifier,
              let mainWindow = UIApplication.shared.delegate?.window,
              let keyWindow = mainWindow,
              let point = interactivePopGestureRecognizer?.location(in: keyWindow) else { return }
        /// 添加右下角扇形view
        if SuspendManager.shared.basketView.superview != keyWindow {
            SuspendManager.shared.basketView.removeFromSuperview()
            keyWindow.addSubview(SuspendManager.shared.basketView)
        }
        /// 如果是新的控制器，显示扇形，否则显示悬浮窗
        if SuspendManager.shared.contains(suspendID: poppingid) {
            SuspendManager.shared.basketView.state = .exist
        }
        SuspendManager.shared.basketView.show(percent: percentComplete)
        SuspendManager.shared.basketView.touchDidMove(toPoint: point)
    }

    @objc
    func swizzle_finishInteractiveTransition(_ percentComplete: CGFloat,
                                             transitionContext: UIViewControllerContextTransitioning) {
        swizzle_finishInteractiveTransition(percentComplete, transitionContext: transitionContext)
        guard SuspendManager.isSuspendEnabled else { return }
        defer {
            SuspendManager.shared.basketView.hide()
            poppingIdentifier = nil
        }
        SuspendManager.shared.basketView.removeFromSuperview()
        guard let poppingId = poppingIdentifier,
            let keyWindow = UIApplication.shared.keyWindow,
            let point = interactivePopGestureRecognizer?.location(in: keyWindow) else {
            return
        }
        // 如果「最近使用」功能打开则添加展示最近使用
        if SuspendManager.shared.isQuickLaunchServiceEnabled {
            guard let topVC = transitionContext.viewController(forKey: .from) as? TabContainable,
                  SuspendManager.shared.basketView.isInsideBasket(point: point) else {
                return
            }
            SuspendManager.shared.pinToQuickLaunchWindow(vc: topVC)
            return
        }
        guard let topVC = transitionContext.viewController(forKey: .from) as? ViewControllerSuspendable else {
            return
        }
        guard !SuspendManager.shared.contains(suspendID: poppingId),
              SuspendManager.shared.basketView.isInsideBasket(point: point) else {
            return
        }
        /// 添加新的悬浮窗
        if SuspendManager.shared.isFull {
            if topVC.isViewControllerRecoverable {
                pushViewController(topVC, animated: true) {
                    SuspendManager.shared.addSuspend(viewController: topVC, shouldClose: true)
                    SuspendManager.shared.viewControllerDidClose(topVC.suspendID)
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    SuspendManager.shared.pushViewController(by: topVC.getPatch(), animated: true) { _ in
                        SuspendManager.shared.addSuspend(viewController: topVC, shouldClose: true)
                        SuspendManager.shared.viewControllerDidClose(topVC.suspendID)
                    }
                }
            }
            // 埋点
            Tracker.post(TeaEvent(Homeric.TASKLIST_ADD_BY_SLIDE, params: [
                "add_result": "failure",
                "task_type": topVC.analyticsTypeName
            ]))
            Tracker.post(TeaEvent(Homeric.TASKLIST_FILLED))
        } else {
            // Fake animation.
            if let snapshotView = topVC.view.snapshotView(afterScreenUpdates: false),
               let bubbleView = SuspendManager.shared.suspendController?.bubbleView {
                topVC.view.isHidden = true
                keyWindow.addSubview(snapshotView)
                let fullframe = topVC.view.convert(topVC.view.bounds, to: keyWindow)
                snapshotView.frame = CGRect(
                    x: fullframe.width * percentComplete,
                    y: fullframe.origin.y,
                    width: fullframe.width,
                    height: fullframe.height
                )
                var bubbleFrame = bubbleView.convert(bubbleView.bounds, to: snapshotView)
                bubbleFrame.origin.x = 0
                let cornerRadius = SuspendConfig.bubbleSize.height / 2
                let beginPath = UIBezierPath(roundedRect: snapshotView.bounds, cornerRadius: cornerRadius)
                let endPath = UIBezierPath(roundedRect: bubbleFrame, cornerRadius: cornerRadius)
                let maskLayer = CAShapeLayer()
                maskLayer.path = endPath.cgPath
                snapshotView.layer.mask = maskLayer
                let animation = CABasicAnimation(keyPath: "path")
                animation.fromValue = beginPath.cgPath
                animation.toValue = endPath.cgPath
                animation.duration = SuspendConfig.animateDuration
                maskLayer.add(animation, forKey: "path")
                let offsetX = bubbleView.frame.minX - snapshotView.frame.minX
                UIView.animate(withDuration: SuspendConfig.animateDuration, animations: {
                    snapshotView.transform = CGAffineTransform(translationX: offsetX, y: 0)
                }, completion: { _ in
                    maskLayer.removeFromSuperlayer()
                    snapshotView.removeFromSuperview()
                    // Add vc to suspend list.
                    SuspendManager.shared.addSuspend(viewController: topVC, shouldClose: false, isBySlide: true)
                    SuspendManager.shared.viewControllerDidClose(topVC.suspendID)
                    // Recover the view visibility if needed.s
                    if topVC.isWarmStartEnabled {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            topVC.view.isHidden = false
                        }
                    }
                })
            } else {
                // No fake animation.
                SuspendManager.shared.addSuspend(viewController: topVC, shouldClose: false, isBySlide: true)
                SuspendManager.shared.viewControllerDidClose(topVC.suspendID)
            }
            // 埋点
            Tracker.post(TeaEvent(Homeric.TASKLIST_ADD_BY_SLIDE, params: [
                "add_result": "success",
                "task_type": topVC.analyticsTypeName
            ]))
        }
    }

    @objc
    func swizzle_cancelInteractiveTransition(_ percentComplete: CGFloat,
                                             transitionContext: UIViewControllerContextTransitioning) {
        swizzle_cancelInteractiveTransition(percentComplete, transitionContext: transitionContext)
        guard SuspendManager.isSuspendEnabled else { return }
        SuspendManager.shared.basketView.hide()
        poppingIdentifier = nil
    }

}

// MARK: - UINavigationControllerDelegate
extension UINavigationController: UINavigationControllerDelegate {

    public func navigationController(_ navigationController: UINavigationController,
                                     didShow viewController: UIViewController,
                                     animated: Bool) {
        poppingIdentifier = nil
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard SuspendManager.isSuspendEnabled else { return nil }
        switch operation {
        case .push:
            guard let suspendToVC = toVC as? ViewControllerSuspendable,
                  SuspendManager.shared.isFromSuspend(sourceID: suspendToVC.suspendSourceID) else {
                return nil
            }
            return SuspendTransition(type: .push)
        case .pop:
            guard let suspendFromVC = fromVC as? ViewControllerSuspendable,
                  SuspendManager.shared.isFromSuspend(sourceID: suspendFromVC.suspendSourceID) else {
                return nil
            }
            return SuspendTransition(type: .pop)
        default:
            return nil
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension UINavigationController: UIGestureRecognizerDelegate {

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

// MARK: - 处理页面切换时状态栏样式变化

extension UIViewController {

    private static let onceToken = UUID().uuidString
    static func initializeSuspendOnceForViewController() {
        guard self == UIViewController.self else { return }
        DispatchQueue.dispatchOnce(onceToken) {
            let swizzleSelectors = [
                NSSelectorFromString("viewDidAppear:"),
                NSSelectorFromString("viewWillDisappear:")
            ]
            for selector in swizzleSelectors {
                let newSelector = ("swizzle_" + selector.description)
                if let originalMethod = class_getInstanceMethod(self, selector),
                   let swizzledMethod = class_getInstanceMethod(self, Selector(newSelector)) {
                    method_exchangeImplementations(originalMethod, swizzledMethod)
                }
            }
        }
    }

    @objc
    func swizzle_viewDidAppear(_ animated: Bool) {
        if let suspendVC = self as? ViewControllerSuspendable,
           SuspendManager.shared.contains(suspendID: suspendVC.suspendID) {
            if suspendVC.isWarmStartEnabled {
                SuspendManager.shared.vcHolder[suspendVC.suspendID] = suspendVC
            }
            SuspendManager.shared.viewControllerDidOpen(suspendVC.suspendID)

            if let page = self as? PagePreservable {
                page.pageScene = .suspend
            }
        }

        if let tabContainableVC = self as? TabContainable, tabContainableVC.isAutoAddEdgeTabBar {
            SuspendManager.shared.addTemporaryTab(vc: tabContainableVC)
            if let page = self as? PagePreservable {
                page.pageScene = .temporary
            }
        }
        swizzle_viewDidAppear(animated)
    }

    @objc
    func swizzle_viewWillDisappear(_ animated: Bool) {
        if let suspendVC = self as? ViewControllerSuspendable,
           SuspendManager.shared.contains(suspendID: suspendVC.suspendID) {
            SuspendManager.shared.viewControllerDidClose(suspendVC.suspendID)
            SuspendManager.shared.updateSuspend(viewController: suspendVC)
            if let page = self as? PagePreservable {
                page.pageScene = .suspend
            }
        }

        // 自动记录符合条件的 “最近打开” 页面
        if let tabContainableVC = self as? TabContainable {
            SuspendManager.shared.addRecentRecord(vc: tabContainableVC)
        }

        if let page = self as? PagePreservable {
            SuspendManager.shared.addPagePreservable(vc: page)
        }
        swizzle_viewWillDisappear(animated)
    }
}
