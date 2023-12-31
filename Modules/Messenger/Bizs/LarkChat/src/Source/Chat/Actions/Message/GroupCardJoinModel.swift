//
//  ShareGroupChatMessageActions.swift
//  Lark
//
//  Created by liuwanlin on 2018/4/11.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkUIKit
import RxSwift
import LarkCore
import LarkModel
import LarkContainer
import LarkFoundation
import EENavigator
import LarkSDKInterface

protocol ShareGroupChatContentMetaProtocol {
    var chat: LarkModel.Chat? { get }
}

final class ShareGroupChatContentMeta: ShareGroupChatContentMetaProtocol {
    var chat: LarkModel.Chat?
    init(chat: Chat) {
        self.chat = chat
    }
}

extension ShareGroupChatContent: ShareGroupChatContentMetaProtocol {}

final class GroupCardJoinModel: GroupShareContent {

    private let chatAPI: ChatAPI

    var content: ShareGroupChatContentMetaProtocol

    private var shareGroupChatContent: ShareGroupChatContent? {
        content as? ShareGroupChatContent
    }

    var avatarKey: String {
        return content.chat?.avatarKey ?? ""
    }

    var title: String {
        return content.chat?.name ?? ""
    }

    var description: String {
        return content.chat?.description ?? ""
    }

    var expiredTime: TimeInterval {
        guard let content = content as? ShareGroupChatContent else { return 0 }
        return content.expireTime
    }

    var ownerId: String {
        return content.chat?.ownerId ?? ""
    }

    var userCount: Int32? {
        guard let chat = content.chat else {
            return 0
        }
        return chat.isUserCountVisible ? chat.userCount : nil
    }

    var joined: Bool {
        guard let shareContent = content as? ShareGroupChatContent else {
            return false
        }
        if let chat = chatAPI.getLocalChat(by: shareContent.shareChatID),
            chat.role == .member {
            return true
        } else {
            return false
        }
    }

    var expired: Bool? {
        get {
            guard !isFromSearch, let content = content as? ShareGroupChatContent else { return nil }
            return Date().timeIntervalSince1970 > content.expireTime || content.joinToken.isEmpty
        }
        set {
            if newValue == true, var shareContent = content as? ShareGroupChatContent {
                shareContent.joinToken = ""
            }
        }
    }

    var token: String? {
        if isFromSearch { return nil }
        return (content as? ShareGroupChatContent)?.joinToken ?? ""
    }

    var chatId: String {
        return content.chat?.id ?? ""
    }

    var isTopicGroup: Bool {
        if let chat = self.content.chat {
            return chat.chatMode == .threadV2
        }
        return false
    }

    var messageId: String?
    var isFromSearch: Bool

    init(content: ShareGroupChatContentMetaProtocol,
         messageId: String? = nil,
         isFromSearch: Bool = false,
         chatAPI: ChatAPI) {
        self.content = content
        self.messageId = messageId
        self.isFromSearch = isFromSearch
        self.chatAPI = chatAPI
    }
}
