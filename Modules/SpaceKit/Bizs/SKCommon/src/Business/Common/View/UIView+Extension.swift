//
//  UIView+Extension.swift
//  Pods
//
//  Created by vvlong on 2018/8/17.
//

import UIKit

extension UIView {
    struct Static {
        static var key = "key"
    }
    public var viewIdentifier: String? {
        get {
            return objc_getAssociatedObject( self, &Static.key ) as? String
        }
        set {
            objc_setAssociatedObject(self, &Static.key, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}
