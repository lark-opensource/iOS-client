//
//  LKBaseNavigationController.swift
//  LarkUIKit
//
//  Created by sniperj on 2020/5/12.
//

import Foundation
import UIKit
import LarkInteraction
import LarkTraitCollection
import LarkSceneManager
import LKCommonsLogging

open class LKBaseNavigationController: UINavigationController {
    public static let logger = Logger.log(LKBaseNavigationController.self, category: "Base.LKBaseNavigationController")

    /// whether doing transition animation（是否正在做转场动画中）
    private var isAnimating = false
    private var isSwipeGestureRecognizerEnabled: Bool {
        return self.topViewController?.naviPopGestureRecognizerEnabled ?? false
    }

    /// 判断是否已经出现过
    private var firstAppeared: Bool = false

    /// 缓存动画过程中正确的 vc 顺序
    var innerViewControllers: [UIViewController]?
    var interactivePopGestureRecognizerObToken: NSKeyValueObservation?

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.interactivePopGestureRecognizer?.isEnabled = self.isSwipeGestureRecognizerEnabled
        Self.logger.info("interactivePopGestureRecognizer init viewDidLoad set \(self.isSwipeGestureRecognizerEnabled)")
        self.interactivePopGestureRecognizer?.delegate = self

        self.interactivePopGestureRecognizerObToken = self.interactivePopGestureRecognizer?.observe(\.isEnabled, options: .new, changeHandler: { _, value in
            Self.logger.info("interactivePopGestureRecognizer isEnabled set \(value.newValue)")
        })
    }

    public override init(navigationBarClass: AnyClass?, toolbarClass: AnyClass?) {
        super.init(
            navigationBarClass: navigationBarClass ?? LarkBaseNaviBar.self,
            toolbarClass: toolbarClass
        )
    }

    public override init(rootViewController: UIViewController) {
        super.init(navigationBarClass: LarkBaseNaviBar.self, toolbarClass: nil)
        self.pushViewController(rootViewController, animated: false)
    }

    public init() {
        super.init(navigationBarClass: LarkBaseNaviBar.self, toolbarClass: nil)
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewWillAppear(_ animated: Bool) {
        if !firstAppeared {
            /// 第一次出现刷新 traitCollection
            self.updateSubTraitCollection()
            firstAppeared = true
        }
        super.viewWillAppear(animated)
    }

    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if self.innerViewControllers != nil {
            self.innerViewControllers = nil
            Self.logger.error("push new viewController but innerViewControllers is not empty")
        }
        // http://t.wtturl.cn/eq2reQC/
        if topViewController == viewController {
            Self.logger.error("push same viewController instance will throw NSException: \(viewController)")
            assertionFailure("push same viewController instance will throw NSException: \(viewController)")
            return
        }
        super.pushViewController(viewController, animated: animated)
        self.updateSubTraitCollection()
    }

    open override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        if animated {
            // 缓存正确的 vc 顺序
            if let first = self.viewControllers.first {
                self.innerViewControllers = [first]
            }
            Self.logger.info("popToRootViewController with animated")
        }
        let result = super.popToRootViewController(animated: animated)
        if let transitionCoordinator = self.transitionCoordinator {
            Self.logger.info("popToRootViewController with animated")
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] (_) in
                // 清除缓存
                Self.logger.info("popToRootViewController with animated completaion")
                self?.innerViewControllers = nil
            }
        } else {
            if animated {
                Self.logger.error("popToRootViewController with animated but not create transitionCoordinator")
                self.innerViewControllers = nil
            }
        }
        return result
    }

    open override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        var currentControllers = self.viewControllers
        let result = super.popToViewController(viewController, animated: animated)
        if animated {
            currentControllers.removeAll { (vc) -> Bool in
                return result?.contains(vc) ?? false
            }
            self.innerViewControllers = currentControllers
            Self.logger.info("popToViewController with animated")
        }

        if let transitionCoordinator = self.transitionCoordinator {
            Self.logger.info("popToViewController with animated")
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] (_) in
                // 清除缓存
                Self.logger.info("popToViewController with animated completaion")
                self?.innerViewControllers = nil
            }
        } else {
            if animated {
                Self.logger.error("popToViewController with animated but not create transitionCoordinator")
                self.innerViewControllers = nil
            }
        }
        return result
    }

    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {

        if animated {
            // 缓存正确的 vc 顺序
            self.innerViewControllers = viewControllers
            Self.logger.info("set viewControllers with animated")
        }
        super.setViewControllers(viewControllers, animated: animated)
        if let transitionCoordinator = self.transitionCoordinator {
            Self.logger.info("set viewControllers with animated")
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] (_) in
                // 清除缓存
                Self.logger.info("set viewControllers with animated completaion")
                self?.innerViewControllers = nil
            }
        } else {
            if animated {
                Self.logger.error("set viewControllers with animated but not create transitionCoordinator")
                self.innerViewControllers = nil
            }
        }
        self.updateSubTraitCollection()
    }

    // 这个值为了保证willTransition（to newTraitCollection)从开始到结束的过程中，traitCollection都用新的
    private var targetTrainCollection: UITraitCollection?

    public override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        targetTrainCollection = newCollection
        self.updateSubTraitCollection()
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            self?.targetTrainCollection = nil
        }
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.updateSubTraitCollection(size: size)
        super.viewWillTransition(to: size, with: coordinator)

        if #available(iOS 12.0, *) {
            return
        }
        /// 修复 iOS 11 中，在非转屏的场景中(切屏，分屏组件全屏操作)
        /// NavigationController 无法传递 viewWillTransition 事件给非 top 的 vc
        /// 无法传递的原因是因为第一次修改 size，并没有真正修改未显示 vc 的 frame size,
        ///  但是调用了它的 viewWillTransition，第二次把 size 改回来，
        ///  navigation 判断 target size 与 vc current size 相同，
        ///  且 coordinator 非转屏触发，则不会再次回调 vc 的 viewWillTransition
        /// 最终导致 vc 只收到了一次 viewWillTransition, 内部逻辑错误

        if coordinator.targetTransform == .identity {
            self.viewControllers.forEach { (vc) in
                if vc != self.topViewController,
                    vc.view.frame.size == size {
                    vc.viewWillTransition(to: size, with: coordinator)
                }
            }
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.updateSubTraitCollection()
    }

    /// 刷新所有子页面的 TraitCollection
    private func updateSubTraitCollection(size: CGSize? = nil) {
        guard needUseCustomTraitCollection() else { return }
        let customTraitCollection = self.customTraitCollection(size: size)
        viewControllers.forEach { (vc) in
            self.setOverrideTraitCollection(customTraitCollection, forChild: vc)
        }
    }

    /// 返回自定义 TraitCollection
    private func customTraitCollection(size: CGSize? = nil) -> UITraitCollection {
        var size = size
        /// 找不到 window 的场景中 证明 vc 还没有展示在视图上
        /// 判断是否 vc 为 window 的 rootVC, 如果是，则使用 window size
        if self.rootWindow() == nil && size == nil {
            size = self.traverseWindow(rootVC: self)?.bounds.size
        }

        return TraitCollectionKit.customTraitCollection(
            targetTrainCollection ?? traitCollection,
            size ?? self.view.bounds.size
        )
    }

    /// 判断是否需要使用自定义 TraitCollection
    /// 在 Navigation 作为 window rootVC 的时候，使用自定义 traitCollection
    private func needUseCustomTraitCollection() -> Bool {
        guard Display.pad else { return false }
        guard let window = self.rootWindow() ??
            traverseWindow(rootVC: self) else {
            return false
        }
        return window.rootViewController == self
    }

    /// 遍历 window 查找 rootVC
    /// 只用于通过 currentWindow 方法找不到 window 的时候使用
    private func traverseWindow(rootVC: UIViewController?) -> UIWindow? {
        return UIApplication.shared.windows.first { (window) -> Bool in
            return window.rootViewController == self
        }
    }
}

extension LKBaseNavigationController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // If you are doing transition animation, do not respond to swipe gestures to avoid freezing screen
        // 如果正在做转场动画，不响应swipe手势，避免出现冻屏现象
        //https://bytedance.feishu.cn/docs/doccnYdREWgMt2ZvKamILKup4Wc#
        if gestureRecognizer is UIScreenEdgePanGestureRecognizer, self.isAnimating {
            Self.logger.info("interactivePopGestureRecognizer gestureRecognizerShouldBegin isAnimating \(self.isAnimating)")
            return false
        }
        Self.logger.info("interactivePopGestureRecognizer gestureRecognizerShouldBegin isSwipeGestureRecognizerEnabled \(self.isSwipeGestureRecognizerEnabled)")
        return self.isSwipeGestureRecognizerEnabled
    }
}

extension LKBaseNavigationController: UINavigationControllerDelegate {
    public func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        if animated {
            Self.logger.info("interactivePopGestureRecognizer willShow set isAnimating true \(viewController)")
            self.isAnimating = true
            // Use the timeout strategy to determine whether the transition animation is over by the timer
            // 使用timeout兜底策略，通过timer来判断转场动画是否结束
            let duration = viewController.transitionCoordinator?.transitionDuration ?? 0
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.isAnimating = false
                Self.logger.info("interactivePopGestureRecognizer willShow set isAnimating false \(viewController)")
            }
        }
    }

    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        // When there is only one VC in the current viewControllers,
        // you need to turn off the interactivePopGestureRecognizer gesture.
        // Otherwise, there will be a frozen screen
        // 当前viewControllers只存在一个vc的时候，需要将interactivePopGestureRecognizer手势关闭，否则会出现冻屏的情况
        //https://bytedance.feishu.cn/docs/doccnYdREWgMt2ZvKamILKup4Wc#
        if self.viewControllers.count <= 1 {
            self.interactivePopGestureRecognizer?.isEnabled = false
            Self.logger.info("navigationController didShow interactivePopGestureRecognizer isEnabled set false by self.viewControllers.count <= 1 \(viewController)")
        } else {
            self.interactivePopGestureRecognizer?.isEnabled = self.isSwipeGestureRecognizerEnabled
            Self.logger.info("navigationController didShow interactivePopGestureRecognizer isEnabled set \(self.isSwipeGestureRecognizerEnabled) \(viewController)")
        }
    }
}

// Add an associated object to viewController to control whether vc supports side slip
// 给viewController添加一个关联对象，用来控制vc是否支持侧滑
private var UIViewController_naviPopGestureRecognizerEnabled = "UIViewController.navi.popGestureRecognizer.enabled"
extension UIViewController {
    public var naviPopGestureRecognizerEnabled: Bool {
        get {
            return objc_getAssociatedObject(self, &UIViewController_naviPopGestureRecognizerEnabled) as? Bool ?? true
        }
        set {
            LKBaseNavigationController.logger.info("naviPopGestureRecognizerEnabled set \(newValue) \(self)")
            objc_setAssociatedObject(self, &UIViewController_naviPopGestureRecognizerEnabled, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

public final class LarkBaseNaviBar: UINavigationBar {

    public override func pushItem(_ item: UINavigationItem, animated: Bool) {
        addPointerInteractionIfNeeded(item)
        super.pushItem(item, animated: animated)
    }

    public override func setItems(_ items: [UINavigationItem]?, animated: Bool) {
        items?.forEach { self.addPointerInteractionIfNeeded($0) }
        super.setItems(items, animated: animated)
    }

    func addPointerInteractionIfNeeded(_ item: UINavigationItem) {
        addPointerInteractionIfNeeded(item.leftBarButtonItem)
        addPointerInteractionIfNeeded(item.rightBarButtonItem)
        item.leftBarButtonItems?.forEach { self.addPointerInteractionIfNeeded($0) }
        item.rightBarButtonItems?.forEach { self.addPointerInteractionIfNeeded($0) }
    }

    func addPointerInteractionIfNeeded(_ item: UIBarButtonItem?) {
        if #available(iOS 13.4, *) {
            guard let item = item,
                  let custom = item.customView,
                  custom.interactions.contains(
                    where: { $0 is UIPointerInteraction }
                  ) else {
                return
            }

            let pointer = PointerInteraction(
                style: .init(
                    effect: .highlight,
                    shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                        guard let view = interaction.view else {
                            return (.zero, 0)
                        }
                        return (CGSize(width: view.bounds.width, height: 36), 8)
                    })
                )
            )
            custom.addLKInteraction(pointer)
        }
    }
}

extension UINavigationController {
    /// 真正的 viewControllers 数组
    public var realViewControllers: [UIViewController] {
        if let nav = self as? LKBaseNavigationController,
           let realVCs = nav.innerViewControllers {
            return realVCs
        }
        return self.viewControllers
    }
}
