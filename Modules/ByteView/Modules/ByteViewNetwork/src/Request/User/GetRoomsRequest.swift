//
//  GetRoomsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 客户端从rust-sdk拉取room_info
/// - MGET_ROOMS = 2322
/// - Videoconference_V1_MGetRoomsRequest
public struct GetRoomsRequest {
    public static let command: NetworkCommand = .rust(.mgetRooms)
    public typealias Response = GetRoomsResponse

    public init(roomIds: [String]) {
        self.roomIds = roomIds
    }

    public var roomIds: [String]
}

/// - Videoconference_V1_MGetRoomsResponse
public struct GetRoomsResponse {

    public var rooms: [Room]
}

extension GetRoomsRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_MGetRoomsRequest
    func toProtobuf() throws -> Videoconference_V1_MGetRoomsRequest {
        var request = ProtobufType()
        request.roomIds = roomIds
        return request
    }
}

extension GetRoomsResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_MGetRoomsResponse
    init(pb: Videoconference_V1_MGetRoomsResponse) throws {
        self.rooms = pb.rooms.map({ $0.value.vcType })
    }
}
