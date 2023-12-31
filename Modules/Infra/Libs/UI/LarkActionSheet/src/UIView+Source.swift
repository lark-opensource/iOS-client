//
//  UIView+Source.swift
//  LarkUIKit
//
//  Created by Jiayun Huang on 2019/9/11.
//

import UIKit
import Foundation

public struct ActionSheetAdapterSource {
    let sourceView: UIView
    let sourceRect: CGRect
    let arrowDirection: UIPopoverArrowDirection
    /// 用于配置popover箭头背景色
    var backgroundColor: UIColor?

    public init(sourceView: UIView, sourceRect: CGRect, arrowDirection: UIPopoverArrowDirection, backgroundColor: UIColor? = nil) {
        self.sourceView = sourceView
        self.sourceRect = sourceRect
        self.arrowDirection = arrowDirection
        self.backgroundColor = backgroundColor
    }
}

public extension UIView {
    var defaultSource: ActionSheetAdapterSource {
        return ActionSheetAdapterSource(sourceView: self, sourceRect: bounds, arrowDirection: .unknown)
    }
}
