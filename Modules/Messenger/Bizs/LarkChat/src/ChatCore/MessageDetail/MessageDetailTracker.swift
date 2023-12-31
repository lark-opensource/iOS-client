//
//  MessageDetailTracker.swift
//  LarkChat
//
//  Created by 李勇 on 2021/3/22.
//

import Foundation
import Homeric
import LKCommonsTracker

/// MessageDetail模块打点汇总
final class MessageDetailTracker {
    /// 用户点击一次【一键转发】
    static func trackForwardAllMessage() {
        Tracker.post(TeaEvent(Homeric.IM_MESSAGE_THREAD_FORWARD))
    }
}
