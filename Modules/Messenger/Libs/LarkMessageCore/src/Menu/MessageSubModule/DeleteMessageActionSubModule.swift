//
//  Delete.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/5.
//

import Foundation
import LarkMessageBase
import LarkModel
import LarkCore
import RxSwift
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import LarkOpenChat
import UniverseDesignToast
import LarkActionSheet
import EENavigator
import LarkUIKit
import LarkAlertController
import LarkSendMessage

public final class DeleteMessageActionSubModule: MessageActionSubModule {
    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var messageAPI: MessageAPI?
    @ScopedInjectedLazy private var videoMessageSendService: VideoMessageSendService?

    public override var type: MessageActionType {
        return .delete
    }

    static let logger = Logger.log(DeleteMessageActionSubModule.self, category: "DeleteMessageActionSubModule")

    private let disposeBag = DisposeBag()

    private lazy var deleteMessageService: DeleteMessageService? = {
        guard let messageAPI = messageAPI else {
            return nil
        }
        return DeleteMessageServiceImpl(controller: self.context.pageAPI ?? UIViewController(),
                                        messageAPI: messageAPI,
                                        nav: self.context.nav)
    }()

    private lazy var pushCenter: PushNotificationCenter? = {
        return try? context.userResolver.userPushCenter
    }()

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    /// 删除
    private func handle(message: Message, chat: Chat) {
        let msgInfos = [(message.id, message.type)]
        deleteMessageService?.delete(messageIds: [message.id]) { result in
            if result {
                IMTracker.Msg.DeleteConfirm.Click(chat, msgInfos)
            }
        }
    }

    /// 假消息删除
    private func quasiHandle(message: Message, chat: Chat) {
        guard let targetVC = self.context.pageAPI else { return }
        let alertController = LarkAlertController()
        alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_Legacy_ChatDeleteTip)
        alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_Cancel)
        alertController.addDestructiveButton(
            text: BundleI18n.LarkMessageCore.Lark_Legacy_LarkDelete,
            dismissCompletion: { [weak self] in
                self?.processQuasiDelete(message: message)
            })

        self.navigator.present(alertController, from: targetVC)
    }

    /// Ephemeral消息删除
    public func ephemeralhandle(message: Message, chat: Chat) {
        guard let targetVC = self.context.pageAPI else { return }
        let alertController = LarkAlertController()

        alertController.setContent(text: BundleI18n.LarkMessageCore.Lark_Legacy_ChatDeleteTip)

        alertController.addSecondaryButton(text: BundleI18n.LarkMessageCore.Lark_Legacy_Cancel)

        alertController.addDestructiveButton(
            text: BundleI18n.LarkMessageCore.Lark_Legacy_LarkDelete,
            dismissCompletion: { [weak self] in
                self?.processEphemeralDelete(message: message)
            })

        self.navigator.present(alertController, from: targetVC)
    }

    private func processQuasiDelete(message: Message) {
        guard let targetVC = self.context.pageAPI else { return }
        let hud = UDToast.showLoading(
            with: BundleI18n.LarkMessageCore.Lark_Legacy_BaseUiLoading,
            on: targetVC.view,
            disableUserInteraction: true
        )
        videoMessageSendService?.cancel(messageCID: message.id, isDelete: true)
        messageAPI?
            .delete(quasiMessageId: message.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                hud.remove()
                guard let `self` = self else { return }
                //QuasiMessage实体没有isdelete字段,删除后rust没法push,需要客户端自己push
                message.isDeleted = true
                self.pushCenter?.post(PushChannelMessage(message: message))
                self.pushCenter?.post(PushChannelMessages(messages: [message]))
            }, onError: { [weak targetVC] error in
                guard let targetVC = targetVC else { return }
                hud.showFailure(
                    with: BundleI18n.LarkMessageCore.Lark_Legacy_ChatViewFailHideMessage,
                    on: targetVC.view,
                    error: error
                )
            })
            .disposed(by: self.disposeBag)
    }

    private func processEphemeralDelete(message: Message) {
        guard let targetVC = self.context.pageAPI else { return }
        let hud = UDToast.showLoading(
            with: BundleI18n.LarkMessageCore.Lark_Legacy_BaseUiLoading,
            on: targetVC.view,
            disableUserInteraction: true
        )
        messageAPI?
            .deleteEphemeral(messageId: message.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                hud.remove()
                guard let `self` = self else { return }
                //EphemeralMessage实体没有isdelete字段,删除后rust没法push,需要客户端自己push
                message.isDeleted = true
                self.pushCenter?.post(PushChannelMessage(message: message))
                self.pushCenter?.post(PushChannelMessages(messages: [message]))
            }, onError: { [weak targetVC] error in
                guard let window = targetVC?.view.window else { return }
                hud.showFailure(
                    with: BundleI18n.LarkMessageCore.Lark_Legacy_ChatViewFailHideMessage,
                    on: window,
                    error: error
                )
            })
            .disposed(by: self.disposeBag)
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        return model.message.threadMessageType != .threadReplyMessage
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        return MessageActionItem(text: BundleI18n.LarkMessageCore.Lark_Legacy_MenuDelete,
                                 icon: BundleResources.Menu.menu_delete,
                                 trackExtraParams: ["click": "delete",
                                                    "target": "none"]) { [weak self] in
            if model.message.isEphemeral {
                self?.ephemeralhandle(message: model.message, chat: model.chat)
            } else if model.message.localStatus != .success {
                self?.quasiHandle(message: model.message, chat: model.chat)
            } else {
                self?.handle(message: model.message, chat: model.chat)
            }
        }
    }
}
