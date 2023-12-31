//
//  UIWindow+Extensions.swift
//  EETroubleKiller
//
//  Created by Meng on 2019/6/12.
//

import Foundation
import UIKit

extension UIWindow {

    static func sortedAsce(_ lhs: UIWindow, _ rhs: UIWindow) -> Bool {
        return lhs.windowLevel.rawValue > rhs.windowLevel.rawValue
    }

    static func sortedDesc(_ lhs: UIWindow, _ rhs: UIWindow) -> Bool {
        return lhs.windowLevel.rawValue < rhs.windowLevel.rawValue
    }

    static func sortedVisibleAsce(_ lhs: UIWindow, _ rhs: UIWindow) -> Bool {
        return sortedAsce(lhs, rhs) && lhs.visible
    }

}

extension UIWindow {

    private static var tkNameKey: Void?

    public var captureName: String {
        get {
            return objc_getAssociatedObject(self, &UIWindow.tkNameKey) as? String ?? ""
        }

        set {
            objc_setAssociatedObject(self, &UIWindow.tkNameKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

}
