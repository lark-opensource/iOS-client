//
//  TabMeetingChangeInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VCTabMeetingChangeInfo
public struct TabMeetingChangeInfo: Equatable {
    public init(changeType: ChangeType, participantChanges: [ParticipantAbbrInfo], meetingInfo: TabHistoryCommonInfo?, audienceInfo: AudienceInfo?) {
        self.changeType = changeType
        self.participantChanges = participantChanges
        self.meetingInfo = meetingInfo
        self.audienceInfo = audienceInfo
    }

    public var changeType: ChangeType

    /// 参会人变更增量信息, 可一次变更多人
    public var participantChanges: [ParticipantAbbrInfo]

    /// 会议基本信息，可直接用于覆盖原有数据
    public var meetingInfo: TabHistoryCommonInfo?

    public var audienceInfo: AudienceInfo?

    public enum ChangeType: Int, Hashable {
        case participant // = 0
        case meeting // = 1
        case audience // = 2
    }
}
