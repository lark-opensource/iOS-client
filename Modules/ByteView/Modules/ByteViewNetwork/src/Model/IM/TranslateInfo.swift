//
//  ImTranslate.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/7.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VCTranslateInfo
public struct TranslateInfo {

    /// 消息容器ID（会议或讨论组ID）
    public var containerID: String

    public var messageID: String

    /// 翻译的目标语言
    public var language: String

    /// 当err_code不为默认值时，意味着翻译失败，需恢复消息原状
    public var errCode: TranslateErrorCode

    /// 1.手动翻译 2.自动翻译
    public var translateSource: TranslateSource

    /// 原文&译文展示规则
    public var displayRule: TranslateDisplayRule

    /// 展示区域：消息气泡或消息列表页
    public var displayArea: TranslateDisplayArea

    /// 消息对应的类型，根据类型来获取对应结构的content
    public var messageType: VideoChatInteractionMessage.TypeEnum

    public var content: VideoChatInteractionMessageContent?

    public var textContent: TextMessageContent? {
        if case .textContent(let v) = content {
            return v
        }
        return nil
    }

    public var reactionContent: ReactionMessageContent? {
        if case .reactionContent(let v) = content {
            return v
        }
        return nil
    }

    public var systemContent: SystemMessageContent? {
        if case .systemContent(let v) = content {
            return v
        }
        return nil
    }

    public enum TranslateErrorCode: Int, Hashable {
        case unknown // = 0

        /// 翻译服务异常
        case internalError // = 1

        /// 主语言和翻译语言一致
        case sameLanguage // = 2

        /// 不支持的翻译语言
        case unsupportedLanguage // = 3

        /// 不支持的消息类型
        case unsupportedMessageType // = 4

        /// 超时未获取到翻译结果
        case timeout // = 5
    }
}

extension TranslateInfo: CustomStringConvertible {
    public var description: String {
        String(indent: "TranslateInfo",
               "containerId: \(containerID)",
               "messageId: \(messageID)",
               "language: \(language)",
               "errCode: \(errCode)",
               "translateSource: \(translateSource)",
               "displayRule: \(displayRule)",
               "displayArea: \(displayArea)",
               "messageType: \(messageType)"
        )
    }
}
