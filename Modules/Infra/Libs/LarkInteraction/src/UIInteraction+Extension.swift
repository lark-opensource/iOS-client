//
//  UIInteraction+Extension.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/18.
//

import UIKit
import Foundation

extension UIDragSession {
    /// 是否存在 item 符合 typeIdentifier 类型数据
    public func hasItemConformingTo(typeIdentifier: String) -> Bool {
        for item in self.items {
            if item.itemProvider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                return true
            }
        }
        return false
    }

    /// 是否存在 item 不符合 typeIdentifier 类型数据
    public func hasItemNotConformingTo(typeIdentifier: String) -> Bool {
        for item in self.items {
            if !item.itemProvider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                return true
            }
        }
        return false
    }
}

extension UIDropSession {
    /// 是否是当前 App 的拖拽操作
    public func isCurrentApplication() -> Bool {
        return localDragSession != nil
    }
}
