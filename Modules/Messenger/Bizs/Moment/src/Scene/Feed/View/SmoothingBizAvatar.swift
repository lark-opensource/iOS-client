//
//  SmoothingBizAvatar.swift
//  Moment
//
//  Created by bytedance on 2021/9/7.
//

import Foundation
import UIKit
import LarkBizAvatar
import FigmaKit

final class SmoothingBizAvatar: BizAvatar {
    private var radius: CGFloat = 8
    private var smoothness: CornerSmoothLevel = .max
    func setSmoothCorner(radius: CGFloat,
                         smoothness: CornerSmoothLevel) {
        self.radius = radius
        self.smoothness = smoothness
        self.layer.ux.setMask(by: .squircle(forRect: self.bounds, cornerRadius: radius, roundedCorners: .allCorners, cornerSmoothness: smoothness))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateCorner()
    }
    private func updateCorner() {
        self.layer.ux.removeMask()
        self.layer.ux.setMask(by: .squircle(forRect: self.bounds, cornerRadius: radius, roundedCorners: .allCorners, cornerSmoothness: smoothness))
    }
}
