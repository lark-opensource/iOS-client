//
//  GetRoomStatusByShareCodeRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ServerPB

/// - ServerPB_Videochat_GetRoomStatusByShareCodeRequest
public struct GetRoomStatusByShareCodeRequest {
    public static let command: NetworkCommand = .server(.getRoomStatusByShareCode)
    public typealias Response = GetRoomStatusByShareCodeResponse

    public init(shareCode: String) {
        self.shareCode = shareCode
    }

    public var shareCode: String
}

/// - ServerPB_Videochat_GetRoomStatusByShareCodeResponse
public struct GetRoomStatusByShareCodeResponse {
    public var meetingId: String
    public var roomId: String
}

extension GetRoomStatusByShareCodeRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_GetRoomStatusByShareCodeRequest
    func toProtobuf() throws -> ServerPB_Videochat_GetRoomStatusByShareCodeRequest {
        var request = ProtobufType()
        request.shareCode = shareCode
        return request
    }
}

extension GetRoomStatusByShareCodeResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_GetRoomStatusByShareCodeResponse
    init(pb: ServerPB_Videochat_GetRoomStatusByShareCodeResponse) throws {
        self.meetingId = pb.meetingID
        self.roomId = pb.roomID
    }
}
