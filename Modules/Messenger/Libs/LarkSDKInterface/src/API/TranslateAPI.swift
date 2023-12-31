//
//  TranslateAPI.swift
//  LarkSDKInterface
//
//  Created by 姚启灏 on 2018/8/2.
//

import Foundation
import LarkModel
import RxSwift
import RustPB

public enum EntityType: Int {
    case other = 0
    case message = 1
}

public protocol TranslateAPI {
    /// 翻译URL Inline
    /// isAutoTranslate: 是否自动翻译；true: 自动触发翻译，false: 手动触发翻译
    func translateURLInlines(inlineContexts: [URLInlineContext], isAutoTranslate: Bool) -> Observable<RustPB.Basic_V1_TranslateMessageUrlPreviewsResponse>

    /// 手动翻译一些消息
    func manualTranslate(contexts: [MessageContext], isFromMessageUpdate: Bool) -> Observable<RustPB.Im_V1_TranslateMessagesV3Response>

    /// 自动检测一些消息
    func autoTranslate(contexts: [MessageContext], isFromMessageUpdate: Bool) -> Observable<RustPB.Im_V1_TranslateMessagesV3Response>

    /// 获取消息主语言
    func getMessageLanguage(messageIds: [String]) -> Observable<[String: String]>

    /// 检测图片是否可翻译
    func detectImageTranslationAbility(imageKeys: [String]) -> Observable<[ImageTranslationAbility]>

    /// 翻译图片
    func translateImages(entityId: String?,
                         entityType: EntityType?,
                         translateScene: Im_V1_ImageTranslateScene,
                         imageKeyInfos: [String: Bool],
                         targetLanguage: String?) -> Observable<TranslateImageKeysResponse>

    /// 通过实体和译图信息换取原图信息
    /// note: 因为server不作设计原译图索引，因此rust提供了这条链路来获取原图映射
    func getOriginImageContext(entityId: String,
                               entityType: EntityType,
                               translateImageKey: String) -> Observable<GetOriginImageContextResponse>

    /// 发送翻译反馈
    // swiftlint:disable all
    func sendTranslateFeedback(scene: RustPB.Ai_V1_TranslationScene,
                               score: Int,
                               originText: String,
                               targetText: String,
                               hasSuggestText: Bool,
                               suggestText: String,
                               editSuggestText: Bool,
                               originLanguage: String,
                               targetLanguage: String,
                               objectID: String?) -> Observable<Void>
    // swiftlint:enable all
}

/// URL Inline翻译请求参数
public struct URLInlineContext {
    public var previewID: String
    public var title: String?
    public var tag: String?
    // 是否SDK抓取的预览
    public var isSDKPreview: Bool
    /// 希望翻译成什么语言
    public var manualTargetLanguage: String?

    public init(previewID: String,
                title: String?,
                tag: String?,
                isSDKPreview: Bool,
                manualTargetLanguage: String?) {
        self.previewID = previewID
        self.title = title
        self.tag = tag
        self.isSDKPreview = isSDKPreview
        self.manualTargetLanguage = manualTargetLanguage
    }

    public func translateContext() -> Basic_V1_TranslateUrlPreviewContext {
        var reqContext = Basic_V1_TranslateUrlPreviewContext()
        reqContext.previewID = previewID
        if let title = title { reqContext.title = title }
        if let tag = tag { reqContext.tag = tag }
        reqContext.isSdkPreview = isSDKPreview
        if let language = self.manualTargetLanguage { reqContext.targetLanguage = language }
        return reqContext
    }
}

/// 翻译请求参数
public struct MessageContext {
    /// 待翻译消息id
    public var messageID: String = ""
    /// 待翻译消息相关上下文
    public var messageSource: MessageSource = MessageSource()
    /// 希望该消息翻译成什么语言
    public var manualTargetLanguage: String?
    /// 该消息在哪个chat里
    public var chatID: String = ""
    /// 消息版本
    public var messageContentVersion: Int32 = 0

    public init() {}

    /// 转成翻译请求所需的model
    public func translateContext() -> Im_V1_TranslateMessageContext {
        var tempContext = Im_V1_TranslateMessageContext()
        tempContext.messageID = self.messageID
        tempContext.messageSource = {
            var source = Basic_V1_MessageSource()
            source.sourceID = self.messageSource.sourceID
            source.sourceType = self.messageSource.sourceType
            source.messageIDPath = self.messageSource.messageIDPath
            return source
        }()
        if let language = self.manualTargetLanguage { tempContext.manualTargetLanguage = language }
        tempContext.chatID = self.chatID
        tempContext.messageContentVersion = messageContentVersion
        return tempContext
    }
}

/// 翻译message传入的相关上下文
public struct MessageSource {
    /// mergeForward代表合并转发详情页，common代表其他的所有场景
    public var sourceType: RustPB.Basic_V1_MessageSourceType = .commonMessage
    /// common表示自身消息id，mergeForward表示父消息id
    public var sourceID: String = ""
    /// mergeForward时有值，表示父消息
    public var sourceMessage: Message?

    // mergeFroward时表示子消息的path
    public var messageIDPath: [String] = []

    /// 快速构造一个通用场景，id为最外层消息id
    public static func common(id: String) -> MessageSource {
        var source = MessageSource()
        source.sourceType = .commonMessage
        source.sourceID = id
        return source
    }

    /// 重载合并转发消息的详情页构造
    public static func mergeForward(id: String, message: Message? = nil, messageIDPath: [String]) -> MessageSource {
        var source = MessageSource()
        source.sourceType = .mergeForwardMessage
        source.sourceID = id
        source.sourceMessage = message
        source.messageIDPath = messageIDPath
        return source
    }

    /// 快速构造一个合并转发详情页场景，id为最外层消息id，message是外层message
    public static func mergeForward(id: String, message: Message) -> MessageSource {
        var source = MessageSource()
        source.sourceType = .mergeForwardMessage
        source.sourceID = id
        source.sourceMessage = message
        return source
    }

    public static func transform(pb: Basic_V1_MessageSource) -> MessageSource {
        var source = MessageSource()
        source.sourceType = pb.sourceType
        source.sourceID = pb.sourceID
        source.messageIDPath = pb.messageIDPath
        return source
    }
}
