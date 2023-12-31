//
//  Associate.swift
//  LarkUIExtensionWrapper
//
//  Created by 李晨 on 2020/3/10.
//

import Foundation

private struct AssociatedKeys {
    static var dirtyTag = "Lark.UIExtension.Dirty.Tag"
}

extension BindEnableObject {
    /// 标记 object 需要被更新
    public var ueDirtyTag: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.dirtyTag) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.dirtyTag, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
