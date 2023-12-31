//
//  VideoChatCombinedInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Rust-sdk向客户端push 聚合之后的data
/// - PUSH_VIDEO_CHAT_COMBINED_INFO = 2313
/// - Videoconference_V1_VideoChatCombinedInfo
public struct VideoChatCombinedInfo {
    public var inMeetingInfo: VideoChatInMeetingInfo
    public var calendarInfo: CalendarInfo?
}

extension VideoChatCombinedInfo: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VideoChatCombinedInfo
    init(pb: Videoconference_V1_VideoChatCombinedInfo) throws {
        if !pb.hasInMeetingInfo { throw ProtobufCodableError(.decodeFailed, "inMeetingInfo is nil") }
        self.inMeetingInfo = pb.inMeetingInfo.toVcType()
        self.calendarInfo = pb.hasCalendarInfo ? pb.calendarInfo.vcType : nil
    }
}

extension VideoChatCombinedInfo: CustomStringConvertible {
    public var description: String {
        String(indent: "VideoChatCombinedInfo",
               "inMeetingInfo: \(inMeetingInfo)",
               "calendarInfo: \(calendarInfo)"
        )
    }
}
