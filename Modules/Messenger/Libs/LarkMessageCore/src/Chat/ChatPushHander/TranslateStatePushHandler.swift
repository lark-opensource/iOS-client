//
//  TranslateStatePushHandler.swift
//  Lark
//
//  Created by 姚启灏 on 2018/7/11.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LarkModel
import LKCommonsLogging
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkKAFeatureSwitch
import LarkFeatureGating
import LarkStorage
import LarkSearchCore
import UniverseDesignToast
import EENavigator
import LarkSetting

/// messageId -> 翻译信息
public struct PushTranslateInfo: PushMessage {
    /// key只会是最外层消息id，如一条合并转发消息A的子消息B需要loading，则push最外层key是A.id，然后把B翻译信息填充到A.subTranslateInfos
    public let translateInfoMap: [String: TranslateInfo]
    /// 已经拉取到URL中台Inline翻译信息的messageID
    public let translateInlineIDs: [String]

    public init(translateInfoMap: [String: TranslateInfo] = [:],
                translateInlineIDs: [String] = []) {
        self.translateInfoMap = translateInfoMap
        self.translateInlineIDs = translateInlineIDs
    }
}

typealias PushTranslateState = RustPB.Im_V1_PushTranslateState

/// 1、PushTranslateState只有译文的翻译信息，区分不出来回到原文的消息，回到原文的消息只在response中存在（回到原文不需要三端同步）；
/// 2、message_id是最外层的消息；
/// 3、如果有translate_errors则表示该次push只会有error，不需要解析其他的属性，translate_errors中的message_id可以表示子消息；
/// 4、如果3不成立则逐个遍历message_id，并且从各id从entities得到message再做后续解析；
/// 5、3和4只会有一个成立，也就是说push要么全是error要么全是翻译信息。
final class TranslateStatePushHandler: UserPushHandler {

    private static var logger = Logger.log(TranslateStatePushHandler.self, category: "Rust.PushHandler")
    private lazy var pushCenter: PushNotificationCenter? = {
        return try? self.userResolver.userPushCenter
    }()
    @ScopedInjectedLazy private var translateService: NormalTranslateService?

    func process(push message: PushTranslateState) throws {
        guard self.userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteTranslation)) else { return }
        if message.translateErrors.isEmpty {
            // 只需要解析翻译信息
            self.handleTranslateState(state: message)
        } else {
            // 只需要解析error
            self.handleErrorState(state: message)
        }
    }

    /// 处理state中的error，error.messageID可以表示子消息id
    private func handleErrorState(state: PushTranslateState) {
        var translateInfoMap: [String: TranslateInfo] = [:]
        /// 按照sourceId聚合mergeForward类型的error，
        /// key为外层消息id，value表示需要Error的消息path
        var mergeForwardError: [String: [[String]]] = [:]
        var longWordsTranslateError: RustPB.Im_V1_TranslateError?
        state.translateErrors.forEach { (error) in
            // common直接处理即可
            if error.messageSource.sourceType == .commonMessage {
                var translateInfo = TranslateInfo(messageId: error.messageID)
                translateInfo.translateFaild = true
                translateInfoMap[error.messageID] = translateInfo
                TranslateStatePushHandler.logger.info("""
                    PushTranslateState.error.info:
                    messageId >> \(error.messageID)
                    errorCode >> \(error.errorCode)
                """)
                // 发请求时做了语言优化处理，如果收到252代码，说明用户选择了和消息语言相同的语种，直接收起译文
                if error.errorCode == 252, state.isUserManualTranslate {
                    translateService?.hideTranslation(messageId: error.messageID, source: MessageSource.transform(pb: error.messageSource), chatId: error.chatID)
                } else if error.errorCode == 255, state.isUserManualTranslate, !state.isFromMessageUpdate {
                    showTranslateErrorToast(error: error)
                }
            } else {
                // mergeForward需要聚合
                var tempErrorPaths = mergeForwardError[error.messageSource.sourceID] ?? [[]]
                tempErrorPaths.append(error.messageSource.messageIDPath)
                mergeForwardError[error.messageSource.sourceID] = tempErrorPaths
                if error.errorCode == 255, state.isUserManualTranslate, !state.isFromMessageUpdate {
                    longWordsTranslateError = error
                }
            }
        }

        if let longWordsTranslateError = longWordsTranslateError {
            showTranslateErrorToast(error: longWordsTranslateError)
        }

        // 处理聚合后的mergeForwardError
        mergeForwardError.forEach { (messageId, _) in
            var tempInfo = TranslateInfo(messageId: messageId)
            Self.logger.info("""
                PushTranslateState.error.info(mergeForward):
                mergeForwardMessageId >> \(messageId)
                subMessageId >> \(mergeForwardError[messageId])
            """)
            mergeForwardError[messageId]?.forEach { (subMessagePath) in
                tempInfo = TranslateInfo.merge(
                    left: tempInfo,
                    right: transformErrorPathToTranslateInfo(curIndex: 0, maxIndex: subMessagePath.count - 1, messagePaths: subMessagePath)
                )
            }
            translateInfoMap[messageId] = tempInfo
        }

        self.pushCenter?.post(PushTranslateInfo(translateInfoMap: translateInfoMap))
    }

    private func showTranslateErrorToast(error: RustPB.Im_V1_TranslateError) {
        guard enableShowTranslateErrorToast() else { return }
        DispatchQueue.main.async {
            if let topView = self.userResolver.navigator.mainSceneTopMost?.view {
                UDToast.showTips(with: error.errorMsg, on: topView)
            }
        }
    }

    private func enableShowTranslateErrorToast() -> Bool {
        let aslConfig = try? self.userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "lark_asl_config"))
        if let enable = aslConfig?["enable_show_translate_error_toast"] as? Bool {
            return enable
        }
        return true
    }

    private func transformErrorPathToTranslateInfo(curIndex: Int, maxIndex: Int, messagePaths: [String]) -> TranslateInfo {
        guard curIndex < maxIndex else { return TranslateInfo(messageId: "") }
        var translateInfo = TranslateInfo(messageId: messagePaths[curIndex])
        if curIndex + 1 == maxIndex {
            var tempInfo = TranslateInfo(messageId: messagePaths[curIndex + 1])
            tempInfo.translateFaild = true
            translateInfo.subTranslateInfos[messagePaths[curIndex + 1]] = tempInfo
        } else if curIndex + 1 < maxIndex {
            translateInfo.subTranslateInfos[messagePaths[curIndex + 1]] = transformErrorPathToTranslateInfo(
                curIndex: curIndex + 1,
                maxIndex: maxIndex,
                messagePaths: messagePaths
            )
        }
        return translateInfo
    }
    /// 处理state中的翻译信息，state.messageID只可能是外层消息的id
    private func handleTranslateState(state: PushTranslateState) {
        let translateInfoMap = state.messageID.reduce([:]) { (result, messageId) -> [String: TranslateInfo] in
            guard let message = state.entities.messages[messageId] else { return result }
            let fg = self.userResolver.fg
            var result = result
            // text/post/image
            if message.type == .text || message.type == .post || TranslateControl.isTranslatableAudioMessage(message) ||
                (message.type == .image && fg.staticFeatureGatingValue(with: .init(key: .imageMessageTranslateEnable))) ||
                TranslateControl.isTranslatableMessageCardType(message) {
                let translateInfo = state.entities.translateMessages[message.id]
                TranslateStatePushHandler.logger.info("""
                        PushTranslateState.info.normalMessage:
                        message.messageId >> \(messageId)
                        message.hasTranslateContent >> \(translateInfo?.hasContent)
                        translateContent.version >> \(translateInfo?.messageContentVersion)
                        message.translatedImages.keys >> \(translateInfo?.imageTranslationInfo.translatedImages.keys)
                        message.translatedImages.imageSets >> \(translateInfo?.imageTranslationInfo.translatedImages.values.map { $0.translatedImageSet })
                        message.translatedImages.imageSets >> \(translateInfo?.imageTranslationInfo.translatedImages.values.map { $0.translatedImageSet })
                        message.translateMessageDisplayRule >> \(message.translateMessageDisplayRule.rule.rawValue)
                    """)
                result[messageId] = TranslateInfo.parseTranslationInfo(
                    message: message,
                    translateInfo: translateInfo,
                    imageTranslationEnable: fg.staticFeatureGatingValue(with: .init(key: .imageMessageTranslateEnable)))
            }
            // mergeForward
            if message.type == .mergeForward {
                // 从mergeForwardTranslateMessages读到合并转发翻译信息
                if let translateInfos = state.entities.mergeForwardTranslateMessages[message.id] {
                    translateInfos.subTranslateMessages.forEach { (keyValues) in
                        TranslateStatePushHandler.logger.info("""
                            PushTranslateState.info.mergeForwardMessage:
                            subMessage.messageId >> \(keyValues.key)
                            subMessage.translatedImages.keys >> \(keyValues.value.imageTranslationInfo.translatedImages.keys)
                            subMessage.translatedImages.imageSets >> \(keyValues.value.imageTranslationInfo.translatedImages.values.map { $0.translatedImageSet })
                            subMessage.contentVersion: >> \(keyValues.value.messageContentVersion)
                        """)
                    }
                    translateInfos.subMfTranslateMessages.forEach { (subMFMessage) in
                        TranslateStatePushHandler.logger.info("""
                            PushTranslateState.info.subMergeForwardMessage:
                            subMessage.messageId >> \(subMFMessage.subMessageID)
                        """)
                    }
                    if AIFeatureGating.multiLayerTranslate.isUserEnabled(userResolver: userResolver) {
                        var needHandlePath = Set<[String]>()
                        result[messageId] = TranslateInfo.multiMergeForwardInfo(
                            message: message,
                            subTranslateInfos: translateInfos,
                            imageTranslationEnable: fg.staticFeatureGatingValue(with: .init(key: .imageMessageTranslateEnable)),
                            messagePath: [],
                            needHandlePath: &needHandlePath
                        )
                    } else {
                        result[messageId] = TranslateInfo.mergeForwardInfo(
                            message: message,
                            subTranslateInfos: translateInfos.subTranslateMessages,
                            imageTranslationEnable: fg.staticFeatureGatingValue(with: .init(key: .imageMessageTranslateEnable))
                        )
                    }

                }
            }
            return result
        }

        self.pushCenter?.post(PushTranslateInfo(translateInfoMap: translateInfoMap))
    }
}
