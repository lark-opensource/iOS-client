//
//  PassThroughStackView.swift
//  SKUIKit
//
//  Created by Weston Wu on 2023/9/27.
//

import UIKit

open class PassThroughStackView: UIStackView {
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard super.point(inside: point, with: event) else { return false }
        for subview in subviews {
            guard !subview.isHidden, subview.alpha > 0, subview.isUserInteractionEnabled else {
                continue
            }
            let pointInSubview = convert(point, to: subview)
            if subview.point(inside: pointInSubview, with: event) {
                return true
            }
        }
        return false
    }
}
