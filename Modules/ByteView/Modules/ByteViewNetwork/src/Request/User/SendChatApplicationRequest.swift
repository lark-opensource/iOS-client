//
//  SendChatApplicationRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/10.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// Im_V1_SendChatApplicationRequest
public struct SendChatApplicationRequest {
    public static let command: NetworkCommand = .rust(.sendChatApplication)
    public init(userId: String, userAlias: String, sender: String, senderId: String,
                sourceId: String, sourceName: String, extraMessage: String) {
        self.userId = userId
        self.userAlias = userAlias
        self.sender = sender
        self.senderId = senderId
        self.sourceId = sourceId
        self.sourceName = sourceName
        self.extraMessage = extraMessage
    }

    /// 联系人用户id
    public var userId: String

    /// 联系人用户设置别名
    public var userAlias: String

    /// 记录用户发送场景和发送携带信息
    public var sender: String

    public var senderId: String

    public var sourceId: String

    /// 来源展示的名称（群聊名称/日程名称/文档名称/会议名称/邮件title等）
    public var sourceName: String

    public var extraMessage: String
}

extension SendChatApplicationRequest: RustRequest {
    typealias ProtobufType = Im_V1_SendChatApplicationRequest
    func toProtobuf() throws -> ProtobufType {
        var request = ProtobufType()
        request.userID = userId
        request.userAlias = userAlias
        request.sender = sender
        request.senderID = senderId
        request.sourceID = sourceId
        request.sourceName = sourceName
        request.subSourceType = ""
        request.source = .vc
        request.extraMessage = extraMessage
        return request
    }
}
