//
//  UIWindow+WaterMark.swift
//  LarkWaterMark
//
//  Created by 李晨 on 2021/4/22.
//

import UIKit
import Foundation

private var uiWindowWaterMark: Void?
private var uiWindowRemoteView: Void?

extension UIWindow {

    @objc public var waterMarkImageView: WaterMarkView? {
        get {
            return objc_getAssociatedObject(self, &uiWindowWaterMark) as? WaterMarkView
        }
        set(newValue) {
            objc_setAssociatedObject(self, &uiWindowWaterMark, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc dynamic public var remoteViewCount: NSInteger {
        get {
            return objc_getAssociatedObject(self, &uiWindowRemoteView) as? NSInteger ?? 0
        }
        set(newValue) {
            willChangeValue(for: \.remoteViewCount)
            objc_setAssociatedObject(self, &uiWindowRemoteView, newValue, .OBJC_ASSOCIATION_ASSIGN)
            didChangeValue(for: \.remoteViewCount)
        }
    }
}
