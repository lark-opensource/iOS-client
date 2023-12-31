//
//  LkNavigationController.swift
//  Lark
//
//  Created by zhuchao on 2017/2/20.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LKCommonsLogging
import Kingfisher
import UniverseDesignColor
import UniverseDesignTheme

public enum NavigationBarStyle: Equatable {
    case `default`, color(UIColor), clear, custom(_ backgroundColor: UIColor, tintColor: UIColor = UIColor.ud.textTitle), none

    /// eunm 默认实现了 Equatable https://github.com/apple/swift-evolution/blob/main/proposals/0185-synthesize-equatable-hashable.md
}

open class LKToolBarNavigationController: LkNavigationController {
    // 记录当前toolbar的坐标y值
    private var toolBarY: CGFloat?

    public override func viewDidLoad() {
        super.viewDidLoad()
        // 监听键盘将要改变位置
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillChangeFrame),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)

        if UIDevice.current.userInterfaceIdiom == .pad {
            // 监听键盘已经改变位置
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardDidChangeFrameForPad),
                                                   name: UIResponder.keyboardDidChangeFrameNotification,
                                                   object: nil)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 发现toolbar在viewDidLayoutSubviews前会被系统的布局覆盖掉其frmae的修改
        // 但如果只在viewDidAppear去重设frame会导致toolbar出现有延迟
        // 因此这里在viewDidLayoutSubviews重设其frame
        if let y = toolBarY {
            self.toolbar.frame.origin.y = y
        }
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 发现toolbar在viewDidLayoutSubviews后会被系统的布局覆盖掉其frame的修改
        // 因此这里在viewDidAppear重设其frame
        if let y = toolBarY {
            self.toolbar.frame.origin.y = y
        }
    }

    @objc
    private func keyboardWillChangeFrame(notification: Notification) {
        let userInfo = notification.userInfo
        guard let frame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if frame.minY >= self.view.frame.height {
            /// 收起时需要考虑安全距离
            var bottomSafeAreaHeight: CGFloat = 0
            bottomSafeAreaHeight = self.view.safeAreaInsets.bottom
            self.toolbar.frame.origin.y = self.view.frame.height - self.toolbar.frame.height - bottomSafeAreaHeight
            toolBarY = self.toolbar.frame.minY
        } else {
            self.toolbar.frame.origin.y = frame.origin.y - self.toolbar.frame.height
            toolBarY = self.toolbar.frame.minY
        }
    }

    // pad上键盘出现后vc会被上移(系统行为), 因此在keyboardDidChangeFrame这个时机对pad下的toolbar单独适配
    @objc
    private func keyboardDidChangeFrameForPad(notification: Notification) {
        let userInfo = notification.userInfo
        guard let frame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        if frame.minY >= self.view.frame.height {
            /// 收起时需要考虑安全距离
            var bottomSafeAreaHeight: CGFloat = 0
            bottomSafeAreaHeight = self.view.safeAreaInsets.bottom
            self.toolbar.frame.origin.y = self.view.frame.height - self.toolbar.frame.height - bottomSafeAreaHeight
            toolBarY = self.toolbar.frame.minY
        } else {
            // 由于pad的键盘不在vc内, 因此需要进行坐标系转化
            if let y = self.toolbar.superview?.convert(CGPoint(x: 0, y: frame.origin.y - self.toolbar.frame.height),
                                                       from: self.view.window).y {
                self.toolbar.frame.origin.y = y
                self.toolBarY = self.toolbar.frame.minY
            }
        }
    }
}

open class LkNavigationController: LKBaseNavigationController {

    public static let CancelPopGestureTag = 999_999
    public static let alogger = Logger.log(LkNavigationController.self, category: "Base.LkNavigationController")
    // 默认样式背景图
    public static var imageForDefaultStyle: UIImage { UIImage.ud.fromPureColor(UIColor.ud.bgBody)
    }
    // 默认样式的shadowimage
    public static var defaultShadowImage: UIImage { UIImage.ud.fromPureColor(UIColor.ud.bgBody)
        .kf.resize(to: CGSize(width: UIScreen.main.bounds.width, height: (1.0 / UIScreen.main.scale)))
    }

    // VCpush状态
    open var isPushing = false

    private var lastLayoutBounds: CGRect = .zero
    /// 如果在 Navibar push 过程中发生了 size 变化，needLayoutWhenVCDidShow 会被标记为 true
    /// 在 push 结束的时候重新触发 layout 方法
    private var needLayoutWhenVCDidShow: Bool = false

    public let allowUpdateWhenStates: [UIGestureRecognizer.State] = [.possible, .cancelled, .failed, .ended]

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.modalPresentationControl.readyToControlIfNeeded()
    }

    private var callStackDepth = 0
    private let maxCallStackDepth = 5
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        defer {
            callStackDepth -= 1
        }
        callStackDepth += 1
        guard callStackDepth <= maxCallStackDepth else {
            return self.viewControllers.last?.preferredStatusBarStyle ?? .default
        }
        if let presentedVc = self.presentedViewController {
            if !presentedVc.isBeingDismissed {
                return presentedVc.preferredStatusBarStyle
            }
        }
        return self.viewControllers.last?.preferredStatusBarStyle ?? .default
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let presentedVc = self.presentedViewController {
            if !presentedVc.isBeingDismissed {
                return presentedVc.supportedInterfaceOrientations
            }
        }
        return self.viewControllers.last?.supportedInterfaceOrientations ?? .allButUpsideDown
    }

    open override var shouldAutorotate: Bool {
        return self.viewControllers.last?.shouldAutorotate ?? true
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.navigationBar.isTranslucent = false
        self.automaticallyAdjustsScrollViewInsets = false
        self.interactivePopGestureRecognizer?.delegate = self

        self.update(style: .default)
    }

    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        // 如果viewControllers不为空，在push的时候隐藏底部bar（包括toolbar, tabbar）
        // 目前使用场景是，tabbar controller中每个tab是一个navigation, 这个navigation再次push页面的时候，
        // 需要隐藏外层的tabbar
        if !self.viewControllers.isEmpty {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bounds = self.view.bounds
        /// 在 Push 过程中发生了 bounds 的变化
        /// 标记 needLayoutWhenVCDidShow 为 true
        /// 在 push 结束之后重新触发 layout
        if self.lastLayoutBounds != .zero,
            bounds != self.lastLayoutBounds,
            self.isPushing {
            self.needLayoutWhenVCDidShow = true
        }
        self.lastLayoutBounds = bounds
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        /// solving issue: in iOS 13, the second presented modally have a gap between navigation bar and the view
        /// it doesn't work to put this code in viewDidLoad() or viewWillAppear()
        /// related to: https://jira.bytedance.com/browse/SUITE-42793
        if #available(iOS 13.0, *) {
            for view in navigationBar.subviews {
                if NSStringFromClass(view.classForCoder).contains("UINavigationBarContentView") {
                    view.frame = CGRect(x: 0, y: 0, width: navigationBar.frame.size.width, height: navigationBar.frame.size.height)
                    view.sizeToFit()
                }
            }
        }
    }

    open func update(style: NavigationBarStyle) {
        switch style {
        case .default:
            self.navigationBar.isTranslucent = false
            self.navigationBar.tintColor = UIColor.ud.textTitle

            if #available(iOS 15.0, *) {
                updateNaviBarStyle(titleColor: UIColor.ud.textTitle, backgroundImage: LkNavigationController.imageForDefaultStyle)
            } else {
                self.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.textTitle]
                self.navigationBar.setBackgroundImage(LkNavigationController.imageForDefaultStyle, for: .default)
                self.navigationBar.shadowImage = UIImage()
            }
        case .color(let color):
            self.navigationBar.isTranslucent = false
            self.navigationBar.tintColor = UIColor.ud.primaryOnPrimaryFill
            if #available(iOS 15.0, *) {
                updateNaviBarStyle(titleColor: UIColor.ud.primaryOnPrimaryFill, backgroundImage: UIImage.ud.fromPureColor(color))
            } else {
                self.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.primaryOnPrimaryFill]
                self.navigationBar.setBackgroundImage(UIImage.ud.fromPureColor(color), for: .default)
                self.navigationBar.shadowImage = UIImage()
            }
        case .custom(let backgroundColor, let tintColor):
            self.navigationBar.isTranslucent = false
            self.navigationBar.tintColor = tintColor
            if #available(iOS 15.0, *) {
                updateNaviBarStyle(titleColor: tintColor, backgroundImage: UIImage.ud.fromPureColor(backgroundColor))
            } else {
                self.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: tintColor]
                self.navigationBar.setBackgroundImage(UIImage.ud.fromPureColor(backgroundColor), for: .default)
                self.navigationBar.shadowImage = UIImage()
            }
        case .clear:
            self.navigationBar.isTranslucent = true
            self.navigationBar.backgroundColor = UIColor.clear
            if #available(iOS 15.0, *) {
                updateNaviBarStyle(titleColor: nil, backgroundImage: UIImage())
            } else {
                self.navigationBar.setBackgroundImage(UIImage(), for: .default)
                self.navigationBar.shadowImage = UIImage()
            }
        case .none: break
        }
        if let vc = viewControllers.last as? CustomNavigationBar {
            setNavigationItemTintColor(navigationBar.tintColor, forViewController: vc)
        }
    }

    // https://developer.apple.com/forums/thread/683265
    @available(iOS 15.0, *)
    func updateNaviBarStyle(titleColor: UIColor?, backgroundImage: UIImage) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        if let titleColor = titleColor {
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: titleColor]
        }
        appearance.backgroundImage = backgroundImage
        appearance.shadowImage = UIImage.ud.fromPureColor(.clear)
        self.navigationBar.standardAppearance = appearance
        self.navigationBar.scrollEdgeAppearance = appearance
    }

    open func setNavigationItemTintColor(_ color: UIColor, forViewController vc: CustomNavigationBar) {
        vc.navigationItem.leftBarButtonItems?.forEach({ (barButtonItem) in
            barButtonItem.customView?.tintColor = color
        })

        vc.navigationItem.rightBarButtonItems?.forEach({ (barButtonItem) in
            barButtonItem.customView?.tintColor = color
        })
    }

    open func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        if otherGestureRecognizer is UILongPressGestureRecognizer {
            return false
        }
        return gestureRecognizer is UIScreenEdgePanGestureRecognizer
    }

    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.tag == LkNavigationController.CancelPopGestureTag {
            return false
        } else {
            return true
        }
    }
}

extension LkNavigationController {
    open override func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        super.navigationController(navigationController, willShow: viewController, animated: animated)
        isPushing = true
        let newTopItem = navigationController.topViewController?.navigationItem
        if newTopItem?.isEqual(navigationController.navigationBar.topItem) ?? false {
            return
        } else {
            for item in navigationController.navigationBar.items ?? [] {
                if item.isEqual(newTopItem) {
                    isPushing = false
                }
            }
        }
    }

    open override func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        super.navigationController(navigationController, didShow: viewController, animated: animated)
        isPushing = false
        if self.needLayoutWhenVCDidShow {
            self.view.setNeedsLayout()
            self.needLayoutWhenVCDidShow = false
        }
    }

    open func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .none:
            return nil
        case .push:
            return (fromVC as? CustomNaviAnimation)?
                .animationProxy?
                .pushAnimationController(from: fromVC, to: toVC) ??
                (toVC as? CustomNaviAnimation)?
                    .animationProxy?
                    .selfPushAnimationController(from: fromVC, to: toVC)
        case .pop:
            return (toVC as? CustomNaviAnimation)?
                .animationProxy?
                .popAnimationController(from: fromVC, to: toVC) ??
                (fromVC as? CustomNaviAnimation)?
                    .animationProxy?
                    .selfPopAnimationController(from: fromVC, to: toVC)
        @unknown default:
            fatalError()
        }
    }

    func navigationController(_ navigationController: UINavigationController,
                              interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard viewControllers.count >= 2 else { return nil }
        return (viewControllers[viewControllers.count - 2] as? CustomNaviAnimation)?
            .animationProxy?
            .interactiveTransitioning(with: animationController)
    }
}

public protocol CustomNaviAnimation {
    @available(*, deprecated, message: "Implement pushAnimationController(from:, to:) instead")
    func pushAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning?

    // push animation for `to vc` (self is `from vc`)
    func pushAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning?

    // push animation for `to vc` (self is `to vc`)
    func selfPushAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning?

    @available(*, deprecated, message: "Implement popAnimationController(from:, to:) instead")
    func popAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning?

    // pop animation for `from vc` (self is `to vc`)
    func popAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning?

    // pop animation for `from vc` (self is `from vc`)
    func selfPopAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning?

    // proxy to other CustomNaviAnimation instance
    var animationProxy: CustomNaviAnimation? { get }

    func interactiveTransitioning(with animatedTransitioning: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning?
}

public extension CustomNaviAnimation {
    func pushAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

    func pushAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return pushAnimationController(for: to)
    }

    func selfPushAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

    func popAnimationController(for controller: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

    func popAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return popAnimationController(for: from)
    }

    func selfPopAnimationController(from: UIViewController, to: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }

    var animationProxy: CustomNaviAnimation? { return self }

    func interactiveTransitioning(with animatedTransitioning: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        nil
    }
}

extension UIAlertController {
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }

    open override var shouldAutorotate: Bool {
        return false
    }
}
