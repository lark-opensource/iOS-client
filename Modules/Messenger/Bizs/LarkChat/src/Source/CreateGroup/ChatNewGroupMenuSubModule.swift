//
//  ChatNewGroupMenuSubModule.swift
//  LarkChat
//
//  Created by liuxianyu on 2023/1/4.
//

import UIKit
import Foundation
import LarkOpenFeed
import LarkOpenChat
import LarkOpenIM
import EENavigator
import LarkNavigator
import LarkMessengerInterface
import LarkSDKInterface
import LarkModel
import LarkUIKit
import LarkContainer
import RxSwift
import UniverseDesignIcon
import RustPB

final class ChatNewGroupMenuSubModule: FeedFloatMenuSubModule {
    public override class var name: String { return "ChatNewGroupMenuSubModule" }

    public override var type: FloatMenuOptionType {
        return .newGroup
    }

    public override class func canInitialize(context: FeedFloatMenuContext) -> Bool {
        return true
    }

    public override func canHandle(model: FeedFloatMenuMetaModel) -> Bool {
        return true
    }

    public override func handler(model: FeedFloatMenuMetaModel) -> [Module<FeedFloatMenuContext, FeedFloatMenuMetaModel>] {
        return [self]
    }

    public override func menuOptionItem(model: FeedFloatMenuMetaModel) -> FloatMenuOptionItem? {
        return FloatMenuOptionItem(
            icon: UDIcon.getIconByKey(.groupOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2),
            title: BundleI18n.LarkChat.Lark_Legacy_ConversationStartGroupChat,
            type: type
        )
    }

    public override func didClick() {
        presentGroupChatController()
    }

    func presentGroupChatController() {
        guard let from = context.feedContext.page else { return }
        let navigator = context.userResolver.navigator
        let createGroupBlock = makeCreateGroupBlock(from: from)
        let body = CreateGroupBody(createGroupBlock: createGroupBlock, from: .plusMenu)
        navigator.present(
            body: body,
            from: from,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    private func makeCreateGroupBlock(from: UIViewController) -> (Chat?, UIViewController, Int64, [AddExternalContactModel], RustPB.Im_V1_CreateChatResponse.ChatPageLinkResult?) -> Void {
        return { (chat, vc, cost, notFriendContacts, _) in
            vc.dismiss(animated: true, completion: { [weak from, weak self] in
                guard let chat = chat, let from = from, let self = self else { return }
                let createGroupToChatInfo = CreateGroupToChatInfo(
                    way: .new_group,
                    syncMessage: false,
                    messageCount: 0,
                    memberCount: Int(chat.userCount),
                    cost: Int64(cost))
                let body = ChatControllerByChatBody(
                    chat: chat,
                    fromWhere: .feed,
                    extraInfo: [CreateGroupToChatInfo.key: createGroupToChatInfo])
                let context: [String: Any] = [
                    FeedSelection.contextKey: FeedSelection(feedId: chat.id,
                                                            selectionType: .skipSame)
                ]

                self.context.userResolver.navigator.showDetailOrPush(
                    body: body,
                    context: context,
                    wrap: LkNavigationController.self,
                    from: from,
                    completion: { [weak self, weak from] (_, _) in
                        // 创群成功后present加好友弹窗
                        self?.presentAddContactAlert(
                            chatId: chat.id,
                            isNotFriendContacts: notFriendContacts,
                            from: from)
                    })
            })
        }
    }

    private func presentAddContactAlert(chatId: String,
                                        isNotFriendContacts: [AddExternalContactModel],
                                        from: UIViewController?) {
        guard !isNotFriendContacts.isEmpty, let from = from else { return }
        let navigator = context.userResolver.navigator
        // 人数为1使用单人alert
        if isNotFriendContacts.count == 1 {
            let contact = isNotFriendContacts[0]
            var source = Source()
            source.sourceType = .chat
            source.sourceID = chatId
            let addContactBody = AddContactApplicationAlertBody(userId: isNotFriendContacts[0].ID,
                                                                chatId: chatId,
                                                                source: source,
                                                                displayName: contact.name,
                                                                targetVC: from,
                                                                businessType: .groupConfirm)
            navigator.present(body: addContactBody, from: from)
            return
        }
        // 人数大于1使用多人alert
        let dependecy = MSendContactApplicationDependecy(source: .chat)
        let addContactApplicationAlertBody = MAddContactApplicationAlertBody(
                                contacts: isNotFriendContacts,
                                source: .createGroup,
                                dependecy: dependecy,
                                businessType: .groupConfirm)
        navigator.present(body: addContactApplicationAlertBody, from: from)
    }
}
