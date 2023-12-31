//
//  DragItem.swift
//  LarkInteraction
//
//  Created by 李晨 on 2020/3/23.
//

import UIKit
import Foundation

extension UIDragItem {
    private struct AssociatedKeys {
        static var itemResult = "ui.drag.item.result"
    }

    var liItemResult: Result<DropItemValue, Error>? {
        get {
            if let itemValue = objc_getAssociatedObject(
                self,
                &AssociatedKeys.itemResult
            ) as? Result<DropItemValue, Error> {
                return itemValue
            }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.itemResult, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
