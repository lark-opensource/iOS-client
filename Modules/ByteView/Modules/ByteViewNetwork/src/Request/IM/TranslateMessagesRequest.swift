//
//  TranslateMessagesRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 描述：翻译消息
/// - 返回值不含信息，翻译结果走推送
/// - TRANSLATE_VC_MESSAGES = 89381
/// - Videoconference_V1_TranslateVCMessagesRequest
public struct TranslateMessagesRequest {
    public static let command: NetworkCommand = .rust(.translateVcMessages)

    public init(containerId: String, source: TranslateSource, contexts: [TranslateContext], role: Participant.MeetingRole) {
        self.containerId = containerId
        self.source = source
        self.contexts = contexts
        self.role = role
    }

    /// 消息所属容器的id，可以是meeting_id, breakout_room_id
    public var containerId: String

    ///1.手动翻译 2.自动翻译
    public var source: TranslateSource

    ///翻译消息需要的信息
    public var contexts: [TranslateContext]

    public var role: Participant.MeetingRole
}

/// 翻译消息需要的上下文
/// - Videoconference_V1_VCTranslateContext
public struct TranslateContext {
    public init(messageId: String, targetLanguage: String, displayRule: TranslateDisplayRule) {
        self.messageId = messageId
        self.targetLanguage = targetLanguage
        self.displayRule = displayRule
    }

    ///消息id
    public var messageId: String

    ///翻译的目标语言
    public var targetLanguage: String

    ///目标消息展示规则
    public var displayRule: TranslateDisplayRule
}

extension TranslateContext: ProtobufEncodable {
    typealias ProtobufType = Videoconference_V1_VCTranslateContext
    func toProtobuf() -> Videoconference_V1_VCTranslateContext {
        var pb = ProtobufType()
        pb.messageID = messageId
        pb.targetLanguage = targetLanguage
        pb.displayRule = .init(rawValue: displayRule.rawValue) ?? .unknownRule
        return pb
    }
}

extension TranslateMessagesRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_TranslateVCMessagesRequest
    func toProtobuf() throws -> Videoconference_V1_TranslateVCMessagesRequest {
        var request = ProtobufType()
        request.containerID = containerId
        request.translateSource = .init(rawValue: source.rawValue) ?? .unknownTranslateSource
        request.translateContexts = contexts.map({ $0.toProtobuf() })
        request.role = role.pbType
        return request
    }
}
