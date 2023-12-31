//
//  ChatChatterPushHandler.swift
//  Lark
//
//  Created by Yuguo on 2017/12/28.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import LarkModel
import LarkAccountInterface

final class ChatChatterPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }
    private var currentChatterId: String? { (try? userResolver.resolve(assert: PassportUserService.self))?.user.userID }

    func process(push message: RustPB.Im_V1_PushChatChattersResponse) {
        let chatId = message.chat.id
        let chatters = message.entity.chatChatters[chatId]?.chatters.map({ (item) -> Chatter in
            Chatter.transform(pb: item.value)
        }) ?? []
        let chatterIds = message.entity.chatChatters[chatId]?.chatters.map({ $0.key }) ?? []

        switch message.type {
        case .addChatter:
            self.pushCenter?
                .post(PushChatChatter(chatId: chatId,
                                      chatters: chatters,
                                      id2DepartmentsDic: message.entity.departments,
                                      type: .append))
        case .deleteChatter:
            if chatterIds.contains(self.currentChatterId ?? "") || chatterIds.contains(message.chat.anonymousID) {
                self.pushCenter?
                    .post(PushRemoveMeFromChannel(channelId: chatId, isDissolved: message.chat.isDissolved))
                if message.chat.chatMode == .threadV2,
                    !message.chat.isPublicV2 {
                    // only not public need push PushRemoveMeForRecommendList for delete threadMessage from recommend list
                    self.pushCenter?.post(PushRemoveMeForRecommendList(channelId: chatId))
                }
            }
            self.pushCenter?
                .post(PushChatChatter(chatId: chatId,
                                      chatters: chatters,
                                      id2DepartmentsDic: message.entity.departments,
                                      type: .delete))
        case .deleteMe:
            self.pushCenter?
                .post(PushRemoveMeFromChannel(channelId: chatId, isDissolved: message.chat.isDissolved))
            if message.chat.chatMode == .threadV2,
                !message.chat.isPublicV2 {
                // only not public need push PushRemoveMeForRecommendList for delete threadMessage from recommend list
                self.pushCenter?.post(PushRemoveMeForRecommendList(channelId: chatId))
            }
        case .updateChatter:
            break
        @unknown default:
            assert(false, "new value")
            break
        }
        pushCenter?.post(PushChatMemberChange(chatId: chatId))
    }
}

// 群管理员更新 push
final class ChatAdminPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushChatAdminUsers) {
        let chatId = message.chatID
        let chatters = message.adminUsers.compactMap { (id) -> Chatter? in
            if let chatter = message.entity.chatChatters[chatId]?.chatters.first(where: { $0.key == id })?.value {
                return Chatter.transform(pb: chatter)
            }
            return nil
        }
        self.pushCenter?
            .post(PushChatAdmin(chatId: chatId,
                                adminUsers: chatters,
                                id2DepartmentsDic: message.entity.departments))
    }
}

// 群管理员tag更新 push
final class ChatChatterTagPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushChatChatterTag) {
        let chatId = message.chatID
        guard let chattersMap = message.entity.chatChatters[chatId]?.chatters.mapValues({ (chatter) -> Chatter in
            Chatter.transform(pb: chatter)
        }) else { return }
        self.pushCenter?
            .post(PushChatChatterTag(chatId: chatId,
                                     chattersMap: chattersMap))
    }
}

// 群成员部门信息更新 push
final class ChatChatterListDepartmentNameHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Im_V1_PushChatChatterListDepartmentName) {
        self.pushCenter?
            .post(PushChatChatterListDepartmentName(chatId: message.chatID,
                                                    chatterIDToDepartmentName: message.chatterIDToDepartmentName))
    }
}
