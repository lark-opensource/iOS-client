//
//  SetTranscriptFilterRequest.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2023/6/21.
//

import Foundation
import RustPB

/// SET_TRANSCRIPT_FILTER = 88025; 转录过滤
public struct SetTranscriptFilterRequest {
    public static let command: NetworkCommand = .rust(.setTranscriptFilter)

    public init(users: [ByteviewUser]) {
        self.users = users
    }

    /// 传入要过滤用户数组；若要清除过滤，传入空数组
    public var users: [ByteviewUser]
}

extension SetTranscriptFilterRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_SetTranscriptFilterRequest
    func toProtobuf() throws -> Videoconference_V1_SetTranscriptFilterRequest {
        var request = ProtobufType()
        request.users = users.map({ $0.pbType })
        return request
    }
}
