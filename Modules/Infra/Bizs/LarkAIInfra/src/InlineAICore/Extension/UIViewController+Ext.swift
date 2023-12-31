//
//  UIViewController+Ext.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/7/3.
//  


import Foundation

extension UIViewController {
    var isFormSheet: Bool {
        if let root = self.navigationController, root.children.first?.modalPresentationStyle == .formSheet ||
            root.modalPresentationStyle == .formSheet {
            return true
        } else if self.modalPresentationStyle == .formSheet {
            return true
        } else {
            return false
        }
    }
    func isMyWindowRegularSize() -> Bool {
        return isMyWindowUISizeClass(.regular)
    }
    func isMyWindowCompactSize() -> Bool {
        return isMyWindowUISizeClass(.compact)
    }
    func isMyWindowUISizeClass(_ sizeClass: UIUserInterfaceSizeClass) -> Bool {
        var traitCollection: UITraitCollection?
        if let trait = view.window?.traitCollection {
            traitCollection = trait
        } else if let trait = self.presentingViewController?.view.window?.traitCollection {
            traitCollection = trait
        }
        return traitCollection?.horizontalSizeClass == sizeClass
    }
}
