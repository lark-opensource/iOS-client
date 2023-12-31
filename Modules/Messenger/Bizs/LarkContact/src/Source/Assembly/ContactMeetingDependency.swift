//
//  ContactMeetingDependency.swift
//  LarkContact
//
//  Created by JackZhao on 2021/4/12.
//

import Foundation
import LarkMessengerInterface

public protocol ContactMeetingDependency {
    /// 通过会议 Number 加入会议
    ///
    /// - Parameters:
    ///     - meetNumber: 默认会议号
    ///     - entrySource: 入口来源
    func joinMeetingByNumber(meetingNumber: String, entrySource: ChatMeetingSource)
}
