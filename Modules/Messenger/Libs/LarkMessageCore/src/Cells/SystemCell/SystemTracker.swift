//
//  SystemTracker.swift
//  LarkMessageCore
//
//  Created by kongkaikai on 2019/8/15.
//

import Foundation
import Homeric
import LarkCore
import LKCommonsTracker

struct SystemTracker {
    static func trackAtOuterInvite() {
        Tracker.post(TeaEvent(Homeric.MOBILE_AT_GROUP_INVITE_CLICK))
    }

    static func trackUserJoinGroupAutoMute() {
        Tracker.post(TeaEvent(Homeric.BIG_GROUP_MUTED_OPEN_SETTINGS))
    }
}
