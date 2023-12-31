//
//  MyAIAnswerFeedbackBody.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/7/7.
//

import Foundation
import UIKit
import EENavigator
import LarkLocalizations

/// MyAI踩反馈原因配置：https://cloud.bytedance.net/appSettings-v2/detail/config/181006/detail/basic
public struct AIFeedbackConfig {
    public struct FeedbackReason: Hashable {
        public let id: String
        /// 所有语言对应的文案列表
        private var nameMap: [String: String] = [:]
        /// 英文，用作兜底
        private var enName: String = ""
        /// 获取当前语言文案
        public var name: String { self.nameMap[LanguageManager.currentLanguage.rawValue] ?? self.enName }

        public init(reason: [String: Any]) {
            self.id = (reason["id"] as? String) ?? ""
            // 解析多国语言文案
            if let names = reason["name"] as? [String: String] {
                self.nameMap = names
                self.enName = names[Lang.en_US.rawValue] ?? ""
            }
        }

        /// Hashable
        public static func == (lhs: FeedbackReason, rhs: FeedbackReason) -> Bool { lhs.id == rhs.id }
        public func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    public static let key = "myai_feedback_config"

    public private(set) var reasons: [FeedbackReason] = []

    public init?(stringDic: [String: Any]?) {
        guard let stringDic = stringDic else { return nil }
        guard let reasonArray = stringDic["dislike_reasons"] as? [[String: Any]] else { return nil }

        self.reasons = reasonArray.map({ FeedbackReason(reason: $0) })
    }
}

/// AI回答反馈弹窗路由
public struct MyAIAnswerFeedbackBody: PlainBody {
    public static var pattern: String = "//client/myaianswer/feedback"

    /// 这两个参数是点踩请求时，服务端返回的
    public let aiMessageId: String
    public let scenario: String
    /// 在哪个场景发送的点踩行为
    public enum Mode {
        /// InlineMode点踩：CCM等场景
        /// 1.queryMessageRawdata：我提问题的内容
        /// 2.ansMessageRawdata：MyAI回复的内容
        case inlineMode(queryMessageRawdata: String, ansMessageRawdata: String)
        /// 会话内点踩：MyAI主分会场
        /// 1.queryMessageID：我提问的消息id
        /// 2.ansMessageID：MyAI回复的消息id
        case chatMode(queryMessageID: String, ansMessageID: String)
    }
    public let mode: MyAIAnswerFeedbackBody.Mode

    public init(aiMessageId: String, scenario: String, mode: MyAIAnswerFeedbackBody.Mode) {
        self.aiMessageId = aiMessageId
        self.scenario = scenario
        self.mode = mode
    }
    
    //TODO.chensi 废弃字段
    public var answerId: String = ""
    public init(answerId: String) {
        self.answerId = answerId
        self.aiMessageId = ""
        self.scenario = ""
        self.mode = .chatMode(queryMessageID: "", ansMessageID: "")
    }
}

// 浮窗模式AI回答反馈数据
public struct LarkInlineAIFeedbackConfig {
    
    /// true: 点赞
    /// false: 点踩
    public let isLike: Bool
    
    public let aiMessageId: String
    
    public let scenario: String
    
    public let queryRawdata: String
    
    public let answerRawdata: String
    
    public init(isLike: Bool, aiMessageId: String, scenario: String, queryRawdata: String, answerRawdata: String) {
        self.isLike = isLike
        self.aiMessageId = aiMessageId
        self.scenario = scenario
        self.queryRawdata = queryRawdata
        self.answerRawdata = answerRawdata
    }
}
