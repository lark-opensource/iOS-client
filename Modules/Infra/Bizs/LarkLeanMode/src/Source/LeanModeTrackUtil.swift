//
//  LeanModeTrackUtil.swift
//  LarkLeanMode
//
//  Created by 袁平 on 2020/3/16.
//

import Foundation
import Homeric
import LKCommonsTracker

final class LeanModeTrackUtil {
    static func attemptOpenLeanMode() {
        Tracker.post(TeaEvent(Homeric.LEAN_MODE_TURNON_ATTEMPT))
    }

    static func confirmOpenLeanMode(syncAllDevice: Bool) {
        Tracker.post(TeaEvent(Homeric.LEAN_MODE_TURNON_CONFIRMED,
                              params: ["all_devices": syncAllDevice ? "y" : "n"]))
    }

    static func attemptCloseLeanMode() {
        Tracker.post(TeaEvent(Homeric.LEAN_MODE_TURNOFF_ATTEMPT))
    }

    static func securityPwdVerifySuccess() {
        Tracker.post(TeaEvent(Homeric.LEAN_MODE_TURNOFF_CONFIRMED))
    }

    static func closeAllDevice() {
        Tracker.post(TeaEvent(Homeric.LEAN_MODE_TURNOFF_CONFIRMED_ALL_DEVICES))
    }

    static func closeCurrentDevice() {
        Tracker.post(TeaEvent(Homeric.LEAN_MODE_TURNOFF_CONFIRMED_CURRENT_DEVICE))
    }
}
