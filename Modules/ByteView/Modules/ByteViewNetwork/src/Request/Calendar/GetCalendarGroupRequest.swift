//
//  GetCalendarGroupRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// 获取要跳转日程群组（如果没有群会创建群）
/// - GET_CALENDAR_GROUP
/// - ServerPB_Videochat_GetCalendarGroupRequest
public struct GetCalendarGroupRequest {
    public static let command: NetworkCommand = .server(.getCalendarGroup)
    public typealias Response = GetCalendarGroupResponse

    public init(meetingID: String, autoCreate: Bool) {
        self.meetingID = meetingID
        self.autoCreate = autoCreate
    }

    /// meeting id
    public var meetingID: String

    public var autoCreate: Bool
}

/// Videoconference_V1_GetCalendarGroupResponse
public struct GetCalendarGroupResponse {

    /// 创建成功就不为nil，不成功为nil
    public var groupID: String

    public var getCalGroupStatus: GetCalendarGroupStatus

    public enum GetCalendarGroupStatus: Int, Hashable {
        case unknown // = 0
        case getGroupSuccess // = 1
        case getGroupFailed // = 2
        case getGroupNotCreated // = 3
        case getGroupNotPermitted // = 4
    }
}

extension GetCalendarGroupRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetCalendarGroupRequest
    func toProtobuf() -> ServerPB_Videochat_GetCalendarGroupRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        request.autoCreate = autoCreate
        return request
    }
}

extension GetCalendarGroupResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetCalendarGroupResponse
    init(pb: ServerPB_Videochat_GetCalendarGroupResponse) throws {
        self.groupID = pb.groupID
        self.getCalGroupStatus = .init(rawValue: pb.getCalGroupStatus.rawValue) ?? .unknown
    }
}
