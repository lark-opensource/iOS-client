//
//  CallContentTracker.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/10/14.
//

import Foundation
import Homeric
import LKCommonsTracker

final class CallContentTracker {
    /// 会话内点击重拨
    static func chatCallPhoneClickRecall() {
        Tracker.post(TeaEvent(Homeric.CHAT_CALL_PHONE_CLICK_RECALL))
    }

    /// 会话内点击回拨
    static func chatCallPhoneClickCallback() {
        Tracker.post(TeaEvent(Homeric.CHAT_CALL_PHONE_CLICK_CALLBACK))
    }
}
