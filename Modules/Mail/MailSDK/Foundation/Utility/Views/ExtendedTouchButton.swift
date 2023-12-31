//
//  ExtendedTouchButton.swift
//  MailSDK
//
//  Created by Quanze Gao on 2022/5/31.
//

import UIKit

/// 支持增大 UIButton 响应点击的区域
class ExtendedTouchButton: UIButton {

    var extendedInsets: UIEdgeInsets = .zero

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let extenedBound = bounds.inset(by: extendedInsets)
        if extenedBound.contains(point) {
            return true
        } else {
            return super.point(inside: point, with: event)
        }
    }
}
