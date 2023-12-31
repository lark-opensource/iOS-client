//
//  UDDrawerAbility.swift
//  UniverseDesignDrawer
//
//  Created by 袁平 on 2021/3/12.
//

import UIKit
import Foundation
public protocol UDDrawerAbilityForVC: UIViewController {
    func hideDrawer(animate: Bool, completion: (() -> Void)?)
}

public protocol UDDrawerAbilityForView: UIView {
    func hideDrawer(animate: Bool, completion: (() -> Void)?)
}

public extension UDDrawerAbilityForVC {
    func hideDrawer(animate: Bool, completion: (() -> Void)?) {
        if let drawer = FindAndHideDrawer.findDrawer(fromViewController: self) {
            FindAndHideDrawer.hideDrawer(drawerViewController: drawer, animate: animate, completion: completion)
        }
    }
}

public extension UDDrawerAbilityForView {
    func hideDrawer(animate: Bool, completion: (() -> Void)?) {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                if let drawer = FindAndHideDrawer.findDrawer(fromViewController: viewController) {
                    FindAndHideDrawer.hideDrawer(drawerViewController: drawer, animate: animate, completion: completion)
                }
                return
            }
        }
    }
}

public final class FindAndHideDrawer {
    // 希望找到UDDrawerContainerViewController，找不到返回nil
    public static func findDrawer(fromViewController: UIViewController) -> UDDrawerContainerViewController? {
        var parentVC: UIViewController? = fromViewController
        while let currentVC = parentVC {
            if let drawer = currentVC as? UDDrawerContainerViewController {
                return drawer
            }
            parentVC = currentVC.parent
        }
        return nil
    }

    // 隐藏抽屉
    public static func hideDrawer(drawerViewController: UDDrawerContainerViewController, animate: Bool, completion: (() -> Void)?) {
        drawerViewController.dismiss(animated: animate, completion: completion)
        if !animate {
            drawerViewController.transitionManager?.state = .hidden
        }
    }
}
