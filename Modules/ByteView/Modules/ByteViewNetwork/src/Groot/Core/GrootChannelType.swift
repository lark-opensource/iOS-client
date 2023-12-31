//
//  GrootChannelType.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_GrootChannel
public enum GrootChannelType: Int, Hashable {

    /// 1已废弃
    case sketch = 2

    /// channelID为shareFollowID，associateID为meetingID
    case follow = 5

    /// channelID为userID，无需填写associateID
    case vcTabUserChannel = 7

    /// channelID为meetingID, 无需填写associateID
    case vcTabMeetingChannel = 8

    /// channelID为userID+用户时区，associateID为userID
    case vcTabListChannel = 9

    /// channelID为whiteboardID
    case newWhiteBoardChannel = 11

    /// channelID为userID，无需填写associateID
    case vcNoticeChannel = 12

    /// channelID为shareID，associateID为meetingID，与follow=5相比，允许增量patches
    case followChannelV2 = 13
}

extension GrootChannelType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sketch:
            return "sketch"
        case .follow:
            return "follow"
        case .vcTabUserChannel:
            return "vcTabUserChannel"
        case .vcTabMeetingChannel:
            return "vcTabMeetingChannel"
        case .vcTabListChannel:
            return "vcTabListChannel"
        case .newWhiteBoardChannel:
            return "newWhiteBoardChannel"
        case .vcNoticeChannel:
            return "vcNoticeChannel"
        case .followChannelV2:
            return "followChannelV2"
        }
    }
}
