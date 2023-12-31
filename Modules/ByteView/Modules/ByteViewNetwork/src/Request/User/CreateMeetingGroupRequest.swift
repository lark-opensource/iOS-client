//
//  CreateMeetingGroupRequest.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2022/11/4.
//

import Foundation
import RustPB

public struct MeetingGroupInfo {
    public var avatarKey: String

    public var isExternal: Bool

    public var topic: String

    public var groupId: String

    public init(avatarKey: String, isExternal: Bool, topic: String, groupId: String) {
        self.avatarKey = avatarKey
        self.isExternal = isExternal
        self.topic = topic
        self.groupId = groupId
    }
}

public struct CreateMeetingGroupRequest {
    public typealias Response = CreateMeetingGroupResponse
    public static let command: NetworkCommand = .rust(.createMeetingGroup)

    public var meetingId: String

    public init(meetingId: String) {
        self.meetingId = meetingId
    }
}

extension CreateMeetingGroupRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_CreateMeetingGroupRequest

    func toProtobuf() throws -> RustPB.Videoconference_V1_CreateMeetingGroupRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        return request
    }
}

public struct CreateMeetingGroupResponse {
    public var groupId: String
    public var meetingGroupInfo: MeetingGroupInfo

}

extension CreateMeetingGroupResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_CreateMeetingGroupResponse

    init(pb: Videoconference_V1_CreateMeetingGroupResponse) throws {
        self.groupId = pb.groupID
        let info = MeetingGroupInfo(avatarKey: pb.meetingGroupInfo.avatarKey, isExternal: pb.meetingGroupInfo.isExternal, topic: pb.meetingGroupInfo.topic, groupId: pb.groupID)
        self.meetingGroupInfo = info
    }

}
