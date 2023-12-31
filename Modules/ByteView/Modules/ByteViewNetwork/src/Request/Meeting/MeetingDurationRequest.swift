//
//  MeetingDurationRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - ADJUEST_MEETING_DURATION
/// - Videoconference_V1_AdjustMeetingDurationRequest
public struct MeetingDurationRequest {
    public static let command: NetworkCommand = .rust(.adjuestMeetingDuration)
    public typealias Response = MeetingDurationResponse

    public init(meetingId: String) {
        self.meetingId = meetingId
    }

    public var meetingId: String
}

/// - Videoconference_V1_AdjustMeetingDurationResponse
public struct MeetingDurationResponse {

    /// in milliseccond
    public var meetingStartTime: Int64

    public var requestBeginTime: Int64

    public var requestEndTime: Int64

    public var meetingDuration: Int64

    /// - 计算公式见 https://bytedance.feishu.cn/docs/doccn1k6QEb4xL1VRgLagFrgVsh#
    public func duration(since startTime: Date) -> TimeInterval {
        let clientDuration = Date().timeIntervalSince(startTime)
        let serverDuration = Double(self.requestEndTime - self.requestBeginTime) / 1000
        let updatedTime = (clientDuration - serverDuration) / 2
        let updatedMeetingDuration = Double(self.meetingDuration) / 1000 + updatedTime
        return updatedMeetingDuration
    }
}

extension MeetingDurationRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_AdjustMeetingDurationRequest
    func toProtobuf() throws -> Videoconference_V1_AdjustMeetingDurationRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        return request
    }
}

extension MeetingDurationResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_AdjustMeetingDurationResponse
    init(pb: Videoconference_V1_AdjustMeetingDurationResponse) throws {
        self.meetingStartTime = pb.meetingStartTime
        self.requestBeginTime = pb.requestBeginTime
        self.requestEndTime = pb.requestEndTime
        self.meetingDuration = pb.meetingDuration
    }
}
