//
//  ChatterExtension.swift
//  LarkCore
//
//  Created by zc09v on 2018/11/11.
//

import Foundation
import LarkModel

public enum GetChatterDisplayNameScene: Int32 {
    case reaction
    case head
    case atInChatInput
    case reply
    case pin
    case atOrUrgentPick
    case urgentConfirm
    case groupMemberList
    case readStatusList
    case transformGroupOwner
    case groupOwnerRecall
    case postAnnouncement
    case detailPageTitle
    case docList
    case unReadTip
    case docPreviewPermission
    case oncall
    case urgentTip
    case fileLastEditInfo //文件消息中的文件被最后编辑的信息
}

public protocol ChatterName {
    var nickName: String? { get }
    var localizedName: String { get }
    var alias: String { get }
    var displayName: String { get }
    var chatExtraChatID: String? { get }
    var displayWithAnotherName: String { get }
    var nameWithAnotherName: String { get }
}

public func getDisplayName(
    with scene: GetChatterDisplayNameScene,
    chatId: String,
    chatType: Chat.TypeEnum?,
    chatterName: ChatterName) -> String {
    guard let chatType = chatType else {
        return chatterName.displayName
    }
    var needAnotherName: Bool = false
    switch scene {
    case .atInChatInput, .pin, .groupOwnerRecall, .postAnnouncement:
        needAnotherName = (scene == .atInChatInput || scene == .pin)
    case .reaction, .head, .reply, .readStatusList, .docList, .detailPageTitle, .docPreviewPermission, .urgentConfirm, .urgentTip:
        needAnotherName = (scene == .head || scene == .reply || scene == .reaction || scene == .readStatusList)
    case .atOrUrgentPick, .groupMemberList, .transformGroupOwner, .fileLastEditInfo:
        needAnotherName = true
    case .unReadTip, .oncall:
        break
    }
    return getDisplayName(chatId: chatId, chatterName: chatterName, needAnotherName: needAnotherName)
}

private func getDisplayName(chatId: String, chatterName: ChatterName, needAnotherName: Bool) -> String {
    var nickName: String = ""
    if let extraChatId = chatterName.chatExtraChatID, let chatterNickName = chatterName.nickName, extraChatId == chatId {
        nickName = chatterNickName
    }
    let displayName = needAnotherName ? chatterName.displayWithAnotherName : chatterName.displayName
    let alias = chatterName.alias
    if alias.isEmpty, !nickName.isEmpty {
        return nickName
    }
    return displayName
}

extension Chatter: ChatterName {
    public var nickName: String? {
        return self.chatExtra?.nickName
    }

    public var chatExtraChatID: String? {
        return self.chatExtra?.chatID
    }
}

public extension Chatter {
    func displayName(chatId: String, chatType: Chat.TypeEnum?, scene: GetChatterDisplayNameScene) -> String {
        return getDisplayName(with: scene, chatId: chatId, chatType: chatType, chatterName: self)
    }
}
