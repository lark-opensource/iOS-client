//
//  UIViewController+ActionSheetAdapter.swift
//  LarkUIKit
//
//  Created by Jiayun Huang on 2019/9/18.
//

import Foundation
import UIKit

extension UIViewController {
    private struct AssociatedKeys {
        static var actionSheetAdapterKey = "actionSheetAdapterKey"
    }

    var actionSheetAdapter: ActionSheetAdapter? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.actionSheetAdapterKey) as? ActionSheetAdapter
        }

        set {
            objc_setAssociatedObject(self, &AssociatedKeys.actionSheetAdapterKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // 对外暴露的actionSheetAdapter getter
    public var sheetAdapter: ActionSheetAdapter? {
        return self.actionSheetAdapter
    }
}
