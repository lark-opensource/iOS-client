//
//  SetMessageAutoDetectStateRequest.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

/// 会中消息自动翻译检测
/// - SET_VC_MESSAGE_AUTO_DETECT_STATE = 89373
/// - Videoconference_V1_SetVCMessageAutoDetectStateRequest
public struct SetMessageAutoDetectStateRequest {
    public static let command: NetworkCommand = .rust(.setVcMessageAutoDetectState)

    public init(isAutoTranslate: Bool, targetLanguage: String, displayRule: TranslateDisplayRule, displayArea: TranslateDisplayArea, messageIds: [String]) {
        self.isAutoTranslate = isAutoTranslate
        self.targetLanguage = targetLanguage
        self.displayRule = displayRule
        self.displayArea = displayArea
        self.messageIds = messageIds
    }

    /// 表示全局配置里是否自动开启翻译
    public var isAutoTranslate: Bool

    /// 用户配置的翻译 目标语言
    public var targetLanguage: String

    /// 用户配置的自动翻译展示规则
    public var displayRule: TranslateDisplayRule

    /// 自动翻译展示场景
    public var displayArea: TranslateDisplayArea

    /// 由端上判断，所有可感知的消息列表
    /// 即，所有需要进行自动检测的消息列表。
    public var messageIds: [String]
}

extension SetMessageAutoDetectStateRequest: RustRequest {
    typealias ProtobufType = Videoconference_V1_SetVCMessageAutoDetectStateRequest
    func toProtobuf() throws -> Videoconference_V1_SetVCMessageAutoDetectStateRequest {
        var request = ProtobufType()
        request.isAutoTranslate = isAutoTranslate
        request.targetLanguage = targetLanguage
        request.displayRule = .init(rawValue: displayRule.rawValue) ?? .unknownRule
        request.displayArea = .init(rawValue: displayArea.rawValue) ?? .chatbox
        request.messageIds = messageIds
        return request
    }
}
