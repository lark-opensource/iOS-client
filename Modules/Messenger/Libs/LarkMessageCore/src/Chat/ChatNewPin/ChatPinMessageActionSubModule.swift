//
//  NewPinSubModule.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/7/18.
//

import UIKit
import LarkModel
import LarkMessageBase
import EENavigator
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkContainer
import LarkAccountInterface
import LarkCore
import LarkOpenChat
import LKCommonsLogging
import LarkAlertController
import UniverseDesignToast

// 新版的Pin和置顶二合一的按钮
public final class ChatPinMessageActionSubModule: MessageActionSubModule {
    private let disposeBag = DisposeBag()
    static let logger = Logger.log(ChatPinMessageActionSubModule.self, category: "MessageCore")

    public override var type: MessageActionType {
        return .chatPin
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        let chat = model.chat
        guard ChatNewPinConfig.supportPinMessage(chat: chat, self.context.userResolver.fg) else {
            return false
        }
        let cardSupportFg = self.userResolver.fg.staticFeatureGatingValue(with: "messagecard.pin.support")
        guard model.message.isSupportChatPin(cardSupportFg: cardSupportFg) else {
            return false
        }
        return ChatPinPermissionUtils.checkChatTabsMenuWidgetsPermission(chat: chat, userID: self.context.userResolver.userID, featureGatingService: self.context.userResolver.fg)
    }

    private var chatAPI: ChatAPI? {
        try? context.userResolver.resolve(assert: ChatAPI.self)
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        guard let pinService = try? self.userResolver.resolve(assert: ChatPinPageService.self) else { return nil }
        if (model.message.content as? PostContent)?.isGroupAnnouncement ?? false {
            if let announcementPinID = pinService.announcementPinID {
                return createUnpinAnnouncementItem(chat: model.chat, pinID: announcementPinID)
            } else {
                return createPinAnnouncementItem(chat: model.chat)
            }
        } else {
            if let pinId = pinService.getPinInfo(messageId: model.message.id)?.pinId {
                return createUnpinMessageItem(chat: model.chat, pinId: pinId, messageID: model.message.id)
            } else {
                return createPinMessageItem(model: model)
            }
        }
    }
}

// MARK: Pin和Unpin的API调用
extension ChatPinMessageActionSubModule {
    private func pinAnnouncement(chat: Chat) {
        guard let targetVC = context.targetVC,
              let chatID = Int64(chat.id) else { return }
        chatAPI?.createAnnouncementChatPin(chatId: chatID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak targetVC] _ in
                if let targetVC = targetVC {
                    UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_IM_SuperApp_ItemPinned_Toast, on: targetVC.view)
                }
                Self.logger.info("chatPinCardTrace pin announcement success chatId: \(chatID)")
            }, onError: { [weak targetVC] error in
                Self.logger.error("chatPinCardTrace pin announcement fail chatId: \(chatID)", error: error)
                if let targetVC = targetVC {
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_SuperApp_CantPin_Toast, on: targetVC.view, error: error)
                }
            })
            .disposed(by: disposeBag)
    }

    private func unPinAnnouncement(chat: Chat, pinID: Int64) {
        guard let targetVC = context.targetVC, let chatID = Int64(chat.id) else { return }
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_IM_NewPin_RemoveFromPinned_Title)
        if chat.type != .p2P {
            alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_IM_NewPin_RemoveFromPinned_Desc)
        }
        alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_NewPin_RemoveFromPinnedCancel_Button)
        alertController.addDestructiveButton(
            text: BundleI18n.LarkMessageCore.Lark_IM_NewPin_RemoveFromPinnedRemove_Button,
            dismissCompletion: { [weak self] in
                guard let self = self else { return }
                self.chatAPI?.deleteChatPin(chatId: chatID, pinId: pinID)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak targetVC] _ in
                        Self.logger.info("chatPinCardTrace delete pin announcement success chatID: \(chatID) chatID: \(chatID)")
                        if let targetVC = targetVC {
                            UDToast.showSuccess(with: BundleI18n.LarkMessageCore.Lark_IM_SuperApp_Unpinned_Toast, on: targetVC.view)
                        }
                    }, onError: { [weak targetVC] error in
                        Self.logger.error("chatPinCardTrace delete pin announcement fail chatID: \(chatID) chatID: \(chatID)", error: error)
                        if let targetVC = targetVC {
                            UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_SuperApp_CantPin_Toast, on: targetVC.view, error: error)
                        }
                    })
                    .disposed(by: self.disposeBag)
            }
        )
        userResolver.navigator.present(alertController, from: targetVC)
    }

    private func pin(message: Message, chat: Chat) {
        guard let targetVC = context.targetVC,
              let messageID = Int64(message.id),
              let chatID = Int64(chat.id) else { return }
        chatAPI?.createMessageChatPin(messageID: messageID, chatID: chatID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (_) in
                Self.logger.info("chatPinCardTrace add pin message success chatId: \(chatID) messageID: \(messageID)")
            }, onError: { [weak targetVC] (error) in
                Self.logger.error("chatPinCardTrace add pin message fail chatId: \(chatID) messageID: \(messageID)", error: error)
                if let targetVC = targetVC {
                    UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_NewPin_ActionFailedRetry_Toast, on: targetVC.view, error: error)
                }
            })
            .disposed(by: disposeBag)
    }

    private func unpin(chat: Chat, pinId: Int64, messageID: String) {
        guard let targetVC = context.targetVC, let chatId = Int64(chat.id) else { return }
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkMessageCore.Lark_IM_NewPin_RemoveFromPinned_Title)
        if chat.type != .p2P {
            alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_IM_NewPin_RemoveFromPinned_Desc)
        }
        alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_IM_NewPin_RemoveFromPinnedCancel_Button)
        alertController.addDestructiveButton(
            text: BundleI18n.LarkMessageCore.Lark_IM_NewPin_RemoveFromPinnedRemove_Button,
            dismissCompletion: { [weak self] in
                guard let self = self else { return }
                self.chatAPI?.deleteChatPin(chatId: chatId, pinId: pinId)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { _ in
                        Self.logger.info("chatPinCardTrace delete pin message success chatId: \(chatId) pinId: \(pinId) messageID: \(messageID)")
                    }, onError: { [weak targetVC] error in
                        Self.logger.error("chatPinCardTrace delete pin message fail chatId: \(chatId) pinId: \(pinId) messageID: \(messageID)", error: error)
                        if let targetVC = targetVC {
                            UDToast.showFailure(with: BundleI18n.LarkMessageCore.Lark_IM_NewPin_ActionFailedRetry_Toast, on: targetVC.view, error: error)
                        }
                    })
                    .disposed(by: self.disposeBag)
            }
        )
        userResolver.navigator.present(alertController, from: targetVC)
    }
}

// MARK: 菜单按钮构造函数
extension ChatPinMessageActionSubModule {
    private func createPinMessageItem(model: MessageActionMetaModel) -> MessageActionItem {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_SuperAppPin_Button,
                                 icon: BundleResources.Menu.menu_Chatpin,
                                 trackExtraParams: ["click": "new_pin", "target": "none"]) { [weak self] in
            self?.pin(message: model.message, chat: model.chat)
        }
    }

    private func createUnpinMessageItem(chat: Chat, pinId: Int64, messageID: String) -> MessageActionItem {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_SuperAppUnpin_Button,
                                 icon: BundleResources.Menu.menu_unPin,
                                 trackExtraParams: ["click": "new_unpin", "target": "none"]) { [weak self] in
            self?.unpin(chat: chat, pinId: pinId, messageID: messageID)
        }
    }

    private func createPinAnnouncementItem(chat: Chat) -> MessageActionItem {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_SuperAppPin_Button,
                                 icon: BundleResources.Menu.menu_Chatpin,
                                 trackExtraParams: ["click": "new_pin", "target": "none"]) { [weak self] in
            self?.pinAnnouncement(chat: chat)
        }
    }

    private func createUnpinAnnouncementItem(chat: Chat, pinID: Int64) -> MessageActionItem {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_IM_SuperAppUnpin_Button,
                                 icon: BundleResources.Menu.menu_unPin,
                                 trackExtraParams: ["click": "new_unpin", "target": "none"]) { [weak self] in
            self?.unPinAnnouncement(chat: chat, pinID: pinID)
        }
    }
}
