//
//  TranslateInfoPushHandler.swift
//  LarkMessageCore
//
//  Created by zc09v on 2019/4/14.
//
import Foundation
import RxSwift
import LarkModel
import LarkContainer
import LarkSDKInterface
import LarkSetting
import RustPB
import LarkSearchCore
import LarkMessengerInterface
import LKCommonsLogging

final class TranslateInfoPushHandlerFactory: NSObject, PushHandlerFactory {
    func createHandler(channelId: String, needCachePush: Bool, userResolver: UserResolver) -> PushHandler {
        return TranslateInfoPushHandler(needCachePush: needCachePush, userResolver: userResolver)
    }
}

final class TranslateInfoPushHandler: PushHandler {
    let disposeBag: DisposeBag = DisposeBag()
    private static let logger = Logger.log(TranslateInfoPushHandler.self, category: "TranslateService")
    @ScopedInjectedLazy private var translateService: NormalTranslateService?
    override func startObserve() throws {
        try self.userResolver.userPushCenter.observable(for: PushTranslateInfo.self).subscribe(onNext: { [weak self] (push) in
            var messageIds = Set(push.translateInfoMap.keys.map { $0 } + push.translateInlineIDs)
            push.translateInfoMap.forEach { (_, translateInfo) in
                messageIds = messageIds.union(self?.getMFMessageId(push: translateInfo) ?? Set<String>())
            }
            self?.dataSourceAPI?.update(messageIds: Array(messageIds), doUpdate: { [weak self] data in
                guard let self = self else { return nil }
                var messageUpdated = false
                var inlineUpdated = false
                var singleMFUpdated = false
                Self.logger.info("""
                    Start update pushTranslateInfo:
                    message.id >> \(data.message.id)
                """)
                /// Message翻译
                if let translateInfo = push.translateInfoMap[data.message.id] {
                    messageUpdated = self.updateTranslateMessage(message: data.message, info: translateInfo)
                }
                /// 合并转发单条子消息翻译
                if let translateInfo = self.getMFMessageInfo(message: data.message, push: push) {
                    singleMFUpdated = self.updateTranslateMessage(message: data.message, info: translateInfo)
                }
                /// Inline翻译
                if !push.translateInlineIDs.isEmpty {
                    inlineUpdated = self.updateTranslateInline(message: data.message, translateInlineIDs: push.translateInlineIDs)
                }
                Self.logger.info("""
                    End update pushTranslateInfo:
                    message.id >> \(data.message.id),
                    messageUpdated >> \(messageUpdated),
                    inlineUpdated >> \(inlineUpdated),
                    singleMFUpdated >> \(singleMFUpdated)
                """)
                if LarkMessageCoreTracker.enablePostTrack(), !messageUpdated, !inlineUpdated, !singleMFUpdated {
                    LarkMessageCoreTracker.trackForStableWatcher(domain: "asl_translate",
                                                                 message: "asl_translate_fail",
                                                                 metricParams: [:],
                                                                 categoryParams: [
                                                                    "source": "message",
                                                                    "type": data.message.type.rawValue,
                                                                    "fail_reason": "not support message type"
                                                                ])
                }
                return (messageUpdated || inlineUpdated || singleMFUpdated) ? data : nil
            })
        }).disposed(by: disposeBag)
    }

    /// 拿到合并转发子消息对应的translateInfo
    private func getMFMessageInfo(message: Message, push: PushTranslateInfo) -> TranslateInfo? {
        var messageIdPath = [message.id]
        var tempMessage = message
        while let fatherMessage = tempMessage.fatherMFMessage {
            messageIdPath.insert(fatherMessage.id, at: 0)
            tempMessage = fatherMessage
        }
        Self.logger.info("""
            Update pushTranslateInfo(getSingleMFPath):
            messageIdPath >> \(messageIdPath)
        """)
        /// 根据path从父TranslateInfo得到子消息对应的translateInfo
        if let translateInfo = push.translateInfoMap[messageIdPath[0]] {
            return getMFTranslateInfo(curIndex: 1, path: messageIdPath, translateInfo: translateInfo)
        }
        return nil
    }

    private func getMFTranslateInfo(curIndex: Int, path: [String], translateInfo: TranslateInfo) -> TranslateInfo? {
        guard curIndex < path.count,
              let subTranslateInfo = translateInfo.subTranslateInfos[path[curIndex]] else { return nil }

        if curIndex == path.count - 1 {
            return subTranslateInfo
        } else {
            return getMFTranslateInfo(curIndex: curIndex + 1, path: path, translateInfo: subTranslateInfo)
        }
    }

    private func getMFMessageId(push: TranslateInfo) -> Set<String> {
        var messageIds = Set<String>()
        messageIds.insert(push.messageId)
        push.subTranslateInfos.forEach { (_, subTranslateInfo) in
            messageIds = messageIds.union(getMFMessageId(push: subTranslateInfo))
        }
        return messageIds
    }

    private func updateTranslateMessage(message: Message, info: TranslateInfo) -> Bool {
        func trackForTranslateShow() {
            guard LarkMessageCoreTracker.enablePostTrack() != false else { return }
            if message.translateState == .translated, !info.translateFaild {
                var startTranslateTime: TimeInterval = 0
                if let translateService = (try? self.userResolver.resolve(assert: NormalTranslateService.self)) {
                    startTranslateTime = translateService.startTranslateTime ?? 0
                }
                LarkMessageCoreTracker.trackForStableWatcher(domain: "asl_translate",
                                                             message: "asl_translate_response_show",
                                                             metricParams: ["duration": ceil((Date().timeIntervalSince1970 - startTranslateTime) * 1000)],
                                                             categoryParams: [
                                                                "source": "message",
                                                                "type": message.type.rawValue
                                                            ])
            }
        }
        func trackForTranslateError(failReason: String) {
            guard LarkMessageCoreTracker.enablePostTrack() != false else { return }
            LarkMessageCoreTracker.trackForStableWatcher(domain: "asl_translate",
                                                         message: "asl_translate_fail",
                                                         metricParams: [:],
                                                         categoryParams: [
                                                            "fail_reason": failReason,
                                                            "source": "message",
                                                            "type": message.type.rawValue
                                                        ])
        }
        let fg = self.userResolver.fg
        // text/post/image
        if message.type == .text ||
            message.type == .post ||
            TranslateControl.isTranslatableAudioMessage(message) ||
            (message.type == .image && fg.staticFeatureGatingValue(with: .init(key: .imageMessageTranslateEnable))) ||
            TranslateControl.isTranslatableMessageCardType(message) {
            Self.logger.info("""
                Update pushTranslateInfo(message):
                message.id >> \(message.id),
                message.type >>\(message.type),
                message.version >> \(message.contentVersion),
                message.path >> \(message.mergeMessageIdPath),
                message.translateContent.isEmpty >> \(info.translateContent.isNil)
            """)
            self.updateTranslationInfo(message: message, translateInfo: info)
            if info.translateFaild {
                trackForTranslateError(failReason: "translate faild")
            } else if info.displayRule == .onlyTranslation || info.displayRule == .withOriginal {
                if info.translateContent == nil {
                    trackForTranslateError(failReason: "translate content is nil")
                } else if info.messageContentVersion != message.contentVersion {
                    trackForTranslateError(failReason: "translate message version is not same")
                } else {
                    trackForTranslateShow()
                }
            }
            return true
        }
        // mergeForward
        if message.type == .mergeForward {
            if AIFeatureGating.multiLayerTranslate.isUserEnabled(userResolver: userResolver) {
                self.updateMultiMergeForwardInfo(message: message, translateInfo: info)
            } else {
                self.updateMergeForwardInfo(message: message, translateInfo: info)
            }
            if info.translateFaild {
                trackForTranslateError(failReason: "translate faild")
            } else if message.displayRule == .onlyTranslation, message.translateState == .translated {
                trackForTranslateShow()
            } else {
                trackForTranslateError(failReason: "no message translated")
            }
            return true
        }
        return false
    }

    /// 更新mergeForward多层消息的翻译相关内容, 返回值表示（是否有子消息loading, 是否有子消息translated)
    private func updateMultiMergeForwardInfo(message: Message, translateInfo: TranslateInfo?) -> (Bool, Bool) {
        guard let content = message.content as? MergeForwardContent, let translateInfo = translateInfo else { return (false, false) }

        var haveLoading = false, haveTranslated = false
        content.messages.forEach { (subMessage) in
            if subMessage.type == .mergeForward {
                let subMerForwardState = updateMultiMergeForwardInfo(message: subMessage,
                                            translateInfo: translateInfo.subTranslateInfos[subMessage.id])
                haveLoading = haveLoading || subMerForwardState.0
                haveTranslated = haveTranslated || subMerForwardState.1
            }
            // 只在text/post/image类型的子消息时才填充翻译信息
            guard canFillTranslationInfo(subMessage) else { return }

            if let translateInfo = translateInfo.subTranslateInfos[subMessage.id] {
                self.updateTranslationInfo(message: subMessage, translateInfo: translateInfo)
            }
            if !haveLoading, subMessage.translateState == .translating {
                haveLoading = true
            }
            if !haveTranslated && (subMessage.displayRule == .onlyTranslation || subMessage.displayRule == .withOriginal) {
                haveTranslated = true
            }
        }

        // 实时变更合并转发消息本身的翻译状态，任何子消息在loading，则展示loading
        if haveLoading {
            message.translateState = .translating
        } else {
            // 任何子消息有译文则展示译文、被翻译
            message.displayRule = haveTranslated ? .onlyTranslation : .noTranslation
            message.translateState = haveTranslated ? .translated : .origin
        }
        Self.logger.info("""
            Update pushTranslateInfo(mergeForward):
            message.id >>\(message.id),
            message.type >>\(message.type),
            message.version >> \(message.contentVersion),
            message.path >> \(message.mergeMessageIdPath),
            message.state >> \(message.translateState)
        """)
        return (haveLoading, haveTranslated)
    }

    private func canFillTranslationInfo(_ message: Message) -> Bool {
        let fg = self.userResolver.fg
        return message.type == .text ||
        message.type == .post ||
        TranslateControl.isTranslatableAudioMessage(message) ||
        (message.type == .image && fg.staticFeatureGatingValue(with: .init(key: .imageMessageTranslateEnable))) ||
        TranslateControl.isTranslatableMessageCardType(message)
    }

    /// 更新mergeForward消息的翻译相关内容
    private func updateMergeForwardInfo(message: Message, translateInfo: TranslateInfo) {
        guard let content = message.content as? MergeForwardContent else { return }

        // 合并转发消息翻译失败了，则所有子消息以翻译失败处理
        if translateInfo.translateFaild {
            content.messages.forEach { (subMessage) in
                // 只在text/post/image类型的子消息时才填充翻译信息
                guard canFillTranslationInfo(subMessage) else { return }

                // 此时translateInfo.subTranslateInfos为空，我们自己构造一个表示错误的TranslateInfo执行后续逻辑
                var translateInfo = TranslateInfo(messageId: subMessage.id)
                translateInfo.translateFaild = true
                self.updateTranslationInfo(message: subMessage, translateInfo: translateInfo)
            }
            // 任何子消息有译文则展示译文&&被翻译
            let haveTranslated = content.messages.contains(where: { $0.displayRule == .onlyTranslation || $0.displayRule == .withOriginal })
            message.displayRule = haveTranslated ? .onlyTranslation : .noTranslation
            message.translateState = haveTranslated ? .translated : .origin
            return
        }

        // 覆盖子消息的翻译信息
        content.messages.forEach { (subMessage) in
            // 只在text/post/image类型的子消息时才填充翻译信息
            guard canFillTranslationInfo(subMessage) else { return }

            if let translateInfo = translateInfo.subTranslateInfos[subMessage.id] {
                self.updateTranslationInfo(message: subMessage, translateInfo: translateInfo)
            }
        }
        // 实时变更合并转发消息本身的翻译状态，任何子消息在loading，则展示loading
        if content.messages.contains(where: { $0.translateState == .translating }) {
            message.translateState = .translating
        } else {
            // 任何子消息有译文则展示译文、被翻译
            let haveTranslated = content.messages.contains(where: { $0.displayRule == .onlyTranslation || $0.displayRule == .withOriginal })
            message.displayRule = haveTranslated ? .onlyTranslation : .noTranslation
            message.translateState = haveTranslated ? .translated : .origin
        }
    }

    /// 更新text/post/image消息的翻译相关内容
    private func updateTranslationInfo(message: Message, translateInfo: TranslateInfo) {
        // 对于翻译失败且原文也没有翻译内容的, 应该不再显示翻译角标, 不然会显示原文带角标
        // 这里应该是 bug, 不止卡片,其他类型消息也需要这个逻辑, 目前单独为消息卡片实现
        if TranslateControl.isTranslatableMessageCardType(message),
            translateInfo.translateFaild && message.translateContent == nil {
            message.translateState = .origin
            return
        }
        // 翻译失败了，内容保持不变
        if translateInfo.translateFaild {
            switch message.displayRule {
            case .noTranslation, .unknownRule:
                message.translateState = .origin
            case .onlyTranslation, .withOriginal:
                message.translateState = .translated
            @unknown default:
                assert(false, "new value")
                break
            }
            return
        }

        /// 消息更新，后端push到sdk，sdk再push到前端，此时会给到前端ONLY_TRANSLATION or WITH_ORIGINAL的display_rule，前端check translation信息，如果为空或者不为空但是translation信息中版本号小于消息中版本号，则UI层面如有译文就不再渲染，同时触发新的翻译请求。
        if translateInfo.displayRule == .onlyTranslation || translateInfo.displayRule == .withOriginal {
            if translateInfo.translateContent == nil {
                message.displayRule = .noTranslation
                translateService?.translateMessage(messageId: message.id,
                                                  source: .common(id: message.id),
                                                  chatId: message.chatID,
                                                  targetLanguage: nil,
                                                  isFromMessageUpdate: true)
            } else if isNeedRepeatTranslateMessage(messageContentVersion: translateInfo.messageContentVersion, contentVersion: message.contentVersion) {
                message.displayRule = .noTranslation
                translateService?.translateMessage(messageId: message.id,
                                                  source: .common(id: message.id),
                                                  chatId: message.chatID,
                                                  targetLanguage: nil,
                                                  isFromMessageUpdate: true)
            } else {
                message.displayRule = translateInfo.displayRule
            }
        } else {
            message.displayRule = translateInfo.displayRule
        }
        message.translateState = translateInfo.state
        message.translateLanguage = translateInfo.translateLanguage
        message.translateContent = translateInfo.translateContent
    }

    private func isNeedRepeatTranslateMessage(messageContentVersion: Int32, contentVersion: Int32) -> Bool {
        var enableRepeatTranslateMessage = true
        let aslConfig = try? self.userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "lark_asl_config"))
        if let enable = aslConfig?["enable_repeat_translate_messsage"] as? Bool {
            enableRepeatTranslateMessage = enable
        }
        if enableRepeatTranslateMessage {
            return messageContentVersion < contentVersion
        } else {
            return messageContentVersion != contentVersion
        }
    }

    private func updateTranslateInline(message: Message, translateInlineIDs: [String]) -> Bool {
        if translateInlineIDs.contains(message.id) {
            return true
        }
        // 合并转发只翻译一层即可
        if message.type == .mergeForward, let content = message.content as? MergeForwardContent {
            let subIDs = content.messages.map({ $0.id })
            return subIDs.contains(where: { translateInlineIDs.contains($0) })
        }
        return false
    }
}
/// 用于向各个界面传递翻译信息展示出翻译内容；判断优先级：(translateFaild = true) > (state == .translating) > other
public struct TranslateInfo {
    /// 消息id
    public var messageId: String
    /// 消息是否翻译失败
    public var translateFaild = false
    /// 该消息的展示规则：原文、译文、原文+译文
    public var displayRule: RustPB.Basic_V1_DisplayRule = .noTranslation
    /// 该消息译文语言
    public var translateLanguage: String = ""
    /// 该消息译文内容
    public var translateContent: MessageContent?
    /// 该消息翻译状态：原文、loading、已翻译
    public var state: Message.TranslateState = .origin
    /// 该消息如果是一条合并转发消息,此属性包括对应的合并转发子消息
    /// 1、当translateFaild=true时无内容，并且只有所有子消息都翻译失败了合并转发消息才算失败；
    /// 2、只会包含text/post消息的翻译信息。
    public var subTranslateInfos: [String: TranslateInfo] = [:]
    // 记录合并转发子消息的path
    public var mergeForwardMessagePath: [String] = []
    public var messageContentVersion: Int32 = 0

    public init(messageId: String) {
        self.messageId = messageId
    }

    public static func merge(left: TranslateInfo, right: TranslateInfo) -> TranslateInfo {
        guard left.messageId == right.messageId else { return right }
        var resultInfo = right
        left.subTranslateInfos.forEach { (subMessageID, subLeftInfo) in
            if let subRightInfo = resultInfo.subTranslateInfos[subMessageID] {
                resultInfo.subTranslateInfos[subMessageID] = merge(left: subLeftInfo, right: subRightInfo)
            } else {
                resultInfo.subTranslateInfos[subMessageID] = subLeftInfo
            }
        }
        return resultInfo
    }

    /// 对 Text/Post/Image/Card 类型消息的TranslateInfo内容进行修正
    private mutating func fixTranslateContent() {
        // 如果展示规则需要译文那么必须要有翻译内容，否则重置状态为原文
        if self.displayRule == .onlyTranslation || self.displayRule == .withOriginal {
            if self.translateContent == nil {
                self.displayRule = .noTranslation
                self.state = .origin
                self.translateLanguage = ""
            }
        }
        // 如果是需要展示原文，那么翻译状态应该为原文
        if self.displayRule == .unknownRule || self.displayRule == .noTranslation {
            self.state = .origin
            self.translateLanguage = ""
            self.translateContent = nil
        }
    }

    /// 从translateInfo中解析出text/post/image消息的翻译信息，外层需保证message是一个text/post/image类型的消息
    public static func parseTranslationInfo(
        message: Basic_V1_Message,
        translateInfo: Basic_V1_TranslateInfo?,
        imageTranslationEnable: Bool
    ) -> TranslateInfo {
        var result = TranslateInfo(messageId: message.id)
        // 组装翻译信息
        if let translateInfo = translateInfo {
            switch message.type {
            case .text:
                result.translateContent = TextContent.transform(pb: translateInfo)
            case .post:
                result.translateContent = PostContent.transform(pb: translateInfo)
            case .image where imageTranslationEnable:
                result.translateContent = ImageContent.transform(pb: translateInfo)
            case .card where TranslateControl.isTranslatableMessageCardType(message):
                result.translateContent = CardContent.transform(pb: translateInfo)
            case .audio where AIFeatureGating.audioMessageTranslation.isEnabled:
                result.translateContent = AudioContent.transform(pb: translateInfo)
            @unknown default: break
            }
            result.translateLanguage = translateInfo.language
        }
        // 三端同步 display_rule 的时候，在收起译文的时候会收到一个 push，不能简单的直接写死 state 是 translated，需要根据 display_rule 判断下
        result.state = message.translateMessageDisplayRule.rule == .noTranslation || message.translateMessageDisplayRule.rule == .unknownRule ? .origin : .translated
        result.displayRule = message.translateMessageDisplayRule.rule
        result.messageContentVersion = translateInfo?.messageContentVersion ?? 0
        return result
    }

    /// 从subTranslateInfos中解析出合并转发消息的部分子消息的翻译信息，外层需保证message是一个mergeForward类型的消息
    public static func mergeForwardInfo(
        message: Basic_V1_Message,
        subTranslateInfos: [String: Basic_V1_TranslateInfo],
        imageTranslationEnable: Bool
    ) -> TranslateInfo {
        // 从subTranslateInfos反向从子messages读取，即可只解析部分子消息的翻译信息
        let subMessageMap = message.content.mergeForwardContent.messages
            .reduce([:]) { (result, message) -> [String: Basic_V1_Message] in
                var result = result
                result[message.id] = message
                return result
            }
        // 存储子消息的翻译信息
        var resultInfos: [String: TranslateInfo] = [:]
        subTranslateInfos.forEach { (subMessageId, subTranslateInfo) in
            // 此subTranslateInfo是否对应着某个子消息
            guard let subMessage = subMessageMap[subMessageId] else { return }
            // 只在text/post/image类型的子消息时才填充翻译信息
            guard subMessage.type == .text ||
                    subMessage.type == .post ||
                    TranslateControl.isTranslatableAudioMessage(subMessage) ||
                    (subMessage.type == .image && imageTranslationEnable) ||
                    TranslateControl.isTranslatableMessageCardType(message) else {
                return
            }

            // 组装翻译信息
            var result = TranslateInfo(messageId: subMessageId)
            switch subMessage.type {
            case .text:
                result.translateContent = TextContent.transform(pb: subTranslateInfo)
            case .post:
                result.translateContent = PostContent.transform(pb: subTranslateInfo)
            case .image where imageTranslationEnable:
                result.translateContent = ImageContent.transform(pb: subTranslateInfo)
            case .card where TranslateControl.isTranslatableMessageCardType(message):
                result.translateContent = CardContent.transform(pb: subTranslateInfo)
            case .audio where AIFeatureGating.audioMessageTranslation.isEnabled:
                result.translateContent = AudioContent.transform(pb: subTranslateInfo)
            @unknown default: break
            }
            result.translateLanguage = subTranslateInfo.language
            result.state = .translated
            result.displayRule = subMessage.translateMessageDisplayRule.rule
            result.messageContentVersion = subTranslateInfo.messageContentVersion ?? 0
            resultInfos[subMessageId] = result
        }

        // 拼接合并转发消息本身翻译信息，这里只设置subTranslateInfos，在界面数据源处实时的根据子消息决定合并转发消息展示什么状态
        var result = TranslateInfo(messageId: message.id)
        result.subTranslateInfos = resultInfos
        return result
    }

    public static func multiMergeForwardInfo(
        message: Basic_V1_Message,
        subTranslateInfos: Basic_V1_SubTranslateInfo,
        imageTranslationEnable: Bool,
        messagePath: [String],
        needHandlePath: inout Set<[String]>
    ) -> TranslateInfo {
        var resultInfo = TranslateInfo(messageId: message.id)

        var mergeForwardMessagePath = messagePath
        mergeForwardMessagePath.append(message.id)
        resultInfo.mergeForwardMessagePath = mergeForwardMessagePath

        // 取出message结构中对应的所有子消息
        let subMessageMap = message.content.mergeForwardContent.messages
            .reduce([:]) { (result, message) -> [String: Basic_V1_Message] in
                var result = result
                result[message.id] = message
                return result
            }
        // 组装所有的子消息（text/post/card)
        subTranslateInfos.subTranslateMessages.forEach { (subMessageId, subTranslateInfo) in
            // 判断response中返回的消息确实存在
            guard let subMessage = subMessageMap[subMessageId] else { return }
            guard subMessage.type == .text ||
                    subMessage.type == .post ||
                    TranslateControl.isTranslatableAudioMessage(subMessage) ||
                    (subMessage.type == .image && imageTranslationEnable) ||
                    TranslateControl.isTranslatableMessageCardType(message) else {
                return
            }

            // 组装翻译信息
            var result = TranslateInfo(messageId: subMessageId)
            var subMessagePath = mergeForwardMessagePath
            subMessagePath.append(subMessageId)
            needHandlePath.remove(subMessagePath)
            result.mergeForwardMessagePath = subMessagePath
            switch subMessage.type {
            case .text:
                result.translateContent = TextContent.transform(pb: subTranslateInfo)
            case .post:
                result.translateContent = PostContent.transform(pb: subTranslateInfo)
            case .image where imageTranslationEnable:
                result.translateContent = ImageContent.transform(pb: subTranslateInfo)
            case .card where TranslateControl.isTranslatableMessageCardType(message):
                result.translateContent = CardContent.transform(pb: subTranslateInfo)
            case .audio where AIFeatureGating.audioMessageTranslation.isEnabled:
                result.translateContent = AudioContent.transform(pb: subTranslateInfo)
            @unknown default: break
            }
            result.translateLanguage = subTranslateInfo.language
            result.state = .translated
            result.displayRule = subMessage.translateMessageDisplayRule.rule
            result.messageContentVersion = subTranslateInfo.messageContentVersion ?? 0

            resultInfo.subTranslateInfos[subMessageId] = result
        }
        // 组装子合并转发消息
        subTranslateInfos.subMfTranslateMessages.forEach {(subMfTranslateMessage) in
            let subMessageId = subMfTranslateMessage.subMessageID
            let subTranslateInfo = subMfTranslateMessage.subTranslateMessages
            // 判断response中返回的消息确实存在
            guard let subMessage = subMessageMap[subMessageId] else {
                return
            }

            resultInfo.subTranslateInfos[subMessageId] = multiMergeForwardInfo(
                message: subMessage,
                subTranslateInfos: subTranslateInfo,
                imageTranslationEnable: imageTranslationEnable,
                messagePath: mergeForwardMessagePath,
                needHandlePath: &needHandlePath
            )

        }
        return resultInfo

    }
}
