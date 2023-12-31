//
//  GetSuggestedParticipantsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 获取推荐参会人
/// - Videoconference_V1_GetSuggestedParticipantsRequest
public struct GetSuggestedParticipantsRequest {
    public static let command: NetworkCommand = .rust(.getSuggestedParticipants)
    public typealias Response = GetSuggestedParticipantsResponse

    public init(meetingId: String, includeDecline: Bool, seqID: Int64) {
        self.meetingId = meetingId
        self.includeDecline = includeDecline
        self.seqID = seqID
    }

    public var meetingId: String

    public var includeDecline: Bool
    /// 当前端上记录的最新的 seq_id
    public var seqID: Int64
}

/// - Videoconference_V1_GetSuggestedParticipantsResponse
public struct GetSuggestedParticipantsResponse: CustomNetworkResponse, Equatable {
    public typealias CustomContext = GetSuggestedParticipantsRequest

    public var suggestedParticipants: [Participant]

    public var declinedParticipants: [Participant]

    public var sipRooms: [String: CalendarInfo.CalendarRoom]

    /// 初始拒绝列表人数
    public var initialDeclinedCount: Int64

    public var preSetInterpreterParticipants: [Participant]
    /// 当前新增或更新的拒绝回复人
    public var upsertReplyUsers: [ByteviewUser]
    /// 当前被移除拒绝回复的人
    public var removeReplyUsers: [ByteviewUser]

    /// rust 侧记录的最新 seq_id
    public var seqID: Int64
    /// 当前端上已经是最新的建议参会人
    public var alreadyLatestSuggestion: Bool
}

extension GetSuggestedParticipantsRequest: RustRequestWithCustomResponse {
    typealias ProtobufType = Videoconference_V1_GetSuggestedParticipantsRequest
    func toProtobuf() throws -> Videoconference_V1_GetSuggestedParticipantsRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.includeDecline = includeDecline
        request.seqID = seqID
        return request
    }
}

extension GetSuggestedParticipantsResponse: _CustomNetworkDecodable {
    typealias ProtobufType = Videoconference_V1_GetSuggestedParticipantsResponse
    init(pb: Videoconference_V1_GetSuggestedParticipantsResponse, context: GetSuggestedParticipantsRequest) throws {
        self.suggestedParticipants = pb.suggestedParticipants.map { $0.vcType(meetingID: context.meetingId) }
        self.declinedParticipants = pb.declinedParticipants.map { $0.vcType(meetingID: context.meetingId) }
        self.sipRooms = pb.sipRooms.mapValues { $0.toCalendarRoom() }
        self.initialDeclinedCount = pb.initialDeclinedCount
        self.seqID = pb.seqID
        self.upsertReplyUsers = pb.upsertReplyUsers.map{ $0.vcType }
        self.removeReplyUsers = pb.removeReplyUsers.map{ $0.vcType }
        self.alreadyLatestSuggestion = pb.alreadyLatestSuggestion
        self.preSetInterpreterParticipants = pb.preSetInterpreterParticipants.map { $0.vcType(meetingID: context.meetingId) }
    }
}

extension GetSuggestedParticipantsResponse {
    public func toChanged(meetingId: String) -> InMeetingSuggestedParticipantsChanged {
        InMeetingSuggestedParticipantsChanged(meetingID: meetingId, suggestedParticipants: suggestedParticipants, declinedParticipants: declinedParticipants, sipRooms: sipRooms, initialDeclinedCount: initialDeclinedCount, preSetInterpreterParticipants: preSetInterpreterParticipants, needImmediateUpdate: false)
    }
}
