//
//  ReplyViewModel.swift
//  Calendar
//
//  Created by zhouyuan on 2018/11/9.
//  Copyright © 2018 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import EventKit
import LarkUIKit

struct ReplyViewModel: ReplyViewContent {
    var ekEvent: EKEvent?
    var showJoinButton: Bool
    var canJoinEvent: Bool
    var isReplyed: Bool
    var showReplyEntrance: Bool
    var rsvpStatusString: String?
    var status: ReplyStatus?

    init(status: ReplyStatus) {
        self.status = status
        self.showJoinButton = false
        self.canJoinEvent = false
        self.isReplyed = false
        self.showReplyEntrance = false
    }

}
