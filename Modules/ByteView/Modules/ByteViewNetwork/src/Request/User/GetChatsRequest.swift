//
//  GetChatsRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Im_V1_MGetChatsRequest
public struct GetChatsRequest {
    public static let command: NetworkCommand = .rust(.mgetChats)
    public typealias Response = GetChatsResponse

    public init(chatIds: [String]) {
        self.chatIds = chatIds
    }

    public var chatIds: [String]
}

/// Im_V1_MGetChatsResponse
public struct GetChatsResponse {

    public var chats: [Chat]
}

extension GetChatsRequest: RustRequestWithResponse {
    typealias ProtobufType = Im_V1_MGetChatsRequest
    func toProtobuf() throws -> Im_V1_MGetChatsRequest {
        var request = ProtobufType()
        request.chatIds = chatIds
        request.shouldAuth = true
        return request
    }
}

extension GetChatsResponse: RustResponse {
    typealias ProtobufType = Im_V1_MGetChatsResponse
    init(pb: Im_V1_MGetChatsResponse) throws {
        self.chats = pb.entity.chats.map({ $0.value.vcType })
    }
}
