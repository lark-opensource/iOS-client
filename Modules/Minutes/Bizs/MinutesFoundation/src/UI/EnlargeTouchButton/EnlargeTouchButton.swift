//
//  MinutesRefreshFooterAnimator.swift
//  MinutesFoundation
//
//  Created by panzaofeng on 2021/2/25.
//

import Foundation

public final class EnlargeTouchButton: UIButton {

    public var enlargeRegionInsets: UIEdgeInsets?

    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
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
}
