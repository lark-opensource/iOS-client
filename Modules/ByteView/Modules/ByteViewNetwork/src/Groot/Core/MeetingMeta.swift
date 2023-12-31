//
//  MeetingMeta.swift
//  ByteViewNetwork
//
//  Created by Prontera on 2022/4/19.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_MeetingMeta
public struct MeetingMeta {

    /// meeting id 必填，即使在分组会议中。
    public var meetingID: String

    public var breakoutRoomID: String?

    public init(meetingID: String,
                breakoutRoomID: String? = nil) {
        self.meetingID = meetingID
        self.breakoutRoomID = breakoutRoomID
    }
}
