//
//  KeyCommandProvider.swift
//  LarkKeyCommandKit
//
//  Created by 李晨 on 2020/2/5.
//

import UIKit
import Foundation

/// KeyCommandProvider 是快捷键提供者
@objc
public protocol KeyCommandProvider {
    /// 返回当前 provider 提供的 keyBindings
    func keyBindings() -> [KeyBindingWraper]

    /// 返回当前 provider 提供的 sub provider 数组
    func subProviders() -> [KeyCommandProvider]
}

/// KeyCommandContainer 是快捷键容器
/// KeyCommandContainer 和 KeyCommandProvider 的区别是
/// KeyCommandContainer 主要指 VC, 它会自动寻找子容器的逻辑
@objc
public protocol KeyCommandContainer: KeyCommandProvider {
    func keyCommandContainers() -> [KeyCommandContainer]
}

extension UIResponder: KeyCommandProvider {
    open func keyBindings() -> [KeyBindingWraper] {
        return []
    }

    open func subProviders() -> [KeyCommandProvider] {
        return []
    }
}

extension UIViewController: KeyCommandContainer {

    open func keyCommandContainers() -> [KeyCommandContainer] {
        // 优先判断 presentedViewController
        // 如果存在，则不返回当前 container
        if let present = self.presentedViewController {
            return present.keyCommandContainers()
        }

        // 获取 container 闭包
        // 内部逻辑是会返回 container 与 指定 childVC 的 keyCommandContainers
        let containerBlock: ([UIViewController]) -> [KeyCommandContainer] = { (children) -> [KeyCommandContainer] in
            return children.reduce([self]) { (containers, vc) -> [KeyCommandContainer] in
                return containers + vc.keyCommandContainers()
            }
        }

        // TabbarVC 使用 selectedViewController
        if let tab = self as? UITabBarController {
            if let selectedViewController = tab.selectedViewController {
                return containerBlock([selectedViewController])
            } else {
                return containerBlock([])
            }
        }

        // SplitVC 使用 viewControllers
        if let split = self as? UISplitViewController {
            return containerBlock(split.viewControllers)
        }

        // Navigation 使用 topViewController
        if let nav = self as? UINavigationController {
            if let topViewController = nav.topViewController {
                return containerBlock([topViewController])
            } else {
                return containerBlock([])
            }
        }

        // 普通 VC 使用自身的 children
        return containerBlock(self.children)
    }
}
