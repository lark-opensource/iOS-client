//
//  CalendarPrimaryColorManager.swift
//  Calendar
//
//  Created by Hongbin Liang on 4/17/23.
//

import Foundation
import LarkUIKit

final class CalendarPrimaryColorManager: PrimaryColorManager {

    override class var trailKey: String {
        return "calendar_detail"
    }

    override class func businessPath() -> String {
        return "vc_calendar"
    }

    override class func adjustColorForHSB(_ HSB: (H: CGFloat, S: CGFloat, B: CGFloat)) -> (H: CGFloat, S: CGFloat, B: CGFloat) {
        var S = min(HSB.S, 0.8)
        S = max(HSB.S, 0.5)
        let B = max(min(HSB.B, PrimaryColorManager.minBrightness), PrimaryColorManager.maxBrightness)
        return (H: HSB.H, S: S, B: B)
    }
}
