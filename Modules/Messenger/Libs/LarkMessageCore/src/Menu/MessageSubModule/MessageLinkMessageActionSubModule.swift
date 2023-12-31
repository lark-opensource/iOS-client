//
//  MessageLink.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/7.
//

import RxSwift
import LarkEMM
import LarkCore
import ServerPB
import LarkModel
import LarkSetting
import LarkContainer
import LarkMessageBase
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignToast
import LarkOpenChat
import LarkSensitivityControl

public class MessageLinkMessageActionSubModule: MessageActionSubModule {
    static let logger = Logger.log(MessageLinkMessageActionSubModule.self, category: "MessageLinkMessageActionSubModule")

    @ScopedInjectedLazy var messageAPI: MessageAPI?
    let disposeBag = DisposeBag()

    public override var type: MessageActionType {
        return .messageLink
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        if context.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.disable_announcement.client"),
           (model.message.content as? PostContent)?.isGroupAnnouncement ?? false {
            return false
        }
        return true
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
            return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_CopyMessageLink_Button,
                                     icon: BundleResources.Menu.menu_message_link_copy,
                                     trackExtraParams: ["click": "copy_msg_link",
                                                        "target": "none"]) { [weak self] in
                self?.handle(model: model)
            }
    }

    public func handle(model: MessageActionMetaModel) {
    }

    public static func getFromID(scene: ContextScene, messages: [Message], chat: Chat) -> String {
        switch scene {
        case .newChat, .messageDetail, .mergeForwardDetail, .pin:
            return chat.id
        case .replyInThread, .threadChat, .threadDetail, .threadPostForwardDetail:
            if let threadID = messages.first?.threadId {
                return threadID
            }
            assertionFailure("no messages")
            return chat.id
        }
    }

    public static func getLinkFrom(scene: ContextScene) -> ServerPB_Messages_PutMessageLinkRequest.LinkFrom {
        switch scene {
        case .newChat, .messageDetail, .mergeForwardDetail, .pin:
            return .chat
        case .threadChat, .threadDetail, .threadPostForwardDetail:
            return .thread
        case .replyInThread:
            return .messageThread
        }
    }

    public static func canCopyMessageLink(scene: ContextScene, chat: Chat, fg: FeatureGatingService) -> Bool {
        if chat.isCrypto || chat.isPrivateMode {
            return false
        }
        if (scene == .newChat || scene == .messageDetail) && fg.staticFeatureGatingValue(with: "im.messenger.message_link") {
            return true
        }
        if scene == .replyInThread, fg.staticFeatureGatingValue(with: "im.messenger.thread_link") {
            return true
        }
        return false
    }
}

public final class ChatMessageLinkMessageActionSubModule: MessageLinkMessageActionSubModule {
    public override static func canInitialize(context: MessageActionContext) -> Bool {
        let featureGatingService = try? context.userResolver.resolve(assert: FeatureGatingService.self)
        return featureGatingService?.dynamicFeatureGatingValue(with: "im.messenger.message_link") ?? false
    }

    public override func handle(model: MessageActionMetaModel) {
        guard let targetVC = self.context.pageAPI else { return }
        let chat = model.chat
        let message = model.message
        Self.logger.info("putMessageLink start in chat: chatID = \(chat.id), messageID = \(message.id)")
        guard !chat.enableRestricted(.copy) else {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: targetVC.view)
            return
        }

        messageAPI?.putMessageLink(fromID: chat.id, from: .chat, copiedIDs: [message.id])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak targetVC] response in
                SCPasteboard.generalPasteboard().string = response.tokenURL
                Self.logger.info("putMessageLink success: \(response.token)")
                if let view = targetVC?.view {
                    UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_IM_MessageLinkCopied_Toast, on: view)
                }
            }, onError: { [weak targetVC] error in
                Self.logger.error("putMessageLink failed", error: error)
                if let view = targetVC?.view {
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_MessageLinkUnableCopy_Toast, on: view)
                }
            }).disposed(by: disposeBag)
    }
}

public final class ReplyThreadMessageLinkMessageActionSubModule: MessageLinkMessageActionSubModule {
    private let pasteboardToken = "LARK-PSDA-messenger-replyInThread-menu-copyMessageLink-permission"

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        let featureGatingService = try? context.userResolver.resolve(assert: FeatureGatingService.self)
        return featureGatingService?.dynamicFeatureGatingValue(with: "im.messenger.thread_link") ?? false
    }

    public override func handle(model: MessageActionMetaModel) {
        guard let targetVC = self.context.pageAPI else { return }
        let chat = model.chat
        let message = model.message
        Self.logger.info("putMessageLink start in replyThread: chatID = \(chat.id), threadID = \(message.threadId), messageID = \(message.id)")
        guard !chat.enableRestricted(.copy) else {
            UDToast.showTips(with: BundleI18n.LarkMessageCore.Lark_IM_RestrictedMode_CopyForwardNotAllow_Toast, on: targetVC.view)
            return
        }

        messageAPI?.putMessageLink(fromID: message.threadId, from: .messageThread, copiedIDs: [message.id])
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak targetVC] response in
                guard let self = self else { return }
                let config = PasteboardConfig(token: Token(self.pasteboardToken))
                do {
                    try SCPasteboard.generalUnsafe(config).string = response.tokenURL
                    Self.logger.info("putMessageLink success: \(response.token)")
                    if let view = targetVC?.view {
                        UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_IM_MessageLinkCopied_Toast, on: view)
                    }
                } catch {
                    // 复制失败兜底逻辑
                    Self.logger.error("PasteboardConfig init fail token:\(self.pasteboardToken)")
                    if let view = targetVC?.view {
                        UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_MessageLinkUnableCopy_Toast, on: view)
                    }
                }
            }, onError: { [weak targetVC] error in
                Self.logger.error("putMessageLink failed", error: error)
                if let view = targetVC?.view {
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_MessageLinkUnableCopy_Toast, on: view)
                }
            }).disposed(by: disposeBag)
    }
}
