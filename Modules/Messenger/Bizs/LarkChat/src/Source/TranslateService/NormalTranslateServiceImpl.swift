//
//  NormalTranslateServiceImpl.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/6/24.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkModel
import UniverseDesignToast
import LKCommonsLogging
import LarkMessengerInterface
import RxCocoa
import RxSwift
import LarkMessageCore
import LarkKAFeatureSwitch
import LarkAppConfig
import ThreadSafeDataStructure
import AppReciableSDK
import EENavigator
import RustPB
import LarkAI
import LarkStorage
import LarkContainer
import LarkSearchCore
import LarkSetting

/// 翻译服务依赖
protocol TranslateServiceDependency {
    var translateAPI: TranslateAPI { get }
    var messageAPI: MessageAPI { get }
    var chatAPI: ChatAPI { get }
    var translateLanguageSetting: TranslateLanguageSetting { get }
    var userGeneralSettings: UserGeneralSettings { get }
    var translateInfoObservable: Observable<PushTranslateInfo> { get }
    var imageTranslateEnable: Bool { get }
    func pushTranslateInfo(info: PushTranslateInfo)
}

/// 通用的翻译服务
final class NormalTranslateServiceImpl: NSObject,
                                        NormalTranslateService,
                                        SelectTargetLanguageTranslateCenterDelegate,
                                        UserResolverWrapper {
    let userResolver: UserResolver
    private static let logger = Logger.log(NormalTranslateServiceImpl.self, category: "TranslateService")
    private static let englishLanguageKey = "en"
    private var rwlock: pthread_rwlock_t = pthread_rwlock_t()
    /// 弹窗让用户重新选择一种语言进行翻译
    private lazy var selectLanguageCenter: SelectTargetLanguageTranslateCenter = {
        return SelectTargetLanguageTranslateCenter(userResolver: userResolver,
                                                   selectTargetLanguageTranslateCenterdelegate: self,
                                                   translateLanguageSetting: self.dependency.translateLanguageSetting)
    }()
    /// 相同界面如果翻译设置不变的情况下，只需要判断一次消息的目标语言&&规则，我们需要记录下来
    private let _checkedMessageMap: SafeDictionary<String, Set<String>> = [:] + .readWriteLock
    private var checkedMessageMap: [String: Set<String>] {
        get { return _checkedMessageMap.getImmutableCopy() }
        set { _checkedMessageMap.replaceInnerData(by: newValue) }
    }
    /// 等待发请求的消息
    private var waitContexts: [MessageContext] = []
    /// 待请求获取主语言的message，这些message缺失了主语言
    private var noLanguageMessages: [(Message, MessageSource, Chat)] = []
    /// 待截断的图片品质前缀范围，避免server无法识别
    private let imageQualityPrefixs = ["origin:", "middle:", "thumbnail:"]
    /// 翻译服务依赖
    private let dependency: TranslateServiceDependency
    private let disposeBag = DisposeBag()
    private var imageTranslateDispose: Disposable?
    /// 可感知埋点，messageid：（key，开始时间）
    private let messageTrackInfos: SafeDictionary<String, (DisposedKey, TimeInterval)> = [:] + .readWriteLock

    private var lastTopMostFrom: NavigatorFrom?
    // URL中台Inline翻译
    private let inlineTranslateService: TranslateInlinePreviewService
    // 记录合并转发消息计算后的目标语言， 通过读写锁保证读写安全
    private var mergeForwardTrgLanguageMap: SafeDictionary<String, String> = [:] + .readWriteLock
    var detachResultDic: SafeDictionary<String, ImageTranslationAbility> = [:] + .readWriteLock
    var startTranslateTime: TimeInterval?

    // MARK: - init
    init(userResolver: UserResolver, dependency: TranslateServiceDependency) {
        self.userResolver = userResolver
        self.dependency = dependency
        self.inlineTranslateService = TranslateInlinePreviewService(dependency: dependency)
        super.init()
        // 监听此push会得到翻译结果
        dependency.translateInfoObservable.subscribe(onNext: { [weak self] translateInfo in
            self?.trackEndTranslateForPushTranslateInfo(pushTranslateInfo: translateInfo)
        }).disposed(by: self.disposeBag)
    }

    // MARK: - 可感知埋点
    /// 用户开始翻译一条消息
    private func trackStartTranslate(message: Message, chat: Chat) {
        // 发起翻译需要进行可感知打点
        let extra = Extra(
            isNeedNet: true,
            latencyDetail: nil,
            metric: ["message_id": message.id],
            category: ["message_type": message.type.rawValue, "chat_type": chat.type.rawValue]
        )
        self.messageTrackInfos[message.id] = (
            AppReciableSDK.shared.start(
                biz: .Messenger,
                scene: .Chat,
                event: .translateMessage,
                page: nil,
                userAction: nil,
                extra: extra
            ),
            CACurrentMediaTime()
        )
    }

    /// 用户翻译了相同语言的消息
    private func trackEndTranslateForSameLanguage(messageId: String) {
        guard self.messageTrackInfos.keys.contains(messageId) else { return }

        let params = ErrorParams(
            biz: .Messenger,
            scene: .Chat,
            event: .translateMessage,
            errorType: .Other,
            errorLevel: .Exception,
            errorCode: 252,
            userAction: nil,
            page: nil,
            errorMessage: "same language",
            extra: nil
        )
        AppReciableSDK.shared.error(params: params)
        self.messageTrackInfos.removeValue(forKey: messageId)
    }

    private var translateInfoMap: [String: TranslateInfo] = [:]
    /// 处理主动发起翻译/其他端同步译文
    private func trackEndTranslateForPushTranslateInfo(pushTranslateInfo: PushTranslateInfo) {
        self.translateInfoMap = pushTranslateInfo.translateInfoMap
        pushTranslateInfo.translateInfoMap.forEach { (messageId, translateInfo) in
            guard self.messageTrackInfos.keys.contains(messageId) else { return }

            // 翻译失败，判断顺序遵从TranslateInfo说明
            if translateInfo.translateFaild {
                let params = ErrorParams(
                    biz: .Messenger,
                    scene: .Chat,
                    event: .translateMessage,
                    errorType: .Other,
                    errorLevel: .Exception,
                    errorCode: -1,
                    userAction: nil,
                    page: nil,
                    errorMessage: nil,
                    extra: nil
                )
                AppReciableSDK.shared.error(params: params)
                self.messageTrackInfos.removeValue(forKey: messageId)
            }
            // 未翻译成功则不处理，后续会有翻译成功/失败
            else if translateInfo.state == .translating {}
            // 翻译成功
            else if let trackInfo = self.messageTrackInfos.removeValue(forKey: messageId) {
                let extra = Extra(
                    isNeedNet: true,
                    latencyDetail: ["sdk_cost": (CACurrentMediaTime() - trackInfo.1) * 1000],
                    metric: [:],
                    category: [:]
                )
                AppReciableSDK.shared.end(key: trackInfo.0, extra: extra)
            }
        }
    }

    // 单条合并转发消息翻译
    public func translateSingleMFMessage(translateParam: MessageTranslateParameter, from: NavigatorFrom) {
        let message = translateParam.message
        let chat = translateParam.chat
        var contexts: [MessageContext] = []
        if message.type == .text || message.type == .post {
            var context = MessageContext()
            context.messageID = message.id
            guard let rootMessageId = message.mergeMessageIdPath.first else { return }
            let messageSource = MessageSource.mergeForward(id: rootMessageId,
                                                           messageIDPath: message.mergeMessageIdPath)
            context.messageSource = messageSource
            context.chatID = chat.id
            let newTrgLanguage = updateTargetLanguage(
                targetLanguage: dependency.translateLanguageSetting.targetLanguage,
                srcLanguage: message.messageLanguage
            )
            context.manualTargetLanguage = newTrgLanguage
            context.messageContentVersion = message.contentVersion
            /// 翻译单条合并转发消息，如果源语言和目标语言相同，并且优化后还是相同语言
            if newTrgLanguage == message.messageLanguage,
               newTrgLanguage == dependency.translateLanguageSetting.targetLanguage {
                self.showSelectLanguage(messageId: message.id, source: messageSource, chatId: chat.id)
            } else {
                contexts.append(context)
                Self.logger.info("translate single MFMessage, id = \(message.id). trgLanguage = \(String(describing: context.manualTargetLanguage))")
            }
        }
        if !contexts.isEmpty {
            self.dependency.translateAPI.manualTranslate(contexts: contexts, isFromMessageUpdate: false).subscribe(onNext: { [weak self] (response) in
                self?.handleResponseV3(response: response)
            }, onError: { [weak self] _ in
                self?.handleError(contexts: contexts)
            }).disposed(by: self.disposeBag)
        }

    }

    // 更新目标语言
    private func updateTargetLanguage(targetLanguage: String, srcLanguage: String) -> String {
        guard AIFeatureGating.optimizeTargetLanuage.isUserEnabled(userResolver: userResolver) else { return targetLanguage }
        var res = targetLanguage
        let mainLanguage = KVPublic.AI.mainLanguage.value()
        let lastSelectLanguage = KVPublic.AI.lastSelectedTargetLanguage.value()
        if targetLanguage == srcLanguage {
            if targetLanguage == Self.englishLanguageKey {
                if mainLanguage != Self.englishLanguageKey {
                    res = mainLanguage
                    Self.logger.info("[optimizeTargetLanguage]: use mainLanguage-\(res), \(mainLanguage.isEmpty)")
                    return res
                } else if !lastSelectLanguage.isEmpty {
                    res = lastSelectLanguage
                    Self.logger.info("[optimizeTargetLanguage]: use lastSelectLanguage-\(res)")
                    return res
                }
            } else {
                res = Self.englishLanguageKey
                Self.logger.info("[optimizeTargetLanguage]: use english-\(res)")
                return res
            }
        }
        Self.logger.info("[optimizeTargetLanguage]: use targetLanguage-\(res)")
        return res
    }

    // MARK: - 处理252错误
    func hideTranslation(messageId: String,
                         source: MessageSource,
                         chatId: String) {
        self.dependency.chatAPI.fetchChats(by: [chatId], forceRemote: false).flatMap { (chats) -> Observable<(Message, Chat)> in
            if let chat = chats[chatId] {
                return self.dependency.messageAPI.fetchMessage(id: messageId).map { ($0, chat) }
            }
            return Observable.error(APIError(type: .entityIncompleteData(message: "no chat found")))
        }.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (message, chat) in
            guard let self = self else { return }
            /// 原文不处理，目前状态为译文的话，做收起译文操作
            if message.displayRule == .withOriginal || message.displayRule == .onlyTranslation {
                let translateParam = MessageTranslateParameter(message: message,
                                                               source: source,
                                                               chat: chat)
                self.translateMessage(translateParam: translateParam, targetLanguage: nil, from: self.lastTopMostFrom)
            }
        }).disposed(by: self.disposeBag)
    }
    // MARK: - 手动翻译一条消息
    func translateMessage(translateParam: MessageTranslateParameter,
                          from: NavigatorFrom,
                          isFromMessageUpdate: Bool) {
        if ChatTrack.enablePostTrack(), translateParam.message.displayRule == .noTranslation {
            trackForClick(source: "message", type: translateParam.message.type.rawValue)
        }
        guard userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteTranslation)) else {
            if ChatTrack.enablePostTrack(), translateParam.message.displayRule == .noTranslation {
                trackForFail(source: "message",
                             type: translateParam.message.type.rawValue,
                             failReason: "fg is closed")
            }
            return
        }
        guard let vc = from.fromViewController else {
            assertionFailure()
            if ChatTrack.enablePostTrack(), translateParam.message.displayRule == .noTranslation {
                trackForFail(source: "message",
                             type: translateParam.message.type.rawValue,
                             failReason: "push vc is nil")
            }
            return
        }
        let lastTopMostFrom = WindowTopMostFrom(vc: vc)
        self.lastTopMostFrom = lastTopMostFrom
        // 如果用户没有手动选择语言，则targetLanguage的配置读取逻辑收敛在sdk
        self.translateMessage(translateParam: translateParam, targetLanguage: nil, from: lastTopMostFrom, isFromMessageUpdate: isFromMessageUpdate)
    }

    func translateMessage(translateParam: MessageTranslateParameter,
                          isFromMessageUpdate: Bool) {
        var isTranslated: Bool {
            if translateParam.message.displayRule == .noTranslation || translateParam.message.displayRule == .unknownRule { return false }
            if translateParam.message.translateLanguage.isEmpty { return false }
            return true
        }
        guard let translateInfo = translateInfoMap[translateParam.message.id] else { return }
        guard isTranslated else { return }
        guard translateInfo.messageContentVersion != translateParam.message.contentVersion else { return }

        translateMessage(translateParam: translateParam,
                         targetLanguage: nil,
                         isFromMessageUpdate: isFromMessageUpdate,
                         isManualTranslated: translateParam.message.isManualTranslated)
    }

    func translateMessage(messageId: String,
                          source: MessageSource,
                          chatId: String,
                          targetLanguage: String?,
                          isFromMessageUpdate: Bool) {
        trackForClick(source: "message", type: -1)
        self.dependency.chatAPI.fetchChats(by: [chatId], forceRemote: false).flatMap { (chats) -> Observable<(Message, Chat)> in
            if let chat = chats[chatId] {
                return self.dependency.messageAPI.fetchMessage(id: messageId).map { ($0, chat) }
            }
            return Observable.error(APIError(type: .entityIncompleteData(message: "no chat found")))
        }.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (message, chat) in
            guard let self = self else { return }
            let translateParam = MessageTranslateParameter(message: message,
                                                           source: source,
                                                           chat: chat)
            self.translateMessage(translateParam: translateParam, targetLanguage: targetLanguage, from: self.lastTopMostFrom, isFromMessageUpdate: isFromMessageUpdate)
        }).disposed(by: self.disposeBag)
    }

    private func translateMessage(translateParam: MessageTranslateParameter,
                                  targetLanguage: String?,
                                  from: NavigatorFrom? = nil,
                                  isSwitchLanguage: Bool? = nil,
                                  isFromMessageUpdate: Bool = false,
                                  isManualTranslated: Bool = true) {
        let message = translateParam.message
        let source = translateParam.source
        let chat = translateParam.chat
        let consTrgLanguage = targetLanguage ?? self.dependency.translateLanguageSetting.targetLanguage
        var srcLanguage = message.messageLanguage
        let optimizeLanguage = updateTargetLanguage(targetLanguage: consTrgLanguage, srcLanguage: srcLanguage)
        self.trackStartTranslate(message: message, chat: chat)
        /// 是否为隐藏译文操作
        var isHideTranslation: Bool?
        switch message.displayRule {
        case .withOriginal, .onlyTranslation:
            ChatTrack.trackTranslateToOrigin(chat: chat)
            if message.type == .image {
                ChatTrack.trackUntranslateImage()
            }
            if isSwitchLanguage == true {
                isHideTranslation = false
            } else {
                isHideTranslation = true
            }
        case .noTranslation:
            ChatTrack.trackTranslate(chat: chat, message: message, way: .manual)
            if message.type == .image {
                ChatTrack.trackTransalteImage(position: "message", messageType: "image")
            }
        @unknown default: break
        }

        /// 手动翻译之后为当前的消息添加已检查标识
        let key = source.sourceType == .commonMessage ? chat.id : source.sourceID
        let id = message.id + "_" + "\(message.contentVersion)"
        // 添加已检查标示
        var currChatSet = self.checkedMessageMap[key] ?? Set<String>()
        currChatSet.insert(id)
        self.checkedMessageMap[key] = currChatSet

        NormalTranslateServiceImpl.logger.info("""
            translateMessage.request.info:
            messageId = \(message.id),
            sourceId = \(source.sourceID),
            sourceType = \(source.sourceType),
            chat = \(chat.id),
            messageType = \(message.type),
            message.displayRule = \(message.displayRule.rawValue),
            message.srcLanguage = \(srcLanguage),
            message.optimizeLanguage = \(optimizeLanguage)
        """)

        // 待请求的MessageContext
        var contexts: [MessageContext] = []
        self.startTranslateTime = Date().timeIntervalSince1970

        // 如果消息是text/post，直接发起翻译即可
        if message.type == .text || message.type == .post || message.type == .image || TranslateControl.isTranslatableAudioMessage(message) || TranslateControl.isTranslatableMessageCardType(message) {
            var context = MessageContext()
            context.messageID = message.id
            context.messageSource = source
            context.chatID = chat.id
            if isHideTranslation != true {
                /// 切换语种不会目标语言优化
                if isSwitchLanguage != true, AIFeatureGating.optimizeTargetLanuage.isUserEnabled(userResolver: userResolver) {
                    context.manualTargetLanguage = optimizeLanguage
                    if srcLanguage == consTrgLanguage,
                       optimizeLanguage == consTrgLanguage {
                        /// 语言优化后,三个语言依然相同，弹起弹窗
                        self.showSelectLanguage(messageId: message.id, source: source, chatId: chat.id)
                        if ChatTrack.enablePostTrack() {
                            trackForFail(source: "message",
                                         type: message.type.rawValue,
                                         failReason: "targetLang equal to sourceLang")
                        }
                        return
                    }
                } else if let language = targetLanguage {
                    context.manualTargetLanguage = language
                }
            }
            NormalTranslateServiceImpl.logger.info("translateMessage.targetLanguage: \(String(describing: context.manualTargetLanguage))")
            context.messageContentVersion = message.contentVersion
            contexts.append(context)
        } else if message.type == .mergeForward, let content = message.content as? MergeForwardContent {
            // 如果是发起翻译请求
            if message.displayRule == .unknownRule || message.displayRule == .noTranslation {

                if mergeForwardCanTranslate(message: message, source: MessageSource.mergeForward(id: message.id, message: message), chat: chat, from: from, trgLanguage: consTrgLanguage) {
                    // 优化后的目标语言
                    /// 合并转发消息没有切换语种操作，目标语言都是传递的优化后的语言，其他消息的收起译文目标语言传值为nil
                    let optimizeMFLanguage = mergeForwardTrgLanguageMap[message.id]
                    Self.logger.info("translate MergeForward Message<id: \(message.id), trgLanguage: \(String(describing: optimizeMFLanguage))>")
                    if AIFeatureGating.multiLayerTranslate.isUserEnabled(userResolver: userResolver) {
                        // 展开翻译
                        contexts += parseMergeForwardContext(message: message,
                                                             chatID: chat.id,
                                                             sourceID: message.id,
                                                             sourceMessage: message,
                                                             trgLanguage: optimizeMFLanguage,
                                                             path: [],
                                                             toOrigin: false)
                    } else {
                        // 只需要把支持翻译的消息发起翻译即可
                        content.messages.forEach { (subMessage) in
                            guard subMessage.type != .mergeForward, subMessage.isSupportToTranslate(imageTranslationEnable: dependency.imageTranslateEnable) else { return }

                            var context = MessageContext()
                            context.messageID = subMessage.id
                            context.messageSource = MessageSource.mergeForward(id: message.id, message: message)
                            context.chatID = chat.id
                            context.messageContentVersion = subMessage.contentVersion
                            if let language = optimizeMFLanguage {
                                context.manualTargetLanguage = language
                            } else if let language = targetLanguage {
                                context.manualTargetLanguage = language
                            }
                            contexts.append(context)
                        }
                    }
                }

            } else {
                Self.logger.info("Return to origin MergeForward Message<id = \(message.id)")
                // 回到原文请求，只需要找到所有不是原文的子消息发起翻译即可
                if AIFeatureGating.multiLayerTranslate.isUserEnabled(userResolver: userResolver) {
                    contexts += parseMergeForwardContext(message: message,
                                                         chatID: chat.id,
                                                         sourceID: message.id,
                                                         sourceMessage: message,
                                                         trgLanguage: targetLanguage,
                                                         path: [],
                                                         toOrigin: true)
                } else {
                    content.messages.forEach { (subMessage) in
                        guard subMessage.displayRule == .onlyTranslation || subMessage.displayRule == .withOriginal else { return }

                        var context = MessageContext()
                        context.messageID = subMessage.id
                        context.messageSource = MessageSource.mergeForward(id: message.id, message: message)
                        context.chatID = chat.id
                        context.messageContentVersion = subMessage.contentVersion
                        if let language = targetLanguage { context.manualTargetLanguage = language }
                        contexts.append(context)
                    }
                }
            }
        }

        // 发起翻译请求
        if !contexts.isEmpty {
            if isManualTranslated {
                self.dependency.translateAPI.manualTranslate(contexts: contexts, isFromMessageUpdate: isFromMessageUpdate).subscribe(onNext: { [weak self] (response) in
                    guard let self = self else { return }
                    if AIFeatureGating.multiLayerTranslate.isUserEnabled(userResolver: self.userResolver) {
                        self.handleResponseV3(response: response)
                    } else {
                        self.handleResponse(contexts: contexts, response: response)
                    }
                }, onError: { [weak self] _ in
                    self?.handleError(contexts: contexts)
                }).disposed(by: self.disposeBag)
            } else {
                self.dependency.translateAPI.autoTranslate(contexts: contexts, isFromMessageUpdate: isFromMessageUpdate).subscribe(onNext: { [weak self] (response) in
                    guard let self = self else { return }
                    if AIFeatureGating.multiLayerTranslate.isUserEnabled(userResolver: self.userResolver) {
                        self.handleResponseV3(response: response)
                    } else {
                        self.handleResponse(contexts: contexts, response: response)
                    }
                }, onError: { [weak self] _ in
                    self?.handleError(contexts: contexts)
                }).disposed(by: self.disposeBag)
            }

        } else if ChatTrack.enablePostTrack() {
            trackForFail(source: "message",
                         type: message.type.rawValue,
                         failReason: "translate contexts is empty")
        }
    }

    func parseMergeForwardContext(message: Message,
                                  chatID: String,
                                  sourceID: String,
                                  sourceMessage: Message,
                                  trgLanguage: String?,
                                  path: [String],
                                  toOrigin: Bool) -> [MessageContext] {
        var contexts: [MessageContext] = []
        var mergeIDPath = path
        guard let content = message.content as? MergeForwardContent else {
            return contexts
        }
        mergeIDPath.append(message.id)
        // 解析当前层支持翻译的消息
        content.messages.forEach { (subMessage) in
            if !toOrigin {
                guard subMessage.isSupportToTranslate(imageTranslationEnable: dependency.imageTranslateEnable) else { return }
            } else {
                // 返回原文
                guard subMessage.displayRule == .onlyTranslation || subMessage.displayRule == .withOriginal else { return }
            }
            if subMessage.type == .mergeForward {
                contexts += parseMergeForwardContext(message: subMessage,
                                                     chatID: chatID,
                                                     sourceID: sourceID,
                                                     sourceMessage: sourceMessage,
                                                     trgLanguage: trgLanguage,
                                                     path: mergeIDPath,
                                                     toOrigin: toOrigin)
            } else {
                var singleMessgePath = mergeIDPath
                singleMessgePath.append(subMessage.id)
                var context = MessageContext()
                context.messageID = subMessage.id
                let messageSource = MessageSource.mergeForward(id: sourceID, message: sourceMessage, messageIDPath: singleMessgePath)
                context.messageSource = messageSource
                context.chatID = chatID
                context.messageContentVersion = subMessage.contentVersion
                if let language = trgLanguage { context.manualTargetLanguage = language }
                contexts.append(context)
            }
        }
        return contexts
    }

    func statisticMergeForwardInfo(message: Message, trgLanguage: String) -> (Int, Int, Int) {
        guard let content = message.content as? MergeForwardContent else { return (1, 0, 1) }
        // 不支持翻译的消息，原语言和目标语言一致的消息, 合并转发消息总条数
        var noSupportCount = 0; var sameLanguageCount = 0; var expandLanguageCount = 0
        content.messages.forEach { (subMessage) in
            if !subMessage.isSupportToTranslate(imageTranslationEnable: dependency.imageTranslateEnable) {
                // 超过三层以上的折叠部分消息，进入此分支，不支持翻译
                noSupportCount += 1
            } else if subMessage.type == .mergeForward {
                expandLanguageCount -= 1
                let res = statisticMergeForwardInfo(message: subMessage, trgLanguage: trgLanguage)
                noSupportCount += res.0
                sameLanguageCount += res.1
                expandLanguageCount += res.2
            } else if subMessage.messageLanguage == trgLanguage {
                sameLanguageCount += 1
            }
            expandLanguageCount += 1
        }

        return (noSupportCount, sameLanguageCount, expandLanguageCount)
    }

    // 检测该合并转发消息是否能够翻译
    private func mergeForwardCanTranslate(message: Message, source: MessageSource, chat: Chat, from: NavigatorFrom?, trgLanguage: String) -> Bool {
        if AIFeatureGating.multiLayerTranslate.isUserEnabled(userResolver: userResolver) {
            return multiLayerCanTranslate(message: message, source: source, chat: chat, from: from, trgLanguage: trgLanguage)
        } else {
            return singleLayerCanTranslate(message: message, source: source, chat: chat, from: from, trgLanguage: trgLanguage)
        }
    }
    // 单层合并转发消息是否支持翻译
    private func singleLayerCanTranslate(message: Message, source: MessageSource, chat: Chat, from: NavigatorFrom?, trgLanguage: String) -> Bool {
        guard let content = message.content as? MergeForwardContent else { return false }
        var newTrgLanguage: String?
        // 不支持翻译的消息，原语言和目标语言一致的消息
        var noSupportCount = 0; var sameLanguageCount = 0
        content.messages.forEach { (message) in
            if !message.isSupportToTranslate(imageTranslationEnable: dependency.imageTranslateEnable) || message.type == .mergeForward {
                noSupportCount += 1
            } else if message.messageLanguage == self.dependency.translateLanguageSetting.targetLanguage {
                sameLanguageCount += 1
            }
        }
        // 如果没有子消息支持翻译，弹窗提示
        if noSupportCount == content.messages.count, let view = from?.fromViewController?.viewIfLoaded {
            UDToast.showTips(with: BundleI18n.LarkChat.Lark_Chat_TranslateAudioMessageError, on: view)
            return false
        }
        if noSupportCount + sameLanguageCount == content.messages.count {
            newTrgLanguage = updateTargetLanguage(targetLanguage: trgLanguage, srcLanguage: trgLanguage)
        }
        // 更新后还是相同的语言，弹起选择语言弹窗
        if newTrgLanguage == trgLanguage {
            self.showSelectLanguage(messageId: message.id, source: source, chatId: chat.id)
            return false
        }
        if newTrgLanguage != mergeForwardTrgLanguageMap[message.id],
           let language = newTrgLanguage {
            mergeForwardTrgLanguageMap[message.id] = language
        }
        // 可以直接翻译或者更新目标语言后可以翻译
        return true
    }
    // 多层合并转发消息是否支持翻译
    private func multiLayerCanTranslate(message: Message, source: MessageSource, chat: Chat, from: NavigatorFrom?, trgLanguage: String) -> Bool {
        guard message.content is MergeForwardContent else { return false }
        var newTrgLanguage: String?

        // 不支持翻译的消息，原语言和目标语言一致的消息, 合并转发消息总条数
        let statisticsInfo = statisticMergeForwardInfo(message: message, trgLanguage: trgLanguage)
        let noSupportCount = statisticsInfo.0
        let sameLanguageCount = statisticsInfo.1
        let expandLanguageCount = statisticsInfo.2

        // 如果没有子消息支持翻译，弹窗提示
        if noSupportCount == expandLanguageCount, let view = from?.fromViewController?.viewIfLoaded {
            UDToast.showTips(with: BundleI18n.LarkChat.Lark_Chat_TranslateAudioMessageError, on: view)
            return false
        }

        if AIFeatureGating.optimizeTargetLanuage.isUserEnabled(userResolver: userResolver) {
            // 所有子消息都和目标语言相同，更新目标语言
            if noSupportCount + sameLanguageCount == expandLanguageCount {
                newTrgLanguage = updateTargetLanguage(targetLanguage: trgLanguage, srcLanguage: trgLanguage)
            }
            // 更新后还是相同的语言，弹起选择语言弹窗
            if newTrgLanguage == trgLanguage {
                self.showSelectLanguage(messageId: message.id, source: source, chatId: chat.id)
                return false
            }
        } else {
            if noSupportCount + sameLanguageCount == expandLanguageCount {
                self.showSelectLanguage(messageId: message.id, source: source, chatId: chat.id)
                return false
            }
        }

        if newTrgLanguage != mergeForwardTrgLanguageMap[message.id],
           let language = newTrgLanguage {
            mergeForwardTrgLanguageMap[message.id] = language
        }
        // 可以直接翻译或者更新目标语言后可以翻译
        return true
    }
    // MARK: - 消息场景下，弹窗让用户重新选择一种语言进行翻译
    func showSelectLanguage(messageId: String, source: MessageSource, chatId: String) {
        showSelectLanguage(messageId: messageId, source: source, chatId: chatId, backButtonStatus: .cancel, dismissCompletion: nil)
    }

    func showSelectLanguage(messageId: String, source: MessageSource, chatId: String, from: NavigatorFrom, dismissCompletion: @escaping (() -> Void)) {
        self.lastTopMostFrom = from
        showSelectLanguage(messageId: messageId, source: source, chatId: chatId, backButtonStatus: .cancel, dismissCompletion: dismissCompletion)
    }

    private func showSelectLanguage(messageId: String,
                                    source: MessageSource,
                                    chatId: String,
                                    backButtonStatus: SelectLanguageHeaderView.BackButtonStatus,
                                    from: NavigatorFrom? = nil,
                                    dismissCompletion: (() -> Void)?) {
        var sourceVC: NavigatorFrom
        if let from = from {
            sourceVC = from
        } else if let from = self.lastTopMostFrom {
            sourceVC = from
        } else {
            assertionFailure()
            return
        }

        self.trackEndTranslateForSameLanguage(messageId: messageId)
         // 从SDK获取message和chat信息，然后再发起请求
        self.dependency.chatAPI.fetchChats(by: [chatId], forceRemote: false).flatMap { (chats) -> Observable<(Message, Chat)> in
            if let chat = chats[chatId] {
                return self.dependency.messageAPI.fetchMessage(id: messageId).map { ($0, chat) }
            }
            return Observable.error(APIError(type: .entityIncompleteData(message: "no chat found")))
        }.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] (message, chat) in
            let translateParam = MessageTranslateParameter(message: message,
                                                           source: source,
                                                           chat: chat)
            self?.selectLanguageCenter.showSelectDrawer(translateContext: .message(context: translateParam),
                                                        from: sourceVC,
                                                        disableLanguage: message.translateLanguage,
                                                        backButtonStatus: backButtonStatus,
                                                        dismissCompletion: dismissCompletion)
        }).disposed(by: self.disposeBag)
    }
    // MARK: - 图片翻译场景下，弹窗让用户重新选择一种语言进行翻译
    func showSelectLanguage(imageTranslateParam: ImageTranslateParameter) {
        guard let from = self.lastTopMostFrom else {
            assertionFailure()
            return
        }
        selectLanguageCenter.showSelectDrawer(translateContext: .image(context: imageTranslateParam), from: from)
    }

    // MARK: - SelectTargetLanguageTranslateCenterDelegate
    func finishSelect(translateContext: TranslateContext, targetLanguage: String) {
        guard let from = self.lastTopMostFrom?.fromViewController else {
            assertionFailure()
            return
        }
        if case let .message(context) = translateContext {
            translateMessage(translateParam: context,
                             targetLanguage: targetLanguage,
                             from: from,
                             isSwitchLanguage: true)
        } else if case let .image(context) = translateContext {
            context.languageConflictSideEffect?()
            translateImage(translateParam: context, targetLanguage: targetLanguage, from: from)
        }
    }

    // MARK: - 检查消息的语言和展示规则是否需要变化
    func checkLanguageAndDisplayRule(translateParam: MessageTranslateParameter, isFromMe: Bool) {
        guard userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteTranslation)) else { return }

        let message = translateParam.message
        let source = translateParam.source
        let chat = translateParam.chat

        // 跳过假消息，假消息的messageId是本地的
        guard message.localStatus == .success else { return }
        guard message.id != message.cid else { return }
        // 该source场景下的message是否需要自动检测
        guard self.messageSourceNeedAutoTranslate(message: message, source: source) else { return }
        // chat是否需要自动检测
        guard self.chatNeedAutoTranslate(chat: chat) else { return }
        // key为该message+source所在界面的唯一标示，common为chat.id，mergeForward为source.sourceID
        let key = source.sourceType == .commonMessage ? chat.id : source.sourceID
        // 已经检查过了，就不再检查
        let id = message.id + "_" + "\(message.contentVersion)"

        if let set = self.checkedMessageMap[key], set.contains(id) { return }
        // 添加已检查标示
        var currChatSet = self.checkedMessageMap[key] ?? Set<String>()
        currChatSet.insert(id)
        self.checkedMessageMap[key] = currChatSet

        guard chat.isAutoTranslate || message.displayRule == .onlyTranslation || message.displayRule == .withOriginal else {
            return
        }

        // 如果是纯图片或消息卡片消息，则不需要考虑缺失主语言的场景
        if message.type == .image && message.anyImageElementCanBeTranslated() || TranslateControl.isTranslatableMessageCardType(message) {
            Self.logger.info("""
                autoTranslate.request.info(image/card):
                message.id = \(message.id),
                message.type = \(message.type),
                message.version = \(message.contentVersion),
                message.displayRule = \(message.displayRule)
            """)
            self.handleLanguageAndDisplayRule(message: message, source: source, chat: chat)
            return
        }
        // 自己发送的合并转发消息不自动翻译
        if AIFeatureGating.multiLayerTranslate.isUserEnabled(userResolver: userResolver), message.type == .mergeForward {
            if message.displayRule == .onlyTranslation || message.displayRule == .withOriginal || (message.displayRule == .noTranslation && !isFromMe) {
                Self.logger.info("""
                    autoTranslate.request.info(mergeForward):
                    message.id = \(message.id),
                    message.type = \(message.type),
                    message.version = \(message.contentVersion),
                    message.displayRule = \(message.displayRule)
                """)
                self.handleLanguageAndDisplayRule(message: message, source: source, chat: chat)
            }
            return
        }
        // 主语言缺失，则需要向服务端获取主语言，然后再执行后续逻辑
        if message.messageLanguage.isEmpty {
            self.noLanguageMessages.append((message, source, chat))
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(putLanguageRequest), object: nil)
            self.perform(#selector(putLanguageRequest), with: nil, afterDelay: 0.3)
        } else {
            Self.logger.info("""
                autoTranslate.request.info:
                message.id = \(message.id),
                message.type = \(message.type),
                message.version = \(message.contentVersion),
                message.displayRule = \(message.displayRule)
            """)
            self.handleLanguageAndDisplayRule(message: message, source: source, chat: chat)
        }
    }

    /// 处理自动检查逻辑
    private func handleLanguageAndDisplayRule(message: Message, source: MessageSource, chat: Chat) {
        // 丢入waitContexts合并请求
        if AIFeatureGating.multiLayerTranslate.isUserEnabled(userResolver: userResolver),
           message.type == .mergeForward {
            self.waitContexts += parseMergeForwardContext(message: message, chatID: chat.id, sourceID: message.id, sourceMessage: message, trgLanguage: nil, path: [], toOrigin: false)
        } else {
            var context = MessageContext()
            context.messageID = message.id
            context.messageSource = source
            context.chatID = chat.id
            context.messageContentVersion = message.contentVersion
            self.waitContexts.append(context)
        }

        // 打点：消息自动翻译埋点
        let autoTranslateGlobalSwitch = self.dependency.userGeneralSettings.translateLanguageSetting.autoTranslateGlobalSwitch
        if autoTranslateGlobalSwitch {
            ChatTrack.trackTranslate(chat: chat, message: message, way: .auto)
        }

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(putContexts), object: nil)
        self.perform(#selector(putContexts), with: nil, afterDelay: 0.3)
    }

    /// 获取消息的主语言
    @objc
    private func putLanguageRequest() {
        // 去重
        let messageSet = self.noLanguageMessages.reduce([:]) { (result, value) -> [String: (Message, MessageSource, Chat)] in
            var result = result
            result[value.0.id] = (value.0, value.1, value.2)
            return result
        }
        self.noLanguageMessages = []
        if messageSet.isEmpty { return }

        // 获取主语言
        self.dependency.translateAPI.getMessageLanguage(messageIds: messageSet.map({ $0.0 }))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (messageLanguages) in
                guard let `self` = self else { return }

                messageLanguages.forEach { (messageId, language) in
                    guard let value = messageSet[messageId], !language.isEmpty else { return }

                    // message是引用传入的且messageLanguage属性不会影响UI展示
                    // 所以直接修改该处的message，不用发message的push，sdk此时也已经更新了该message
                    value.0.messageLanguage = language
                    self.handleLanguageAndDisplayRule(message: value.0, source: value.1, chat: value.2)
                }
            }).disposed(by: self.disposeBag)
    }

    @objc
    private func putContexts() {
        let tempContexts = self.waitContexts
        self.waitContexts = []

        // 进行自动检测请求
        self.dependency.translateAPI.autoTranslate(contexts: tempContexts, isFromMessageUpdate: false)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else { return }
                if AIFeatureGating.multiLayerTranslate.isUserEnabled(userResolver: self.userResolver) {
                    self.handleResponseV3(response: response)
                } else {
                    self.handleResponse(contexts: tempContexts, response: response)
                }
            }, onError: { [weak self] _ in
                self?.handleError(contexts: tempContexts)
            }).disposed(by: self.disposeBag)
    }

    // MARK: - 重置key对应消息的检查状态
    func resetMessageCheckStatus(key: String) {
        self.checkedMessageMap[key] = Set<String>()
        self.inlineTranslateService.resetTranslatedInlines(key: key)
    }

    // MARK: - 探测一组图片是否支持翻译
    func detectImageTranslationAbility(assetKeys: [String],
                                       completion: @escaping ([ImageTranslationAbility]?, Error?) -> Void) {
        /// 这里需要端上特化处理下，去除带品质前缀的imageKey，否则server识别不了
        let fixedAssetKeys = assetKeys.map { (key) -> String in
            var fixKey = key
            for prefix in self.imageQualityPrefixs {
                fixKey = fixKey.replacingOccurrences(of: prefix, with: "", options: .regularExpression)
            }
            return fixKey
        }
        NormalTranslateServiceImpl.logger.info("""
            detectImageTranslationAbility.request.info:
            assetKeys = \(fixedAssetKeys)
        """)
        dependency.translateAPI.detectImageTranslationAbility(imageKeys: fixedAssetKeys)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (translateAbilities) in
                NormalTranslateServiceImpl.logger.info("""
                    detectImageTranslationAbility.response.info:
                    assetKeys = \(fixedAssetKeys),
                    abilities = \(translateAbilities.map { $0.canTranslate })
                """)
                completion(translateAbilities, nil)
            }, onError: { (error) in
                NormalTranslateServiceImpl.logger.error("detectImageTranslationAbility.error = \(error.localizedDescription)")
                completion(nil, error)
            }).disposed(by: disposeBag)
    }

    // MARK: - 手动翻译一张图片 / 回到原图
    func translateImage(translateParam: ImageTranslateParameter, from: NavigatorFrom) {
        guard let vc = from.fromViewController else {
            assertionFailure()
            return
        }
        let lastTopMostFrom = WindowTopMostFrom(vc: vc)
        self.lastTopMostFrom = lastTopMostFrom
        return translateImage(translateParam: translateParam, targetLanguage: nil, from: lastTopMostFrom)
    }
    func enableDetachResultDic() -> Bool {
        let enableDetachResultDic = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "lark_asl_config"))
        if let enable = enableDetachResultDic?["enable_detach_result_dic"] as? Bool {
            return enable
        }
        return true
    }

    private func translateImage(translateParam: ImageTranslateParameter, targetLanguage: String?, from: NavigatorFrom) {
        let entityId = translateParam.entityId
        let entityType = translateParam.entityType
        let isOrigin = translateParam.isOrigin
        let chatId = translateParam.chatId
        let completion = translateParam.completion
        let imageTranslateAbility = translateParam.imageTranslateAbility

        if isOrigin {
            ChatTrack.trackTransalteImage(position: "imgviewer", messageType: "other")
        } else {
            ChatTrack.trackUntranslateImage()
        }

        var type: EntityType?
        if let entityType = entityType {
            switch entityType {
            case .message:
                type = .message
            case .other:
                type = .other
            @unknown default:
                type = .other
            }
        }

        let withPrefixImageKey = translateParam.middleImageKey
        /// 这里需要端上特化处理下，去除带品质前缀的imageKey，否则server识别不了
        var fixedImageKey = translateParam.imageKey
        for prefix in imageQualityPrefixs {
            fixedImageKey = fixedImageKey.replacingOccurrences(of: prefix, with: "", options: .regularExpression)
        }

        if isOrigin {
            /// 原图 -> 译图
            if ChatTrack.enablePostTrack() {
                trackForClick(source: "image", type: -1)
            }
            /// 先判断是否属于目标语言冲突场景
            /// 条件：当且仅当 没有targetLanguage参数输入 && 图片原语种只有一个 && 并且包含用户翻译设置的全局目标语种
            if targetLanguage == nil &&
                imageTranslateAbility.srcLanguage.count == 1 &&
                imageTranslateAbility.srcLanguage.contains(dependency.translateLanguageSetting.targetLanguage) {
                NormalTranslateServiceImpl.logger.info("translate target language conflict occur in image<\(fixedImageKey)>")
                completion(nil, nil, nil, nil)
                selectLanguageCenter.showSelectDrawer(translateContext: .image(context: translateParam), from: from)
                if ChatTrack.enablePostTrack() {
                    trackForFail(source: "image",
                                 type: -1,
                                 failReason: "targetLang equal to sourceLang")
                }
                return
            }
            self.startTranslateTime = Date().timeIntervalSince1970
            sendTranslateImageRequest(
                entityId: entityId,
                chatId: chatId,
                entityType: type,
                translateScene: translateParam.translateScene,
                imageKey: fixedImageKey,
                withPrefixImageKey: withPrefixImageKey,
                isOrigin: isOrigin,
                targetLanguage: targetLanguage,
                completion: completion
            )
        } else {
            /// 译图 -> 原图
            guard let entityId = entityId, let type = type else {
                // 没有原图信息，属于异常case
                completion(nil, nil, nil, nil)
                NormalTranslateServiceImpl.logger.error("imageKey (\(fixedImageKey)) no origin image info")
                return
            }
            _ = dependency.translateAPI.getOriginImageContext(
                entityId: entityId,
                entityType: type,
                translateImageKey: fixedImageKey)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                // 如果是译转原，直接取原图信息
                NormalTranslateServiceImpl.logger.info("""
                    getOriginImageContext.response.info:
                    originKey = \(response.originImageKey),
                    originImageSetKey = \(response.originImageSet.origin.key),
                    originImagePropertyKey = \(response.originImageProperty.originKey)
                """)
                var originImageKey = ""
                if response.hasOriginImageSet {
                    completion(response.originImageSet, nil, withPrefixImageKey, nil)
                    originImageKey = response.originImageSet.origin.key
                } else if response.hasOriginImageProperty {
                    completion(nil, response.originImageProperty, withPrefixImageKey, nil)
                    originImageKey = response.originImageProperty.originKey
                } else if response.hasOriginImageKey {
                    // 6.11 临时修复方案：Rust 只传 origin key 回来，mock 一个 ImageProperty，后面会改造成传 ImageSet/ImageProperty
                    originImageKey = response.originImageKey
                    var imageProperty = RustPB.Basic_V1_RichTextElement.ImageProperty()
                    imageProperty.token = originImageKey
                    imageProperty.originKey = originImageKey
                    imageProperty.middleKey = originImageKey
                    imageProperty.thumbKey = originImageKey
                    completion(nil, imageProperty, withPrefixImageKey, nil)
                } else {
                    // 没有原图信息，属于异常case
                    completion(nil, nil, nil, nil)
                    NormalTranslateServiceImpl.logger.error("imageKey (\(fixedImageKey)) no origin image info")
                }
                if !originImageKey.isEmpty {
                    // 由于server的图片翻译设计上是绝对的(原到译)，因此端上无论是原到译，还是译到原，req的imageKey都传原图的key
                    var fixedOriginKey = originImageKey
                    for prefix in self?.imageQualityPrefixs ?? [] {
                        fixedOriginKey = fixedOriginKey.replacingOccurrences(of: prefix, with: "", options: .regularExpression)
                    }
                    self?.sendTranslateImageRequest(
                        entityId: entityId,
                        chatId: chatId,
                        entityType: type,
                        translateScene: translateParam.translateScene,
                        imageKey: fixedOriginKey,
                        withPrefixImageKey: translateParam.imageKey,
                        isOrigin: isOrigin,
                        targetLanguage: targetLanguage,
                        completion: completion
                    )
                }
            }, onError: { (error) in
                NormalTranslateServiceImpl.logger.error("getOriginImageContext.error = \(error.localizedDescription)")
                completion(nil, nil, nil, error)
            })
        }
    }

    private func sendTranslateImageRequest(entityId: String?,
                                           chatId: String?,
                                           entityType: EntityType?,
                                           translateScene: Im_V1_ImageTranslateScene,
                                           imageKey: String,
                                           withPrefixImageKey: String,
                                           isOrigin: Bool,
                                           targetLanguage: String?,
                                           completion: @escaping (ImageSet?, ImageProperty?, String?, Error?) -> Void) {
        NormalTranslateServiceImpl.logger.info("""
            translateImage.request.info:
            entityId = \(entityId ?? ""),
            entityType = \(entityType?.rawValue ?? EntityType.other.rawValue),
            imageKey = \(imageKey),
            isOrigin = \(isOrigin)
        """)
        imageTranslateDispose = dependency.translateAPI.translateImages(
            entityId: entityId,
            entityType: entityType,
            translateScene: translateScene,
            imageKeyInfos: [imageKey: isOrigin],
            targetLanguage: targetLanguage)
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (response) in
            guard let `self` = self else { return }
            let imageTranslationInfo = response.imagesTranslationInfo
            NormalTranslateServiceImpl.logger.info("""
                translateImages.response.info:
                entityId = \(entityId ?? ""),
                entityType = \(entityType?.rawValue ?? TranslateEntityType.other.rawValue),
                imageKey = \(imageKey),
                translatedImageInfo = \(String(describing: imageTranslationInfo.translatedImages[imageKey]?.translatedImageSet)),
                affectEntityToTranslate = \(response.affectEntityToTranslate),
                isTranslated = \(imageTranslationInfo.translatedImages[imageKey]?.isTranslated ?? false)
            """)
            if isOrigin {
                /// 原->译，取译图信息
                if let translatedImageInfo = imageTranslationInfo.translatedImages[imageKey] {
                    completion(translatedImageInfo.translatedImageSet, nil, withPrefixImageKey, nil)
                    if ChatTrack.enablePostTrack() {
                        if let translatedImageSet = translatedImageInfo.translatedImageSet as? ImageSet {
                            ChatTrack.trackForStableWatcher(domain: "asl_translate",
                                                            message: "asl_translate_response_show",
                                                            metricParams: ["duration": ceil((Date().timeIntervalSince1970 - (self.startTranslateTime ?? 0)) * 1000)],
                                                            categoryParams: [
                                                                "source": "image",
                                                                "type": -1
                                                            ])
                        } else {
                            self.trackForFail(source: "image", type: -1, failReason: "translatedImageSet is empty")
                        }
                    }
                } else {
                    /// 没有译图信息，属于异常case
                    completion(nil, nil, nil, nil)
                    NormalTranslateServiceImpl.logger.error("imageKey (\(imageKey)) no translated image info")
                    if ChatTrack.enablePostTrack() {
                        self.trackForFail(source: "image",
                                          type: -1,
                                          failReason: "imageKey (\(imageKey)) no translated image info")
                    }
                }
            }
            /// 如果 affectEntityToTranslate 为 true，则说明本次图片的翻译行为会影响到 entity 的翻译状态
            /// 端上需要对这条 entity 重新发起手动翻译请求，以保证多端的翻译数据是同步的

            /// 由于sdk遗失affectEntityToTranslate的返回逻辑，而目前产品逻辑为图片消息退出图片浏览器时不保留翻译状态
            /// affectEntityToTranslate返回为true时，图片消息将单独翻译，与产品逻辑相悖，因此对应注释手动发起翻译的流程

            /*
            if isOrigin &&
                response.affectEntityToTranslate &&
                !imageTranslationInfo.entityID.isEmpty {
                if case .messageEntity = imageTranslationInfo.entityType, let chatId = chatId {
                    self.translateMessageSilently(messageId: imageTranslationInfo.entityID,
                                                                      chatId: chatId,
                                                                      targetLanguage: targetLanguage)
                }
            }
             */
            self.imageTranslateDispose = nil
        }, onError: { [weak self] (error) in
            if ChatTrack.enablePostTrack() {
                self?.trackForFail(source: "image",
                                   type: -1,
                                   failReason: "translateImage.error = \(error.localizedDescription)")
            }
            NormalTranslateServiceImpl.logger.error("translateImage.error = \(error.localizedDescription)")
            completion(nil, nil, nil, error)
            self?.imageTranslateDispose = nil
        })
    }

    // MARK: - 取消最近的图片翻译行为
    func cancelImageTranslate() {
        imageTranslateDispose?.dispose()
    }

    // MARK: - 静默翻译/还原某一条简单含图消息
    func translateMessageSilently(messageId: String,
                                  chatId: String,
                                  targetLanguage: String? = nil,
                                  isFromMessageUpdate: Bool) {
        NormalTranslateServiceImpl.logger.info("""
            translateMessageSilently.messageId = \(messageId),
            translateMessageSilently.chatId = \(chatId)
        """)

        let messageSource = MessageSource.common(id: messageId)
        var context = MessageContext()
        context.messageID = messageId
        context.messageSource = messageSource
        context.chatID = chatId
        context.manualTargetLanguage = targetLanguage

        dependency.translateAPI.manualTranslate(contexts: [context], isFromMessageUpdate: isFromMessageUpdate).subscribe(onNext: { [weak self] (response) in
            guard let self = self else { return }
            if AIFeatureGating.multiLayerTranslate.isUserEnabled(userResolver: self.userResolver) {
                self.handleResponseV3(response: response)
            } else {
                self.handleResponse(contexts: [context], response: response)
            }
        }, onError: { [weak self] (error) in
            NormalTranslateServiceImpl.logger.error("translateMessageSilently.error = \(error.localizedDescription)")
            self?.handleError(contexts: [context])
        }).disposed(by: disposeBag)
    }

    // MARK: - 小工具
    /// chat是否需要自动检测
    private func chatNeedAutoTranslate(chat: Chat) -> Bool {
        // 1：密聊不支持自动翻译
        if chat.isCrypto { return false }
        return true
    }

    /// 该source场景下的message是否需要自动检测
    private func messageSourceNeedAutoTranslate(message: Message, source: MessageSource) -> Bool {
        // 消息是否需要自动检测
        func messageNeedAutoTranslate(message: Message) -> Bool {
            // 去掉撤回、删除的消息
            if message.isRecalled || message.isDeleted { return false }
            // 只传text、post、mergeForward消息给SDK
            guard message.type == .text || message.type == .post || message.type == .mergeForward || message.type == .image || TranslateControl.isTranslatableAudioMessage(message) ||
                    TranslateControl.isTranslatableMessageCardType(message) else { return false }
            return true
        }

        // 普通消息直接检测
        if source.sourceType == .commonMessage { return messageNeedAutoTranslate(message: message) }

        // 对于合并转发子消息，父消息是译文状态才发起检测逻辑，主要是为了处理以下badcase：
        // 一个合并转发消息被自动翻译了，SDK只会翻译前4条，这时候如果用户手动收起该合并转发消息的译文，那么端上只会传前4条给SDK，
        // 这时候前4条的'手动操作过'变为true，后面子消息为false；
        // 这时候用户如果前往合并转发详情页，如果不做此过滤的话，会错误的把后面的子消息都翻译出译文。
        guard let sourceMessage = source.sourceMessage, sourceMessage.translateState == .translated else { return false }

        // 检测子消息
        return messageNeedAutoTranslate(message: message)
    }

    /// 处理成功的请求，解析loading、error和翻译信息
    private func handleResponse(contexts: [MessageContext], response: RustPB.Im_V1_TranslateMessagesV3Response) {
        // 1、messageIds可以表示子消息id，messageSources和messageIds根据index一一对应；
        // 2、translatedMessageIds只是最外层的消息id，表示有译文、text/post应该回到原文的消息；
        // 3、传两条子消息进行翻译，那么response中不会有其他子消息的准确信息，需要自己判断出哪些子消息在本次请求中是回到原文。
        guard response.messageIds.count == response.messageSources.count else { return }

        var translateInfoMap: [String: TranslateInfo] = [:]
        // 先解析error
        response.translateErrors.forEach { (error) in
            // translateErrors中的id只是最外层的消息id
            guard error.messageSource.sourceType == .commonMessage else { return }

            var translateInfo = TranslateInfo(messageId: error.messageID)
            translateInfo.translateFaild = true
            translateInfoMap[error.messageID] = translateInfo
        }

        // mergeForwardMap: [父消息id: [子消息id]]，标识reponse里正在翻译的子消息
        var mergeForwardMap: [String: [String]] = [:]
        // 再处理common类型消息的loading
        for i in 0..<response.messageIds.count {
            let tempId = response.messageIds[i]
            let tempSource = response.messageSources[i]

            // common直接处理即可
            if tempSource.sourceType == .commonMessage {
                var translateInfo: TranslateInfo
                // 卡片需要在源语言与目标语言相同的情况在进入会话不收起译文，所以需要在计算 loading 属性的时候没有同步 displayRule 到 TranslateInfo 上，暂时只对卡片做这个逻辑（不影响其他类型的消息）
                if let message = response.entities.messages[tempId],
                   let info = response.entities.translateMessages[message.id],
                    TranslateControl.isTranslatableMessageCardType(message) {
                    translateInfo = TranslateInfo.parseTranslationInfo(
                        message: message,
                        translateInfo: info,
                        imageTranslationEnable: dependency.imageTranslateEnable)
                } else {
                    translateInfo = TranslateInfo(messageId: tempId)
                    translateInfo.state = .translating
                }
                translateInfoMap[tempId] = translateInfo
            } else {
                // mergeForward需要聚合
                var tempSources = mergeForwardMap[tempSource.sourceID] ?? []
                tempSources.append(tempId)
                mergeForwardMap[tempSource.sourceID] = tempSources
            }
        }

        var requestMergeForwardMap: [String: Set<String>] = [:]
        // needHandleMessageIds: 标记sdkdb中已有译文信息的messageIds
        // 得到还需要处理哪些translatedMessageIds，合并转发消息在处理loading时会顺带的去读取翻译信息
        var needHandleMessageIds = Set<String>(response.translatedMessageIds)
        contexts.forEach { (context) in
            guard context.messageSource.sourceType == .mergeForwardMessage else { return }

            var tempIds = requestMergeForwardMap[context.messageSource.sourceID] ?? []
            tempIds.insert(context.messageID)
            requestMergeForwardMap[context.messageSource.sourceID] = tempIds
        }
        // 再处理合并转发消息的翻译信息
        requestMergeForwardMap.forEach { (messageId, subMessageIds) in
            guard let message = response.entities.messages[messageId] else { return }

            needHandleMessageIds.remove(messageId)
            var translateInfo: TranslateInfo
            // 如果该messsageId在reponse中有子消息的翻译信息，就直接读取子消息的翻译信息，并标记子消息的翻译状态为.translated
            if let subInfos = response.entities.mergeForwardTranslateMessages[messageId]?.subTranslateMessages {
                translateInfo = TranslateInfo.mergeForwardInfo(
                    message: message,
                    subTranslateInfos: subInfos,
                    imageTranslationEnable: dependency.imageTranslateEnable
                )
            } else {
                translateInfo = TranslateInfo(messageId: messageId)
            }
            // 从mergeForwardMap得到该合并转发消息中需要loading的子消息
            (mergeForwardMap[messageId] ?? []).forEach { (messageId) in
                var tempInfo = TranslateInfo(messageId: messageId)
                tempInfo.state = .translating
                translateInfo.subTranslateInfos[messageId] = tempInfo
            }

            // requestIds去掉有译文&&loading的子消息，剩下的requestIds是回到原文的子消息
            var requestIds = Set<String>(subMessageIds)
            translateInfo.subTranslateInfos.keys.forEach({ requestIds.remove($0) })
            requestIds.forEach { (messageId) in
                var tempInfo = TranslateInfo(messageId: messageId)
                tempInfo.displayRule = .noTranslation
                tempInfo.state = .origin
                translateInfo.subTranslateInfos[messageId] = tempInfo
            }

            translateInfoMap[messageId] = translateInfo
        }
        // 再处理剩下的translatedMessageIds(理论上剩下都是commonMessages了)，读取译文信息 或 回到原文
        needHandleMessageIds.forEach { (messageId) in
            guard let message = response.entities.messages[messageId] else { return }

            // text/post/image/card
            // card 类型在发起前就会做更详尽的检查, 详见 isTranslatableMessageCardType 此处返回的数据,由于类型不同,为避免多余的数据转换, 仅判断类型
            if message.type == .text || message.type == .post || message.type == .image || TranslateControl.isTranslatableAudioMessage(message) ||
                TranslateControl.isTranslatableMessageCardType(message) {
                // 回到原文
                if message.translateMessageDisplayRule.rule == .noTranslation || message.translateMessageDisplayRule.rule == .unknownRule {
                    var info = TranslateInfo(messageId: messageId)
                    info.state = .origin
                    info.displayRule = .noTranslation
                    info.messageContentVersion = message.version.contentVersion
                    translateInfoMap[messageId] = info
                } else if let translateInfo = response.entities.translateMessages[message.id] {
                    // 有译文信息
                    let translateInfo = TranslateInfo.parseTranslationInfo(
                        message: message,
                        translateInfo: translateInfo,
                        imageTranslationEnable: dependency.imageTranslateEnable
                    )
                    translateInfoMap[messageId] = translateInfo
                } else {
                    // 错误处理
                    var info = TranslateInfo(messageId: messageId)
                    info.state = .origin
                    info.displayRule = .noTranslation
                    translateInfoMap[messageId] = info
                }
            }
            // mergeForward
            if message.type == .mergeForward {
                // 从mergeForwardTranslateMessages读到合并转发翻译信息
                if let translateInfos = response.entities.mergeForwardTranslateMessages[message.id]?.subTranslateMessages {
                    translateInfoMap[messageId] = TranslateInfo.mergeForwardInfo(
                        message: message,
                        subTranslateInfos: translateInfos,
                        imageTranslationEnable: dependency.imageTranslateEnable
                    )
                } else {
                    // 没有读到翻译信息，就表示所有子消息都需要回到原文
                    var info = TranslateInfo(messageId: messageId)
                    info.subTranslateInfos = message.content.mergeForwardContent.messages.reduce([:], { (result, message) -> [String: TranslateInfo] in
                        var result = result
                        var info = TranslateInfo(messageId: message.id)
                        info.state = .origin
                        info.displayRule = .noTranslation
                        result[message.id] = info
                        return result
                    })
                    translateInfoMap[messageId] = info
                }
            }
        }

        let errorsMessageIds = translateInfoMap.values
            .filter { $0.translateFaild }
            .map { $0.messageId }
        let translatingMessageIds = translateInfoMap.values
            .filter { $0.state == .translating }
            .map { $0.messageId }
        let toOriginMessageIds = translateInfoMap.values
            .filter { $0.state == .origin }
            .map { $0.messageId }
        let toTranslateMessageIds = translateInfoMap.values
            .filter { $0.state == .translated }
            .map { $0.messageId }
        NormalTranslateServiceImpl.logger.info("""
            translateMessage.response.info:
            errorsMessageIds = \(errorsMessageIds),
            translatingMessageIds = \(translatingMessageIds),
            toOriginMessageIds = \(toOriginMessageIds),
            toTranslateMessageIds = \(toTranslateMessageIds)
        """)

        self.dependency.pushTranslateInfo(info: PushTranslateInfo(translateInfoMap: translateInfoMap))
    }

    private func handleResponseV3(response: RustPB.Im_V1_TranslateMessagesV3Response) {
        /// loading的数据
        guard response.messageIds.count == response.messageSources.count else { return }

        var translateInfoMap: [String: TranslateInfo] = [:]
        /// 第一部分 处理loading消息
        /// 聚合mergeForward，key为外层消息id，value表示需要loading的消息path
        var loadingMFMap: [String: [[String]]] = [:]
        for i in 0..<response.messageIds.count {
            let tempId = response.messageIds[i]
            let tempSource = response.messageSources[i]

            // common直接处理即可
            if tempSource.sourceType == .commonMessage {
                var translateInfo: TranslateInfo
                // 卡片需要在源语言与目标语言相同的情况在进入会话不收起译文，所以需要在计算 loading 属性的时候没有同步 displayRule 到 TranslateInfo 上，暂时只对卡片做这个逻辑（不影响其他类型的消息）
                if let message = response.entities.messages[tempId],
                   let info = response.entities.translateMessages[message.id],
                    TranslateControl.isTranslatableMessageCardType(message) {
                    translateInfo = TranslateInfo.parseTranslationInfo(
                        message: message,
                        translateInfo: info,
                        imageTranslationEnable: dependency.imageTranslateEnable)
                } else {
                    translateInfo = TranslateInfo(messageId: tempId)
                    translateInfo.state = .translating
                }
                translateInfoMap[tempId] = translateInfo
            } else {
                // mergeForward需要聚合
                var tempPaths = loadingMFMap[tempSource.sourceID] ?? [[]]
                tempPaths.append(tempSource.messageIDPath)
                loadingMFMap[tempSource.sourceID] = tempPaths
            }

        }
        // 处理多层合并转发的loadding子消息
        loadingMFMap.forEach { (messageId, _) in
            var loadingInfo: TranslateInfo = TranslateInfo(messageId: messageId)
            (loadingMFMap[messageId] ?? []).forEach { (subMessagePath) in
                loadingInfo = TranslateInfo.merge(left: loadingInfo, right: transformPathToTranslateInfo(curIndex: 0,
                                                                                                         maxIndex: subMessagePath.count - 1,
                                                                                                         messagePaths: subMessagePath,
                                                                                                         state: .translating))
            }
            if !(loadingMFMap[messageId] ?? []).isEmpty {
                translateInfoMap[messageId] = loadingInfo
            }

        }
        /// 第二部分： 处理翻译/返回原文信息
        ///需要处理的合并转发消息，key表示外层id, value表示需处理的子消息path
        var translatedMFMap: [String: Set<[String]>] = [:]
        for i in 0..<response.translatedMessageSources.count {
            let curMessageSource = response.translatedMessageSources[i]
            let messageId = curMessageSource.sourceID
            if curMessageSource.sourceType == .commonMessage {
                guard let message = response.entities.messages[messageId] else { return }

                // text/post/image/card
                // card 类型在发起前就会做更详尽的检查, 详见 isTranslatableMessageCardType 此处返回的数据,由于类型不同,为避免多余的数据转换, 仅判断类型
                if message.type == .text || message.type == .post || message.type == .image || TranslateControl.isTranslatableAudioMessage(message) ||
                    TranslateControl.isTranslatableMessageCardType(message) {
                    // 回到原文
                    if message.translateMessageDisplayRule.rule == .noTranslation || message.translateMessageDisplayRule.rule == .unknownRule {
                        var info = TranslateInfo(messageId: messageId)
                        info.state = .origin
                        info.displayRule = .noTranslation
                        info.messageContentVersion = message.version.contentVersion
                        translateInfoMap[messageId] = info
                    } else if let translateInfo = response.entities.translateMessages[message.id] {
                        // 有译文信息
                        let translateInfo = TranslateInfo.parseTranslationInfo(
                            message: message,
                            translateInfo: translateInfo,
                            imageTranslationEnable: dependency.imageTranslateEnable
                        )
                        translateInfoMap[messageId] = translateInfo
                    } else {
                        // 错误处理
                        var info = TranslateInfo(messageId: messageId)
                        info.state = .origin
                        info.displayRule = .noTranslation
                        translateInfoMap[messageId] = info
                    }
                }
            } else {
                // 处理合并转发消息
                var tempPaths = translatedMFMap[messageId] ?? Set<[String]>()
                tempPaths.insert(curMessageSource.messageIDPath)
                translatedMFMap[messageId] = tempPaths
            }
        }

        /// 处理多层合并转发消息
        translatedMFMap.forEach { (messageId, _) in
            guard let message = response.entities.messages[messageId] else { return }
            var needHandlePath = translatedMFMap[messageId] ?? Set<[String]>()
            if let translateInfos = response.entities.mergeForwardTranslateMessages[messageId] {
                translateInfoMap[messageId] = TranslateInfo.multiMergeForwardInfo(
                    message: message,
                    subTranslateInfos: translateInfos,
                    imageTranslationEnable: dependency.imageTranslateEnable,
                    messagePath: [],
                    needHandlePath: &needHandlePath
                )
            }
            // 返回原文的子消息
            var toOriginTranslateInfo: TranslateInfo = TranslateInfo(messageId: messageId)
            for subMessagePath in needHandlePath {
                toOriginTranslateInfo = TranslateInfo.merge(left: toOriginTranslateInfo,
                                                            right: transformPathToTranslateInfo(curIndex: 0,
                                                                                                maxIndex: subMessagePath.count - 1,
                                                                                                messagePaths: subMessagePath,
                                                                                                state: .origin))
            }
            if !needHandlePath.isEmpty {
                translateInfoMap[messageId] = TranslateInfo.merge(left: translateInfoMap[messageId] ?? TranslateInfo(messageId: messageId),
                                                                  right: toOriginTranslateInfo)
            }
        }
        let errorsMessageIds = translateInfoMap.values
            .filter { $0.translateFaild }
            .map { $0.messageId }
        let translatingMessageIds = translateInfoMap.values
            .filter { $0.state == .translating }
            .map { $0.messageId }
        let toOriginMessageIds = translateInfoMap.values
            .filter { $0.state == .origin }
            .map { $0.messageId }
        let toTranslateMessageIds = translateInfoMap.values
            .filter { $0.state == .translated }
            .map { $0.messageId }
        NormalTranslateServiceImpl.logger.info("""
            translateMessage.response.info(V3):
            errorsMessageIds = \(errorsMessageIds),
            translatingMessageIds = \(translatingMessageIds),
            toOriginMessageIds = \(toOriginMessageIds),
            toTranslateMessageIds = \(toTranslateMessageIds)
        """)

        self.dependency.pushTranslateInfo(info: PushTranslateInfo(translateInfoMap: translateInfoMap))
    }

//     类似树的构造，函数功能为将合并转发消息的path转换为对应的translateInfo结构
//     path->[a, b, c] 表示合并转发消息a[b[c]]
    private func transformPathToTranslateInfo(curIndex: Int, maxIndex: Int, messagePaths: [String], state: Message.TranslateState) -> TranslateInfo {
        guard curIndex < maxIndex else { return TranslateInfo(messageId: "") }
        var translateInfo = TranslateInfo(messageId: messagePaths[curIndex])
        if curIndex + 1 == maxIndex {
            var tempInfo = TranslateInfo(messageId: messagePaths[curIndex + 1])
            tempInfo.state = state
            if state == .origin {
                tempInfo.displayRule = .noTranslation
            }
            translateInfo.subTranslateInfos[messagePaths[curIndex + 1]] = tempInfo
        } else if curIndex + 1 < maxIndex {
            translateInfo.subTranslateInfos[messagePaths[curIndex + 1]] = transformPathToTranslateInfo(
                curIndex: curIndex + 1,
                maxIndex: maxIndex,
                messagePaths: messagePaths,
                state: state
            )
        }
        return translateInfo

    }
    /// 处理失败的请求，所有contexts以翻译失败处理
    private func handleError(contexts: [MessageContext]) {
        var translateInfoMap: [String: TranslateInfo] = [:]
        // 按照sourceId聚合mergeForward类型的MessageContext，key为外层消息id
        var mergeForwardContext: [String: [MessageContext]] = [:]
        contexts.forEach { (context) in
            // common直接处理即可
            if context.messageSource.sourceType == .commonMessage {
                var translateInfo = TranslateInfo(messageId: context.messageID)
                translateInfo.translateFaild = true
                translateInfoMap[context.messageID] = translateInfo
            } else {
                // mergeForward需要聚合
                var tempErrors = mergeForwardContext[context.messageSource.sourceID] ?? []
                tempErrors.append(context)
                mergeForwardContext[context.messageSource.sourceID] = tempErrors
            }
        }
        // 处理聚合后的mergeForwardContext
        mergeForwardContext.forEach { (messageId, contexts) in
            var tempInfo = TranslateInfo(messageId: messageId)
            // 因为是聚合的所以只是合并转发消息部分子消息翻译失败，不能设置整体的翻译失败
            // tempInfo.translateFaild = true
            tempInfo.subTranslateInfos = contexts.reduce([:]) { (result, context) -> [String: TranslateInfo] in
                var result = result
                var subInfo = TranslateInfo(messageId: context.messageID)
                subInfo.translateFaild = true
                result[context.messageID] = subInfo
                return result
            }
            translateInfoMap[messageId] = tempInfo
        }

        self.dependency.pushTranslateInfo(info: PushTranslateInfo(translateInfoMap: translateInfoMap))
    }
    private func trackForClick(source: String, type: Any) {
        guard ChatTrack.enablePostTrack() else { return }
        ChatTrack.trackForStableWatcher(domain: "asl_translate",
                                        message: "asl_translate_click",
                                        metricParams: [:],
                                        categoryParams: [
                                            "source": source,
                                            "type": type
                                        ])
    }

    private func trackForFail(source: String, type: Any, failReason: String) {
        guard ChatTrack.enablePostTrack() else { return }
        ChatTrack.trackForStableWatcher(domain: "asl_translate",
                                       message: "asl_translate_fail",
                                       metricParams: [:],
                                       categoryParams: [
                                           "source": source,
                                           "type": type,
                                           "fail_reason": failReason
                                       ])
    }
}

// MARK: - URL中台Inline翻译
extension NormalTranslateServiceImpl {
    func translateURLInlines(translateParam: MessageTranslateParameter) {
        guard userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteTranslation)) else { return }
        inlineTranslateService.translateURLInlines(translateParam: translateParam)
    }

    func getTranslatedInline(translateParam: MessageTranslateParameter) -> InlinePreviewEntityBody {
        guard userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteTranslation)) else { return [:] }
        return inlineTranslateService.getTranslatedInline(translateParam: translateParam)
    }
}
