//
//  LarkSplitViewController+Extension.swift
//  LarkSplitViewController
//
//  Created by Yaoguoguo on 2022/11/1.
//

import UIKit
import Foundation

/// Default VC Protocol
public protocol DefaultDetailVC: UIViewController {
}
/// Default VC PorviderResult Model
public struct DefaultVCResult {
    public var defaultVC: DefaultDetailVC
    public var wrap: UINavigationController.Type?

    public init(defaultVC: DefaultDetailVC, wrap: UINavigationController.Type? = nil) {
        self.defaultVC = defaultVC
        self.wrap = wrap
    }

    func wrapVC() -> UIViewController {
        if let wrap = self.wrap {
            return wrap.init(rootViewController: defaultVC)
        }
        return defaultVC
    }
}

extension SplitViewController {

    public var sideNavigationController: UINavigationController? {
        return isCollapsed ? compactNavigation : self.sideWrapperNavigation
    }

    public var contentNavigationController: UINavigationController? {
        if isCollapsed {
            return compactNavigation
        }
        if self.splitMode == .sideOnly {
            return sideNavigationController
        }
        return self.secondaryNavigation
    }

    public var primaryViewController: UIViewController? {
        guard hasViewController(for: .primary) else { return nil }
        return self.viewController(for: .primary)
    }

    public var compactViewController: UIViewController? {
        return self.viewController(for: .compact)
    }

    public var supplementaryViewController: UIViewController? {
        guard hasViewController(for: .supplementary) else { return nil }
        return self.viewController(for: .supplementary)
    }

    public var secondaryViewController: UIViewController? {
        guard hasViewController(for: .secondary) else { return nil }
        return self.viewController(for: .secondary)
    }

    public var contentSize: CGSize {
        return self.contentView.bounds.size
    }

    // 退出当前topVC
    // 先获取最顶层VC，根据所属Navi退出topVC
    public func popTopViewController(animated: Bool) {
        if checkNavigationInTransition(completion: { [weak self] in
            self?.popTopViewController(animated: animated)
        }) {
            return
        }
        guard let vc = self.topViewController() else {
            return
        }
        var navigation: UINavigationController?
        if let nav = vc as? UINavigationController {
            navigation = nav
        } else if let nav = vc.navigationController {
            navigation = nav
        }
        guard let navi = navigation else { return }
        guard navi == self.sideWrapperNavigation ||
                navi == self.secondaryNavigation  ||
                navi == self.compactNavigation else {
            return
        }

        if navi.viewControllers.count > 1 {
            navi.popViewController(animated: false)
        } else {
            navi.children.forEach { vc in
                vc.view.removeFromSuperview()
                vc.removeFromParent()
            }
            if let result = self.defaultVCProvider?() {
                navi.setViewControllers([result.defaultVC], animated: false)
                self.setViewController(navi, for: .secondary)
            }
        }
    }

    public func topViewController() -> UIViewController? {
        return topMost
    }

    private func hasViewController(for column: Column) -> Bool {
        guard let vc = self.viewController(for: column) else { return false }
        if vc as? DefaultDetailVC != nil {
            return false
        }

        if let navi = vc as? UINavigationController, navi.viewControllers.last as? DefaultDetailVC != nil {
            return false
        }
        return true
    }
}
