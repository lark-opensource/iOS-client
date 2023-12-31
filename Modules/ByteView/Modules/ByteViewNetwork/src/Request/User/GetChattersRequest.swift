//
//  GetChattersRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Contact_V1_MGetChattersRequest
public struct GetChattersRequest {
    public static let command: NetworkCommand = .rust(.mgetChatters)
    public typealias Response = GetChattersResponse

    public init(chatterIds: [String]) {
        self.chatterIds = chatterIds
    }

    public var chatterIds: [String]
}

public struct GetChattersResponse {

    public var chatters: [User]
}

extension GetChattersRequest: RustRequestWithResponse {
    typealias ProtobufType = Contact_V1_MGetChattersRequest
    func toProtobuf() throws -> Contact_V1_MGetChattersRequest {
        var request = ProtobufType()
        request.chatterIds = chatterIds
        return request
    }
}

extension GetChattersResponse: RustResponse {
    typealias ProtobufType = Contact_V1_MGetChattersResponse
    init(pb: Contact_V1_MGetChattersResponse) throws {
        self.chatters = pb.entity.chatters.map({ $0.value.toUser() })
    }
}
