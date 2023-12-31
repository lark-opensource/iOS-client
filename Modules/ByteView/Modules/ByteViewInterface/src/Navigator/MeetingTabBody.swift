//
//  MeetingTabBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/30.
//

import Foundation

/// /client/vctab/open
public struct MeetingTabBody: CodablePathBody {
    public static let path = "/client/vctab/open"

    public let source: Source
    public let action: Action
    public let meetingID: String?

    public init(source: Source, action: Action, meetingID: String?) {
        self.source = source
        self.action = action
        self.meetingID = meetingID
    }

    public enum Source: String, Codable {
        case chat // 消息机器人卡片
        case onboarding = "onboarding_task"
        case callkit
    }

    public enum Action: String, Codable {
        case detail // 打开会议详情
        case opentab // 打开独立tab
    }
}
