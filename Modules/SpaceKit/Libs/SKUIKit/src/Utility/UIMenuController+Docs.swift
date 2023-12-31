//
//  UIMenuController+Docs.swift
//  SKUIKit
//
//  Created by zengsenyuan on 2022/4/27.
//  


import Foundation
import SKFoundation


extension UIMenuController: DocsExtensionCompatible {}

public extension DocsExtension where BaseType == UIMenuController {
    
    func showMenu(from targetView: UIView, rect targetRect: CGRect) {
        if #available(iOS 13.0, *) {
            base.showMenu(from: targetView, rect: targetRect)
        } else {
            base.setTargetRect(targetRect, in: targetView)
            base.setMenuVisible(true, animated: true)
        }
    }

    func hideMenu() {
        if #available(iOS 13.0, *) {
            base.hideMenu()
        } else {
            base.setMenuVisible(false, animated: true)
        }
    }
}
