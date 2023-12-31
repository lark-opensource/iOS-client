//
//  UIBarButtonItem+Docs.swift
//  DocsSDK
//
//  Created by chenjiahao.gill on 2019/3/12.
//  

import Foundation

extension UIBarButtonItem {
    private static var hightlightKey: UInt8 = 0
    var highlightImage: UIImage? {
        get {
            guard let value = objc_getAssociatedObject(self, &UIBarButtonItem.hightlightKey) as? UIImage else {
                return nil
            }
            return value
        }
        set {
            objc_setAssociatedObject(self, &UIBarButtonItem.hightlightKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
