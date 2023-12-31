//
//  VideoChatExtraInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import ByteViewCommon

/// 不会影响到状态机核心逻辑的数据推送
/// - NOTIFY_VIDEO_CHAT_EXTRA = 2306
/// - Videoconference_V1_VideoChatExtraInfo
/// 注意：此推送为后端推给rust，rust将更新内容放入到VideoChatCombinedInfo，然后全量推给端上
/// 所以端上对于VideoChatExtraInfo的推送，无需单独监听VideoChatExtraInfo，用VideoChatCombinedInfo的推送就行
public struct VideoChatExtraInfo {

    public var type: VideoChatExtraInfoType

    /// action产生时间
    public var actionTime: MeetingActionTime

    public var ringingReceivedData: RingingReceivedData?

    public var inMeetingData: [InMeetingData]

    public var subtitle: MeetingSubtitleData?

    public var liveExtraInfo: LiveExtraInfo?

    public var transcripts: [MeetingSubtitleData]

    public enum VideoChatExtraInfoType: Int, Hashable {
        case ringingReceived = 1
        case inMeetingChanged // = 2
        case subtitle // = 3
        case updateLiveExtraInfo // = 4
        case transcript // = 5
    }

    public struct RingingReceivedData: Equatable {
        public init(meetingID: String, participant: Participant) {
            self.meetingID = meetingID
            self.participant = participant
        }

        /// 会议id
        public var meetingID: String

        /// 收到ringing的参与者
        public var participant: Participant
    }

    public struct LiveExtraInfo: Equatable {
        public init(onlineUsersCount: Int32) {
            self.onlineUsersCount = onlineUsersCount
        }

        /// 直播在线观看用户数
        public var onlineUsersCount: Int32
    }
}

extension VideoChatExtraInfo: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VideoChatExtraInfo
    init(pb: Videoconference_V1_VideoChatExtraInfo) throws {
        guard let type = VideoChatExtraInfoType(rawValue: pb.type.rawValue) else {
            throw ProtobufCodableError(.notSupported, "type not supported: \(pb.type)")
        }
        if type == .inMeetingChanged {
            let data = pb.inMeetingData.filter({ $0.type == .liveMeeting }).compactMap({ try? InMeetingData(pb: $0) })
            if data.isEmpty {
                throw ProtobufCodableError(.emptyMessage)
            }
            self.inMeetingData = data
        } else {
            self.inMeetingData = []
        }
        self.type = type
        self.actionTime = pb.actionTime.vcType
        self.ringingReceivedData = pb.hasRingingReceivedData ? pb.ringingReceivedData.vcType : nil
        self.subtitle = pb.hasSubtitle ? pb.subtitle.vcType : nil
        self.liveExtraInfo = pb.hasLiveExtraInfo ? pb.liveExtraInfo.vcType : nil
        self.transcripts = pb.transcriptList.map({ $0.vcType })
    }
}

extension VideoChatExtraInfo: CustomStringConvertible {
    public var description: String {
        String(indent: "VideoChatExtraInfo",
               "type: \(type)",
               "time: \(actionTime)",
               "ring: \(ringingReceivedData)",
               "changes: \(inMeetingData)",
               "subtitle: \(subtitle)",
               "live: \(liveExtraInfo)"
        )
    }
}
