//
//  GroupQRCodePrimaryColorManager.swift
//  LarkChatSetting
//
//  Created by liuxianyu on 2021/9/15.
//

import UIKit
import Foundation
import LarkUIKit

final class GroupQRCodePrimaryColorManager: PrimaryColorManager {
    static let defaultColor = UIColor.ud.bgFloat
    override class var trailKey: String {
        return "_chatsetting_groupinfo_qrcode_blend"
    }
    override class func businessPath() -> String {
        return "LarkChatSetting"
    }
    override class func adjustColorForHSB(_ HSB: (H: CGFloat, S: CGFloat, B: CGFloat)) -> (H: CGFloat, S: CGFloat, B: CGFloat) {
        var S = min(HSB.S, 0.8)
        S = max(HSB.S, 0.5)
        let B = max(min(HSB.B, PrimaryColorManager.minBrightness), PrimaryColorManager.maxBrightness)
        return (H: HSB.H, S: S, B: B)
    }
}
