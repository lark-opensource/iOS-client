//
//  SearchChatPickerItem.swift
//  LarkSearchFilter
//
//  Created by Patrick on 2021/8/4.
//

import UIKit
import Foundation
import RustPB
import LarkModel
import EENavigator

public struct SearchChatPickerItem: Equatable {

    public enum Info {
        public enum MetaInfo {
            case chat(isCrossTenant: Bool, isCrossWithKa: Bool, userCountText: String)
            case chatter(tenantID: String)
        }
        case chat(displayName: String, description: String, isCrossTenant: Bool, isCrossWithKa: Bool, userCount: Int32)
        case searchResult(meta: MetaInfo, subtitle: NSAttributedString, title: NSAttributedString, extra: NSAttributedString?)
    }

    public let id: String
    public let name: String
    public let chatID: String
    public let groupID: String? // 单聊会话 ID，如果为空表示是群聊
    public let chatterID: String
    public let avatarKey: String
    public let avatarID: String
    public let description: String
    public let descriptionFlag: Chatter.Description.TypeEnum
    public let extraInfo: Info

    public static func == (lhs: SearchChatPickerItem, rhs: SearchChatPickerItem) -> Bool {
        return lhs.id == rhs.id && lhs.chatID == rhs.chatID
    }

    public init(chat: Chat) {
        self.id = chat.id
        self.name = chat.name
        self.chatID = chat.id
        self.chatterID = chat.chatterId
        self.groupID = chat.type == .p2P ? chat.id : nil
        self.avatarID = chat.type == .p2P ? chat.chatterId : chat.id
        self.avatarKey = chat.avatarKey
        self.description = chat.description
        self.descriptionFlag = .onDefault
        self.extraInfo = .chat(displayName: chat.displayName, description: chat.description, isCrossTenant: chat.isCrossTenant, isCrossWithKa: chat.isCrossWithKa, userCount: chat.userCount)
    }

    public init(id: String,
                name: String,
                chatID: String,
                chatterID: String,
                avatarKey: String,
                avatarID: String,
                description: String,
                descriptionFlag: Chatter.Description.TypeEnum,
                extraInfo: Info,
                groupID: String? = nil) {
        self.id = id
        self.name = name
        self.chatID = chatID
        self.chatterID = chatterID
        self.avatarID = avatarID
        self.avatarKey = avatarKey
        self.description = description
        self.descriptionFlag = descriptionFlag
        self.extraInfo = extraInfo
        self.groupID = groupID
    }

}
