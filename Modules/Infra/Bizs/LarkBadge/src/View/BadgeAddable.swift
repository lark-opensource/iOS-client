//
//  BadgeAddable.swift
//  LarkBadge
//
//  Created by KT on 2019/4/15.
//

import Foundation
import UIKit

/// Represent the `view` that enable to add badge
public protocol BadgeAddable: AnyObject {

    /// The target view to add badge
    var badgeTarget: UIView? { get }

    /// Update
    ///
    /// - Parameter node: 节点树里面查询到的最新node
    func configBadgeView(_ observers: [Observer], with path: [NodeName])
}

// MARK: UIView
extension UIView: BadgeAddable {
    public var badgeTarget: UIView? { return self }
}

// MARK: UIBarButtonItem
extension UIBarButtonItem: BadgeAddable {
    public var badgeTarget: UIView? {
        guard let naviButton = self.value(forKey: "_view") as? UIView else { return nil }
        let systemVersion = (UIDevice.current.systemVersion as NSString).doubleValue
        let controlName = (systemVersion < 11.0 ? "UIImageView" : "UIButton" )
        for subView in naviButton.subviews {
            if subView.isKind(of: NSClassFromString(controlName)!) {
                return subView
            }
        }
        return naviButton
    }
}

// MARK: UITabBarItem
extension UITabBarItem: BadgeAddable {
    public var badgeTarget: UIView? {
        guard let tabButton = self.value(forKey: "_view") as? UIView else { return nil }
        for subView in tabButton.subviews {
            guard let superclass = subView.superclass else { return tabButton }
            if superclass == NSClassFromString("UIImageView") {
                return subView
            }
        }
        return tabButton
    }
}

extension UIView {
    private static var uiBadgeKey: Void?

    /// 绑定BadgeView
    internal var lkBadgeView: BadgeView? {
        get { return objc_getAssociatedObject(self, &UIView.uiBadgeKey) as? BadgeView }
        set { objc_setAssociatedObject(self, &UIView.uiBadgeKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
