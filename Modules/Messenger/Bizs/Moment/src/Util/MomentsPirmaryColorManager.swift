//
//  MomentsPirmaryColorManager.swift
//  Moment
//
//  Created by liluobin on 2021/5/1.
//

import Foundation
import UIKit
import LarkUIKit

final class MomentsPirmaryColorManager: PrimaryColorManager {
    static let defaultColor = UIColor.ud.color(127.5, 127.5, 127.5, 0.8)
    override class var trailKey: String {
        return "_moments_category_detail_blend_v2"
    }
    override class func businessPath() -> String {
        return "Moments"
    }
    override class func adjustColorForHSB(_ HSB: (H: CGFloat, S: CGFloat, B: CGFloat)) -> (H: CGFloat, S: CGFloat, B: CGFloat) {
        var S = min(HSB.S, 0.8)
        S = max(HSB.S, 0.5)
        let B = max(min(HSB.B, PrimaryColorManager.minBrightness), PrimaryColorManager.maxBrightness)
        return (H: HSB.H, S: S, B: B)
    }

}
