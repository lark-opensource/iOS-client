//
//  SyncRoomManageRequest.swift
//  ByteViewNetwork
//
//  Created by wulv on 2023/10/17.
//

import Foundation
import ServerPB

/// 会议室控制
/// SYNC_ROOM_MANAGE = 89903
/// ServerPB_Videochat_SyncRoomManageRequest
public struct SyncRoomManageRequest {
    public static let command: NetworkCommand = .server(.syncRoomManage)
    public typealias Response = SyncRoomManageResponse

    public var meetingId: String
    public var bindRoomId: String
    public var action: Action

    public init(meetingId: String, bindRoomId: String, action: Action) {
        self.meetingId = meetingId
        self.bindRoomId = bindRoomId
        self.action = action
    }

    public enum Action: Int {
        case unknown // = 0
        case micMute // = 1
        case micUnmute // = 2
    }
}

extension SyncRoomManageRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_SyncRoomManageRequest
    func toProtobuf() throws -> ServerPB_Videochat_SyncRoomManageRequest {
        var request = ProtobufType()
        request.meetingID = meetingId
        request.bindRoomID = bindRoomId
        request.action = .init(rawValue: action.rawValue) ?? .unknown
        return request
    }
}

/// ServerPB_Videochat_SyncRoomManageResponse
public struct SyncRoomManageResponse {}
extension SyncRoomManageResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_SyncRoomManageResponse
    init(pb: ServerPB_Videochat_SyncRoomManageResponse) throws {}
}
