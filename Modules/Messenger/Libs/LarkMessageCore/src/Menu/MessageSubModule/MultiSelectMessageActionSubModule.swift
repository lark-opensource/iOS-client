//
//  MultiSelect.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/2/7.
//

import Foundation
import LarkModel
import RxSwift
import LarkOpenChat
import LarkMessengerInterface
import LarkContainer
import LarkSDKInterface
import LarkMessageBase

public class MultiSelectMessageActionSubModule: MessageActionSubModule, DeleteMessageService {

    @ScopedInjectedLazy private var chatterManager: ChatterManagerProtocol?
    @ScopedInjectedLazy private var chatMicroAppDependency: ChatMicroAppDependency?

    public func delete(messageIds: [String], callback: ((Bool) -> Void)?) {
        try? self.context.userResolver.resolve(assert: ChatMessagesOpenService.self).delete(messageIds: messageIds, callback: callback)
    }

    private let disposeBag = DisposeBag()
    private var _handler: MultiSelectHandler?
    private var handler: MultiSelectHandler? {
        if _handler == nil {
            let messagesService = try? self.context.userResolver.resolve(assert: ChatMessagesOpenService.self)
            guard let messagesService = messagesService,
                  let pageAPI = messagesService.pageAPI as? ChatPageAPI,
                  let scence = messagesService.dataSource?.scene,
                  let currentChatter = chatterManager?.currentChatter else {
                return nil
            }
            _handler = MultiSelectHandler(userResolver: self.userResolver,
                                          currentChatter: currentChatter,
                                          scene: scence,
                                          chatPageAPI: pageAPI,
                                          chatDeleteMessageService: self,
                                          takeActionV2: { [weak messagesService, weak self] chatId, messageIds in
                guard let targetVC = messagesService?.pageAPI, let chatMicroAppDependency = self?.chatMicroAppDependency else { return }
                chatMicroAppDependency.takeMessageActionV2(chatId: chatId,
                                                           messageIds: messageIds,
                                                           isMultiSelect: true,
                                                           targetVC: targetVC)
            })
        }
        return _handler
    }

    public override var type: MessageActionType {
        return .multiSelect
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    private func handle(message: Message, chat: Chat) {
        self.handler?.handle(message: message, chat: chat, params: [:])
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        return true
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let text = true ? BundleI18n.LarkMessageCore.Lark_Legacy_MenuMultiSelect : BundleI18n.LarkMessageCore.Lark_Chat_NewMultiselect
        return MessageActionItem(text: text,
                                 icon: BundleResources.Menu.menu_multi,
                                 trackExtraParams: ["click": "multi_select",
                                                    "target": "im_msg_multi_select_view"]) { [weak self] in
            self?.handle(message: model.message, chat: model.chat)
        }
    }
}

public protocol ChatMicroAppDependency {
    func takeMessageActionV2(chatId: String, messageIds: [String], isMultiSelect: Bool, targetVC: UIViewController)
}
