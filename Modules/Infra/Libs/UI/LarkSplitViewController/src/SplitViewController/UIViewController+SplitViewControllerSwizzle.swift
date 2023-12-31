//
//  UIViewController+SplitViewControllerSwizzle.swift
//  LarkSplitViewController
//
//  Created by Yaoguoguo on 2022/9/5.
//

import UIKit
import Foundation
import AnimatedTabBar

extension UIViewController {
    @objc
    static func lkSplitViewControllerSetupTababr() {
        guard UIDevice.current.userInterfaceIdiom != .phone else {
            return
        }
        AnimatedTabbarConfig.customNeedShowTabbar = { (vc) -> Bool? in
            if let customSplitVC = vc.larkSplitViewController {
                if let result = customSplitVC.isCustomShowTabBar(vc) {
                    return result
                }
            }
            return nil
        }

        AnimatedTabbarConfig.customNeedHandleTabbarLayout = { (vc) -> Bool in
            if let detail = vc.larkSplitViewController?.secondaryViewController, detail == vc {
                return true
            }
            return false
        }
    }

    @objc
    static func splitViewControllerSwizzleMethod() {
        guard UIDevice.current.userInterfaceIdiom != .phone else {
            return
        }

        let swizzlingSet: [(Selector, Selector)] = [
            (#selector(UIViewController.present(_:animated:completion:)), #selector(UIViewController.splitvc_present(_:animated:completion:))),
            (#selector(UIViewController.viewWillAppear(_:)), #selector(UIViewController.splitvc_viewWillAppear(_:))),
            (#selector(UIViewController.viewWillTransition(to:with:)), #selector(UIViewController.splitvc_viewWillTransition(to:with:)))
        ]

        swizzlingSet.forEach { (value) in
            let originalSelector = value.0
            let swizzledSelector = value.1
            swizzling(
                forClass: UIViewController.self,
                originalSelector: originalSelector,
                swizzledSelector: swizzledSelector
            )
        }
    }
}

extension UIViewController {
    @objc
    func splitvc_present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        splitvc_present(viewControllerToPresent, animated: flag, completion: completion)
        // fix: https://jira.bytedance.com/browse/SUITE-53271
        // to mark presented vc, first mark vcs in splitvc
        larkSplitViewController?.markChildrenIdentifier()

        let modalPresentationStyle = viewControllerToPresent.modalPresentationStyle
        guard modalPresentationStyle == .overCurrentContext || modalPresentationStyle == .currentContext,
        !viewControllerToPresent.childrenIdentifier.contains(.initial) else {
            /// 只有 present 在左栏 or 右栏的情况才处理
            viewControllerToPresent.childrenIdentifier.splitViewController = larkSplitViewController
            return
        }
        viewControllerToPresent.childrenIdentifier = childrenIdentifier
        viewControllerToPresent.childrenIdentifier.splitViewController = larkSplitViewController
    }

    @objc
    func splitvc_viewWillAppear(_ animated: Bool) {
        updateSecondaryOnlyButtonItemIfNeeded()
        observeNewSplitVCSplitModeChange()
        autoLeaveFullScreenIfNeeded()
        updateSplitSecondaryGestureEnable()

        splitvc_viewWillAppear(animated)
    }

    @objc
    func splitvc_viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        splitvc_viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { (_) in
            self.updateSecondaryOnlyButtonItemIfNeeded()
            self.observeNewSplitVCSplitModeChange()
        }
    }

    // 自动处理拖拽条的显隐逻辑
    func updateSplitSecondaryGestureEnable() {
        if let split = self.larkSplitViewController,
           split != self {
            var needCheck = false
            if let navigation = self.navigationController,
               split.viewController(for: .secondary) == navigation,
               self.parent == navigation {
                needCheck = true
            }
            if split.viewController(for: .secondary) == self,
               !(self is UINavigationController) {
                needCheck = true
            }
            if needCheck {
                split.isShowPanGestureView = self.supportSecondaryPanGesture
            }
        }
    }

    // 处理自动退出全屏的逻辑
    func autoLeaveFullScreenIfNeeded() {
        if let split = self.larkSplitViewController,
           split != self,
           let navigation = self.navigationController,
           self.parent == navigation {
            // 右侧全屏的情况
            if split.splitMode == .secondaryOnly,
               split.viewController(for: .secondary) == navigation,
               !self.supportSecondaryOnly {
                split.updateSplitMode(.twoOverSecondary, animated: true)
            }
        }
    }

    // 自动添加 item
    func updateSecondaryOnlyButtonItemIfNeeded() {
        if let split = self.larkSplitViewController,
           split != self,
           let navigation = self.navigationController,
           self.parent == navigation,
           self.supportSecondaryOnlyButton {
            /// 自动添加 item 场景 更新 items
            if self.autoAddSecondaryOnlyItem {
                if navigation == split.sideWrapperNavigation {
                    /// 删除全屏 item
                    if let leftBarButtonItems = self.navigationItem.leftBarButtonItems,
                       !leftBarButtonItems.isEmpty {
                        var items = leftBarButtonItems
                        if let index = items.firstIndex(where: { (item) -> Bool in
                            return item == self.secondaryOnlyButtonItem
                        }) {
                            items.remove(at: index)
                        }
                        if let index = items.firstIndex(where: { (item) -> Bool in
                            return item == self.autoBackBarButtonItem
                        }) {
                            items.remove(at: index)
                        }
                        if let index = items.firstIndex(where: { (item) -> Bool in
                            return item == self.autoBackSpaceItem
                        }) {
                            items.remove(at: index)
                        }
                        self.navigationItem.leftBarButtonItems = items
                    } else if let leftBarButtonItem = self.navigationItem.leftBarButtonItem {
                        if leftBarButtonItem == self.secondaryOnlyButtonItem {
                            self.navigationItem.leftBarButtonItem = nil
                        }
                    }
                } else if navigation == split.secondaryNavigation {
                    /// 添加全屏 item
                    if let leftBarButtonItems = self.navigationItem.leftBarButtonItems,
                       !leftBarButtonItems.isEmpty {

                        if !leftBarButtonItems.contains(self.secondaryOnlyButtonItem) {
                            var items = leftBarButtonItems
                            items.append(self.autoBackSpaceItem)
                            items.append(self.secondaryOnlyButtonItem)
                            self.navigationItem.leftBarButtonItems = items
                        }
                    } else if let leftBarButtonItem = self.navigationItem.leftBarButtonItem {
                        if leftBarButtonItem != self.secondaryOnlyButtonItem {
                            self.navigationItem.leftBarButtonItems = [
                                leftBarButtonItem,
                                self.autoBackSpaceItem,
                                self.secondaryOnlyButtonItem
                            ]
                        }
                    } else {
                        if navigation.viewControllers.first == self {
                            self.navigationItem.leftBarButtonItem = self.secondaryOnlyButtonItem
                        } else {
                            self.navigationItem.leftBarButtonItems = [
                                self.autoBackBarButtonItem,
                                self.autoBackSpaceItem,
                                self.secondaryOnlyButtonItem
                            ]
                        }
                    }
                }
            }

            /// 更新 full screen item
            self.secondaryOnlyButtonItem.updateSplitState()
        }
    }

    private func observeNewSplitVCSplitModeChange() {
        guard let split = self.larkSplitViewController else { return }
        if let old = self.splitSplitMode {
            if old != split.splitMode {
                self.splitSplitMode = split.splitMode
                self.splitVCSplitModeChange(split: split)
                self.splitSplitModeChange(splitMode: split.splitMode)
            }
        } else {
            self.splitSplitMode = split.splitMode
        }
    }

    /// split改版过一次，有的业务方用的方法一，有的业务方用的方法二，所以在调用时只要调用下述方法的任意一个就可以
    /// 监听 splitVC display mode 变化
    @objc
    open func splitVCSplitModeChange(split: SplitViewController) {
    }

    /// 新版splitVC display mode 变化
    @objc
    open func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
    }
}

private func swizzling(
    forClass: AnyClass,
    originalSelector: Selector,
    swizzledSelector: Selector) {
    guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
        let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
            return
    }
    if class_addMethod(
        forClass,
        originalSelector,
        method_getImplementation(swizzledMethod),
        method_getTypeEncoding(swizzledMethod)
        ) {
        class_replaceMethod(
            forClass,
            swizzledSelector,
            method_getImplementation(originalMethod),
            method_getTypeEncoding(originalMethod)
        )
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
