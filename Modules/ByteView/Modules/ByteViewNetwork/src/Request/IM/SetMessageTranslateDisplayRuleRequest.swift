//
//  SetMessageTranslateDisplayRuleRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// -  SET_VC_MANUALLY_MESSAGE_TRANSLATE_DISPLAY_RULE = 89372
/// - Videoconference_V1_SetVCManuallyMessageTranslateDisplayRuleRequest
public struct SetMessageTranslateDisplayRuleRequest {
    public static let command: NetworkCommand = .rust(.setVcManuallyMessageTranslateDisplayRule)

    public init(messageId: String, displayRule: TranslateDisplayRule) {
        self.messageId = messageId
        self.displayRule = displayRule
    }

    /// 需要设置的消息 id，因为是手动设置的，考虑直接用单个id
    public var messageId: String

    /// 设置的消息的记录id
    public var displayRule: TranslateDisplayRule
}

extension SetMessageTranslateDisplayRuleRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_SetVCManuallyMessageTranslateDisplayRuleRequest
    func toProtobuf() throws -> Videoconference_V1_SetVCManuallyMessageTranslateDisplayRuleRequest {
        var request = ProtobufType()
        request.messageID = messageId
        request.displayRule = .init(rawValue: displayRule.rawValue) ?? .unknownRule
        return request
    }
}
