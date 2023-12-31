//
//  ImageTranslationPushHandler.swift
//  LarkMessageCore
//
//  Created by shizhengyu on 2020/3/31.
//

import Foundation
import RustPB
import LarkRustClient
import LarkModel
import LarkFeatureGating
import LarkContainer
import LarkMessengerInterface
import LKCommonsLogging
import LarkKAFeatureSwitch
import LarkFeatureSwitch

/// 更新图片翻译信息的PushMessage
struct UpdateImageTranslationInfo: PushMessage {
    /// 收到sdk push推送获取到的最新的imageTranslationInfo信息
    public let imageTranslationInfo: ImageTranslationInfo

    public init(imageTranslationInfo: ImageTranslationInfo) {
        self.imageTranslationInfo = imageTranslationInfo
    }
}

typealias PushImageTranslationInfo = Im_V1_PushImageTranslationInfo

final class ImageTranslationPushHandler: UserPushHandler {
    private enum AffectAdditionKey {
        static let chatId: String = "chat_id"
    }

    private static var logger = Logger.log(ImageTranslationPushHandler.self,
                                           category: "Rust.PushHandler.ImageTranslationPushHandler")
    private lazy var pushCenter: PushNotificationCenter? = {
        return try? self.userResolver.userPushCenter
    }()
    @ScopedInjectedLazy private var translateService: NormalTranslateService?

    func process(push message: PushImageTranslationInfo) throws {
        let fg = self.userResolver.fg
        guard fg.staticFeatureGatingValue(with: .init(switch: .suiteTranslation)) else { return }
        guard fg.staticFeatureGatingValue(with: .init(key: .imageMessageTranslateEnable)) else { return }

        let entityType = message.imagesTranslationInfo.entityType
        let entityId = message.imagesTranslationInfo.entityID
        let affectToOrigin = message.affectEntityToOrigin
        let imageKey = message.imagesTranslationInfo.translatedImages.keys.first ?? ""
        let isTranslated = message.imagesTranslationInfo.translatedImages[imageKey]?.isTranslated ?? false
        ImageTranslationPushHandler.logger.info("""
            PushImageTranslationInfo.info:
            entityId >> \(entityId),
            entityType >> \(entityType.rawValue),
            imageKey >> \(imageKey),
            affectToOrigin >> \(affectToOrigin),
            isTranslated >> \(isTranslated)
            """)

        /// 如果是消息实体，则会更新message的imageTranslationInfo信息
        if entityType == .messageEntity {
            self.updateMessageImageTranslationInfo(message)
        }
        /// side effect
        if message.affectEntityToOrigin && entityType == .messageEntity {
            /// 这里只会处理译图->原图的图片翻译行为需要更新消息的情况
            /// 原因详见 https://bytedance.feishu.cn/docs/doccnK6WMBAMeD5C3JJ1Zabcn8d#
            self.translateMessageToOrigin(message)
        }
    }

    /// 以下类型的消息会随着图片在查看器中从译图回到原图时被更新翻译状态
    /// 1. 纯图片消息
    /// 2. 仅单图无文本的富文本消息
    private func translateMessageToOrigin(_ message: PushImageTranslationInfo) {
        let imageTranslationInfo = message.imagesTranslationInfo
        let messageId = imageTranslationInfo.entityID
        let affectAdditionInfo = message.affectAdditionInfo
        let chatId = affectAdditionInfo[AffectAdditionKey.chatId]
        if !messageId.isEmpty, let chatId = chatId {
            translateService?.translateMessageSilently(messageId: messageId,
                                                      chatId: chatId,
                                                      targetLanguage: nil,
                                                      isFromMessageUpdate: false)
        }
    }

    private func updateMessageImageTranslationInfo(_ message: PushImageTranslationInfo) {
        let imageTranslationInfo = message.imagesTranslationInfo
        let messageId = imageTranslationInfo.entityID
        if !messageId.isEmpty {
            /// 发送更新imageTranslationInfo的client通知
            pushCenter?.post(UpdateImageTranslationInfo(imageTranslationInfo: imageTranslationInfo))
        }
    }
}
