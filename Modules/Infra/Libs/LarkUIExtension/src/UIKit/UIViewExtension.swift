//
//  UIViewExtension.swift
//  LarkUIExtensionWrapper
//
//  Created by 李晨 on 2020/3/10.
//

import UIKit
import Foundation

extension UIView {
    public func needUpdateByBindValue() -> Bool {
        return self.window != nil
    }
}
