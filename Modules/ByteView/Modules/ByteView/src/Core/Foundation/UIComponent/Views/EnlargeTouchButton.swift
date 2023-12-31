//
//  EnlargeTouchButton.swift
//  ByteView
//
//  Created by chentao on 2019/10/17.
//

import UIKit

class EnlargeTouchButton: UIButton {

    var enlargeRegionInsets: UIEdgeInsets?

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let insets = enlargeRegionInsets {
            let transformInsets = UIEdgeInsets(top: -insets.top,
                                              left: -insets.left,
                                              bottom: -insets.bottom,
                                              right: -insets.right)
            let region = bounds.inset(by: transformInsets)
            return region.contains(point)
        } else {
            return super.point(inside: point, with: event)
        }
    }

    convenience init(padding: CGFloat) {
        self.init(type: .custom)
        self.enlargeRegionInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }
}

class FixedTouchSizeButton: UIButton {
    var touchSize: CGSize?

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let touchSize = self.touchSize {
            let touchRect = CGRect(origin: CGPoint(x: self.bounds.midX - touchSize.width * 0.5,
                                                   y: self.bounds.midY - touchSize.height * 0.5),
                                   size: touchSize)
            return touchRect.contains(point)
        } else {
            return super.point(inside: point, with: event)
        }
    }
}
