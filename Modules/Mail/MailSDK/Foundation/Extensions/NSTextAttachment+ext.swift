//
//  NSAttachMent.swift
//  DocsSDK
//
//  Created by huahuahu on 2019/1/14.
//

import Foundation

extension NSTextAttachment {

    private static var additionalInfoKey: UInt8 = 0
    var additionalInfo: AnyObject? {
        get {
            return objc_getAssociatedObject(self, &NSTextAttachment.additionalInfoKey) as AnyObject
        }
        set {
            objc_setAssociatedObject(self, &NSTextAttachment.additionalInfoKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
