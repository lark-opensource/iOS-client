//
//  UIButton+TouchArea.swift
//  LarkUIKit
//
//  Created by chengzhipeng-bytedance on 2017/6/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

struct AssociatedKeys {
    static var edgeInsets: Int8 = 0
}

extension UIControl {
    public var hitTestEdgeInsets: UIEdgeInsets {
        get {
            guard let edge = objc_getAssociatedObject(self, &AssociatedKeys.edgeInsets) as? UIEdgeInsets else {
                return .zero
            }
            return edge
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.edgeInsets, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if self.hitTestEdgeInsets == .zero || !self.isEnabled || self.isHidden {
            return super.point(inside: point, with: event)
        }

        let relativeFrame = self.bounds
        let hitFrame = relativeFrame.inset(by: self.hitTestEdgeInsets)
        return hitFrame.contains(point)
    }
}
