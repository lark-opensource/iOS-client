//
//  MeetingJoinInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_MeetingJoinInfo
public struct MeetingJoinInfo {
    public init(meetingID: String, joinStatus: JoinStatus) {
        self.meetingID = meetingID
        self.joinStatus = joinStatus
    }

    public var meetingID: String

    public var joinStatus: JoinStatus

    public enum JoinStatus: Int, Hashable {
        case unknown // = 0
        case joined // = 1
        case waiting // = 2
        case joinable // = 3
        case end // = 4
    }
}
