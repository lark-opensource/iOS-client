//
//  MeetingMinutesBadgeService.swift
//  LarkMessengerInterface
//
//  Created by zhaojiachen on 2022/1/11.
//

import Foundation
import LarkBadge

public enum MeetingMinutesBadgeStatus: String {
    case none = "static"//无红点
    case unread = "new"//未读（红点）
    case editing = "edit"//正在编辑（笔）
}

public protocol MeetingMinutesBadgeService {
    var meetingMinutesStatus: MeetingMinutesBadgeStatus { get }
    func startMonitorMeetingSummaryBadge()
}
