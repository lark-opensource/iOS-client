//
//  ContentSize.swift
//  LarkUIKit
//
//  Created by Saafo on 2021/12/9.
//
//  preferredContentSize 优化
//  文档：https://bytedance.feishu.cn/wiki/wikcnnnuo4mPXfOpMazS684N6xb

import Foundation
import LarkSetting
import LKCommonsLogging
import UIKit

extension FeatureGatingManager.Key {
    static let contentSizeImproveKey: Self = "mobile.ipad.core.content_size_improve"
}

// MARK: Extension properties

private var UIViewController_rememberContentSizeEnabled = "UIViewController_rememberContentSizeEnabled"
extension UIViewController {
    /// Modal View DidLoad 时，是否在未设置 contentSize 时记住当前大小
    public var rememberContentSizeEnabled: Bool {
        get { objc_getAssociatedObject(self, &UIViewController_rememberContentSizeEnabled) as? Bool ?? false }
        set {
            guard ContentSizeImprover.swizzleContentSizeMethodIfNeeded() else { return }
            objc_setAssociatedObject(self, &UIViewController_rememberContentSizeEnabled, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

// MARK: Swizzle

extension UIViewController {
    @objc
    func swizzled_viewDidAppear(animated: Bool) {
        swizzled_viewDidAppear(animated: animated)
        rememberContentSizeIfNeeded()
    }

    private func rememberContentSizeIfNeeded() {
        guard self.rememberContentSizeEnabled &&
                !type(of: self).isSubclass(of: UINavigationController.self) &&
                navigationController?.modalPresentationStyle == .formSheet &&
                view.window?.traitCollection.horizontalSizeClass == .regular &&
                preferredContentSize == .zero else { return }
        var navigationBarHeight: CGFloat = 0
        if !(navigationController?.isNavigationBarHidden ?? true) &&
            [.all, .top].contains(edgesForExtendedLayout) &&
            navigationController?.navigationBar.isTranslucent ?? false {
            navigationBarHeight = navigationController?.navigationBar.bounds.height ?? 0
        }
        var toolBarHeight: CGFloat = 0
        if !(navigationController?.isToolbarHidden ?? true) &&
            [.all, .bottom].contains(edgesForExtendedLayout) &&
            navigationController?.toolbar.isTranslucent ?? false {
            toolBarHeight = navigationController?.toolbar.bounds.height ?? 0
        }
        let preferredHeight = view.bounds.height - navigationBarHeight - toolBarHeight
        preferredContentSize = CGSize(width: view.bounds.width, height: preferredHeight)
        ContentSizeImprover.logger.info("UIViewController: \(String(describing: self)) ContentSize set to: \(preferredContentSize)")
    }
}

// MARK: swizzle tool

private final class ContentSizeImprover {
    static let logger = Logger.log(ContentSizeImprover.self, category: "ContentSizeImprover")

    static var shouldImproveContentSize: Bool = {
        return Display.pad && FeatureGatingManager.shared.featureGatingValue(with: .contentSizeImproveKey)//Global 纯UI相关，成本比较大，先不改
    }()
    static var swizzledContentSize: Bool = false

    /// - Returns: should continue
    static func swizzleContentSizeMethodIfNeeded() -> Bool {
        guard shouldImproveContentSize else { return false }
        guard swizzledContentSize == false else { return true }
        defer { swizzledContentSize = true }
        swizzling(forClass: UIViewController.self,
                  originalSelector: #selector(UIViewController.viewDidAppear(_:)),
                  swizzledSelector: #selector(UIViewController.swizzled_viewDidAppear(animated:)))
        logger.info("swizzledContentSizeMethods!")
        return true
    }

    private static func swizzling(
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
}
