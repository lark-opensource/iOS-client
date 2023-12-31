//
//  SetSubtitlesFilterRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// - Videoconference_V1_SetSubtitlesFilterRequest
public struct SetSubtitlesFilterRequest {
    public static let command: NetworkCommand = .rust(.setSubtitlesFilter)
    public typealias Response = SetSubtitlesFilterResponse

    public init(users: [ByteviewUser], breakoutRoomId: String?) {
        self.users = users
        self.breakoutRoomId = breakoutRoomId
    }

    /// 传入要过滤用户数组；若要清除过滤，传入空数组
    public var users: [ByteviewUser]

    public var breakoutRoomId: String?
}

/// - Videoconference_V1_SetSubtitlesFilterResponse
public struct SetSubtitlesFilterResponse {
    public init(breakoutRoomId: String) {
        self.breakoutRoomId = breakoutRoomId
    }

    public var breakoutRoomId: String
}

extension SetSubtitlesFilterRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_SetSubtitlesFilterRequest
    func toProtobuf() throws -> Videoconference_V1_SetSubtitlesFilterRequest {
        var request = ProtobufType()
        request.users = users.map({ $0.pbType })
        if let id = RequestUtil.normalizedBreakoutRoomId(breakoutRoomId) {
            request.breakoutRoomID = id
        }
        return request
    }
}

extension SetSubtitlesFilterResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_SetSubtitlesFilterResponse
    init(pb: Videoconference_V1_SetSubtitlesFilterResponse) throws {
        self.breakoutRoomId = pb.breakoutRoomID
    }
}
