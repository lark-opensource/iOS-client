//
//  NormalTranslateService.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/6/24.
//

import UIKit
import Foundation
import LarkModel
import RxSwift
import LarkSDKInterface
import EENavigator
import RustPB
import TangramService
import ThreadSafeDataStructure

/// 图片翻译相关的请求参数
public struct ImageTranslateParameter {
    public let entityId: String?
    public let entityType: TranslateEntityType?
    public let translateScene: Im_V1_ImageTranslateScene

    public let chatId: String?
    public let imageKey: String
    public let middleImageKey: String
    public let isOrigin: Bool
    public let imageTranslateAbility: ImageTranslationAbility
    public let languageConflictSideEffect: (() -> Void)?
    public let completion: (ImageSet?, ImageProperty?, String?, Error?) -> Void

    public init(entityId: String? = nil,
                entityType: TranslateEntityType? = nil,
                translateScene: Im_V1_ImageTranslateScene,
                chatId: String? = nil,
                imageKey: String,
                middleImageKey: String,
                isOrigin: Bool,
                imageTranslateAbility: ImageTranslationAbility,
                languageConflictSideEffect: (() -> Void)?,
                completion: @escaping (ImageSet?, ImageProperty?, String?, Error?) -> Void) {
        self.entityId = entityId
        self.entityType = entityType
        self.translateScene = translateScene
        self.chatId = chatId
        self.imageKey = imageKey
        self.middleImageKey = middleImageKey
        self.isOrigin = isOrigin
        self.imageTranslateAbility = imageTranslateAbility
        self.languageConflictSideEffect = languageConflictSideEffect
        self.completion = completion
    }
}

/// 消息翻译相关的请求参数
public struct MessageTranslateParameter {
    public let message: Message
    public let source: MessageSource
    public let chat: Chat

    public init(message: Message,
                source: MessageSource,
                chat: Chat) {
        self.message = message
        self.source = source
        self.chat = chat
    }
}

/// 公司圈翻译相关的请求参数
public struct MomentsTranslateParameter {
    public let entityId: String
    public let entityType: RustPB.Moments_V1_EntityType
    public let contentLanguages: [String]
    public let currentTranslateInfo: RustPB.Moments_V1_TranslationInfo
    public let richText: RustPB.Basic_V1_RichText
    public let inlinePreviewEntities: InlinePreviewEntityBody
    public let urlPreviewHangPointMap: [String: Basic_V1_UrlPreviewHangPoint]
    public let from: NavigatorFrom?

    public init(entityId: String,
                entityType: RustPB.Moments_V1_EntityType,
                contentLanguages: [String],
                currentTranslateInfo: RustPB.Moments_V1_TranslationInfo,
                richText: RustPB.Basic_V1_RichText,
                inlinePreviewEntities: InlinePreviewEntityBody,
                urlPreviewHangPointMap: [String: Basic_V1_UrlPreviewHangPoint],
                from: NavigatorFrom?) {
        self.entityId = entityId
        self.entityType = entityType
        self.contentLanguages = contentLanguages
        self.currentTranslateInfo = currentTranslateInfo
        self.richText = richText
        self.inlinePreviewEntities = inlinePreviewEntities
        self.urlPreviewHangPointMap = urlPreviewHangPointMap
        self.from = from
    }
}

public typealias CancelTranslateBlock = () -> Void

/// 通用翻译服务
public protocol NormalTranslateService {
    func translateURLInlines(translateParam: MessageTranslateParameter)

    func getTranslatedInline(translateParam: MessageTranslateParameter) -> InlinePreviewEntityBody

    /// 手动翻译一条消息，这个消息只能传最外层的消息，比如：不会传合并转发消息的子消息进行翻译（目前不支持此功能）
    func translateMessage(translateParam: MessageTranslateParameter,
                          from: NavigatorFrom,
                          isFromMessageUpdate: Bool)
    func translateMessage(translateParam: MessageTranslateParameter,
                          isFromMessageUpdate: Bool)

    /// 翻译一条合并转发子消息
    func translateSingleMFMessage(translateParam: MessageTranslateParameter,
                                  from: NavigatorFrom)
    /// 手动翻译一条消息，这个消息只能传最外层的消息，比如：不会传合并转发消息的子消息进行翻译（目前不支持此功能）
    func translateMessage(messageId: String,
                          source: MessageSource,
                          chatId: String,
                          targetLanguage: String?,
                          isFromMessageUpdate: Bool)

    /// 处理252错误，目前策略为收起译文，另外开放接口做收起，防止翻译循环
    func hideTranslation(messageId: String,
                         source: MessageSource,
                         chatId: String)
    /// 消息场景下，弹窗让用户重新选择一种语言进行翻译
    func showSelectLanguage(messageId: String, source: MessageSource, chatId: String)

    /// 消息场景下，弹窗让用户重新选择一种语言进行翻译
    func showSelectLanguage(messageId: String, source: MessageSource, chatId: String, from: NavigatorFrom, dismissCompletion: @escaping (() -> Void))

    /// 图片翻译场景下，弹窗让用户重新选择一种语言进行翻译
    func showSelectLanguage(imageTranslateParam: ImageTranslateParameter)

    /// 检查消息是否应该：1：由原文被自动翻译，2：切换译文语言/显示规则，3：回到原文
    func checkLanguageAndDisplayRule(translateParam: MessageTranslateParameter, isFromMe: Bool)

    /// 重置key对应消息的检查状态
    func resetMessageCheckStatus(key: String)

    /// 探测一组图片是否支持翻译
    func detectImageTranslationAbility(assetKeys: [String],
                                       completion: @escaping ([ImageTranslationAbility]?, Error?) -> Void)

    /// 手动翻译一张图片 / 回到原图
    /// 使用场景：例如图片查看器的翻译行为
    /// PS：由于图片的单独翻译行为可能会affect挂载此图片的消息，因此该方法内部会调用translateMessageSilently
    /// 目前会影响到的消息种类有（目前暂不考虑对合并转发消息的影响）：
    /// 1. 纯图片消息
    /// 2. 仅单图无文字的富文本消息
    func translateImage(translateParam: ImageTranslateParameter, from: NavigatorFrom)

    /// 取消最近的图片翻译行为
    func cancelImageTranslate()

    /// 静默翻译/还原某一条消息(仅针对于非合并转发消息)，用户无感知(没有语种选择框等行为)
    /// 适用场景：图片查看器的翻译行为affect到简单含图消息(1. 纯图片消息  2. 仅单图无文字的富文本消息)
    func translateMessageSilently(messageId: String,
                                  chatId: String,
                                  targetLanguage: String?,
                                  isFromMessageUpdate: Bool)
    /// 存储某个消息页内的图片是否支持翻译
    var detachResultDic: SafeDictionary<String, ImageTranslationAbility> {get set}
    func enableDetachResultDic() -> Bool
    var startTranslateTime: TimeInterval? {get}
}

public extension NormalTranslateService {
    func translateMessage(translateParam: MessageTranslateParameter,
                          from: NavigatorFrom) {
        translateMessage(translateParam: translateParam, from: from, isFromMessageUpdate: false)
    }

    func translateMessage(messageId: String,
                          source: MessageSource,
                          chatId: String,
                          targetLanguage: String?) {
        translateMessage(messageId: messageId, source: source, chatId: chatId, targetLanguage: targetLanguage, isFromMessageUpdate: false)
    }
}

/// 翻译反馈服务
public protocol TranslateFeedbackService {
    /// 发送消息翻译反馈
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

    /// 调起发送消息反馈的弹框
    func showTranslateFeedbackView(message: Message, fromVC: UIViewController)

    /// 选择部分词语，调用翻译反馈
    func showTranslateFeedbackForSelectText(selectText: String,
                                            translateText: String,
                                            targetLanguage: String,
                                            copyConfig: TranslateCopyConfig,
                                            extraParam: [String: Any],
                                            fromVC: UIViewController)
}

public extension TranslateFeedbackService {
    func showTranslateFeedbackForSelectText(selectText: String,
                                            translateText: String,
                                            targetLanguage: String,
                                            extraParam: [String: Any],
                                            fromVC: UIViewController) {
        self.showTranslateFeedbackForSelectText(selectText: selectText,
                                                translateText: translateText,
                                                targetLanguage: targetLanguage,
                                                copyConfig: TranslateCopyConfig(),
                                                extraParam: extraParam,
                                                fromVC: fromVC)
    }
}

/// 划词翻译服务
public protocol SelectTranslateService {
    /// 调起划词翻译卡片，trackParam传值两种情况：
    /// 第一消息的划词翻译："messageID", "chatID", "cardSource"
    /// 其他场景的划词翻译："cardSource"    
    func showSelectTranslateView(selectString: String,
                                 fromVC: UIViewController,
                                 copyConfig: TranslateCopyConfig?,
                                 trackParam: [String: Any])
}

public extension SelectTranslateService {
    func showSelectTranslateView(selectString: String,
                                 fromVC: UIViewController,
                                 trackParam: [String: Any]) {
        self.showSelectTranslateView(selectString: selectString,
                                     fromVC: fromVC,
                                     copyConfig: nil,
                                     trackParam: trackParam)
    }
}

public struct TranslateCopyConfig {
    public let canCopy: Bool
    public let denyCopyText: String?
    public let pointId: String?
    //是否隐藏需要进行复制管控的系统菜单
    public let hideSystemMenu: Bool

    public init(canCopy: Bool = true, denyCopyText: String? = nil, pointId: String? = nil, hideSystemMenu: Bool = false) {
        self.canCopy = canCopy
        self.denyCopyText = denyCopyText
        self.pointId = pointId
        self.hideSystemMenu = hideSystemMenu
    }
}
