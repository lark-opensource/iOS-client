//
//  GetMessagePositionRequest.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2023/2/15.
//

import Foundation
import RustPB

public struct GetMessagePositionRequest {
    public typealias Response = GetMessagePositionResponse
    public static let command: NetworkCommand = .rust(.getVcChatMessagePosition)

    public init() {
    }
}

extension GetMessagePositionRequest: RustRequestWithResponse {
    typealias ProtobufType = Videoconference_V1_GetVCChatMessagePositionRequest

    func toProtobuf() throws -> RustPB.Videoconference_V1_GetVCChatMessagePositionRequest {
        return ProtobufType()
    }
}

public struct GetMessagePositionResponse {
    public init() {
    }
}

extension GetMessagePositionResponse: RustResponse {
    typealias ProtobufType = Videoconference_V1_GetVCChatMessagePositionResponse

    init(pb: RustPB.Videoconference_V1_GetVCChatMessagePositionResponse) throws {
    }
}
