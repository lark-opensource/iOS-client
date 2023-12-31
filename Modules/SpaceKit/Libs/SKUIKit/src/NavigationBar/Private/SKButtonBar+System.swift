//
//  SKButtonBar+System.swift
//  SKNavigationBar
//
//  Created by 边俊林 on 2019/11/26.
//

import Foundation

extension SKButtonBar {

    /** Used for UIBarButtonItem.customView, so that we can take away its custom view, and place a pseudo-view back. */
    final class PseudoCustomView: UIView { }

}

extension UIBarButtonItem {

    private static var skCustomViewKey: UInt8 = 0

    var skCustomView: UIView? {
        get { return objc_getAssociatedObject(self, &UIBarButtonItem.skCustomViewKey) as? UIView }
        set { objc_setAssociatedObject(self, &UIBarButtonItem.skCustomViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

}
