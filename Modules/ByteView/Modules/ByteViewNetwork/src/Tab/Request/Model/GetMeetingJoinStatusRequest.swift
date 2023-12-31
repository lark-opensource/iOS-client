//
//  GetMeetingJoinStatusRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 获取会议可加入详情
/// - GET_VC_MEETING_JOIN_STATUS = 89210
/// - Videoconference_V1_GetVcMeetingJoinStatusRequest
public struct GetMeetingJoinStatusRequest {
    public static let command: NetworkCommand = .rust(.getVcMeetingJoinStatus)
    public typealias Response = GetMeetingJoinStatusResponse
    public static let defaultOptions: NetworkRequestOptions? = [.shouldPrintResponse]

    public init() {}
}

/// 最多返回一个正在进行的会议，在已经加入/等候会议室。
/// - PUSH_VC_MEETING_JOIN_STATUS = 89345
/// - Videoconference_V1_GetVcMeetingJoinStatusResponse
public struct GetMeetingJoinStatusResponse {

    public var meetingJoinInfos: MeetingJoinInfo
}

extension GetMeetingJoinStatusRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetVcMeetingJoinStatusRequest
    func toProtobuf() throws -> Videoconference_V1_GetVcMeetingJoinStatusRequest {
        ProtobufType()
    }
}

extension GetMeetingJoinStatusResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetVcMeetingJoinStatusResponse

    init(pb: Videoconference_V1_GetVcMeetingJoinStatusResponse) {
        self.meetingJoinInfos = pb.meetingJoinInfos.vcType
    }
}
