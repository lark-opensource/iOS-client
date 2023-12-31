//
//  GetVCMyAIInitInfoRequest.swift
//  ByteViewNetwork
//
//  Created by 陈乐辉 on 2023/7/12.
//

import Foundation
import ServerPB

/// COMMAND GET_VC_MY_AI_INIT_INFO = 94001
public struct GetVCMyAIInitInfoRequest {
    public static let command: NetworkCommand = .server(.getVcMyAiInitInfo)
    public typealias Response = GetVCMyAIInitInfoResponse

    let meetingID: String
    let linkURL: String

    public init(meetingID: String, linkURL: String) {
        self.meetingID = meetingID
        self.linkURL = linkURL
    }
}

extension GetVCMyAIInitInfoRequest: RustRequestWithResponse {
    typealias ProtobufType = ServerPB_Videochat_my_ai_GetVCMyAIInitInfoRequest
    func toProtobuf() throws -> ServerPB_Videochat_my_ai_GetVCMyAIInitInfoRequest {
        var request = ProtobufType()
        request.meetingID = meetingID
        request.linkURL = linkURL
        return request
    }
}

public struct GetVCMyAIInitInfoResponse {
    public var chatID: String
    public var aiChatModeID: String
}

extension GetVCMyAIInitInfoResponse: RustResponse {
    typealias ProtobufType = ServerPB_Videochat_my_ai_GetVCMyAIInitInfoResponse

    init(pb: ServerPB_Videochat_my_ai_GetVCMyAIInitInfoResponse) throws {
        self.chatID = pb.chatID
        self.aiChatModeID = pb.aiChatModeID
    }
}
