//
//  FeedTeamItemViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/19.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import UniverseDesignToast
import ThreadSafeDataStructure
import RunloopTools
import LKCommonsLogging
import LarkPerf
import LarkModel
import LarkBizAvatar
import LarkBadge
import LarkFeedBase

struct FeedTeamItemViewModel {
    var teamItem: Basic_V1_Item
    var teamEntity: Basic_V1_Team
    var chatModels = [FeedTeamChatItemViewModel]()
    var chatIndexMap = [Int: Int]()
    var isExpanded = false
    var hidenCount = 0
    var badgeInfo: (type: BadgeType, style: LarkBadge.BadgeStyle)?
    var remindUnreadCount: Int?
    var muteUnreadCount: Int?
    var unreadCount: Int?

    init(item: Basic_V1_Item,
        teamEntity: Basic_V1_Team) {
        self.teamItem = item
        self.teamEntity = teamEntity
    }

    private mutating func update() {
        badgeInfo = getBadgeInfo()
        sort()
    }
}

extension FeedTeamItemViewModel {
    mutating
    func updateChats(chatItems: [Basic_V1_Item],
                     chatEntities: [Int: FeedPreview]) {
        var errorIds = [Int]()
        chatItems.forEach { chatItem in

            guard let chatEntityId = Int(chatItem.entityID) else {
                return
            }
            guard let chatEntity = chatEntities[chatEntityId] else {
                errorIds.append(chatEntityId)
                return
            }
            if let index = self.chatIndexMap[Int(chatItem.id)], index < self.chatModels.count {
                var oldChatModel = self.chatModels[index]
                oldChatModel.updateChatItem(item: chatItem)
                oldChatModel.updateChatEntity(chatEntity: chatEntity)
                self.chatModels[index] = oldChatModel
            } else {
                let newChatModel = FeedTeamChatItemViewModel(item: chatItem, chatEntity: chatEntity)
                self.chatModels.append(newChatModel)
            }
        }
        if !errorIds.isEmpty {
            FeedContext.log.error("teamlog/updateChats. chatItems and chatEntities don't match, could not find a chatEntity to add/update: \(errorIds)")
        }
        update()
    }

    mutating
    func updateChatItems(_ chatItems: [Basic_V1_Item]) {
        var errorIds = [Int]()
        chatItems.forEach { chatItem in
            let chatItemId = Int(chatItem.id)
            if let index = self.chatIndexMap[chatItemId], index < chatModels.count {
                var oldChatModel = self.chatModels[index]
                oldChatModel.updateChatItem(item: chatItem)
                self.chatModels[index] = oldChatModel
            } else {
                errorIds.append(chatItemId)
            }
        }
        if !errorIds.isEmpty {
            FeedContext.log.error("teamlog/updateChatItems. chat could not be found locally, errorIds: \(errorIds)")
        }
        update()
    }

    mutating func removeChat(_ chatItemId: Int) {
        guard let chatIndex = self.chatIndexMap[chatItemId],
              chatIndex < chatModels.count else { return }
        self.chatModels.remove(at: chatIndex)
        update()
    }

    mutating func removeChats(_ chatItemIds: [Int]) {
        chatItemIds.forEach { chatItemId in
            removeChat(chatItemId)
        }
    }

    mutating func removeAllChats() {
        self.chatModels.removeAll()
        update()
    }
}

extension FeedTeamItemViewModel {
    mutating func updateTeamItem(item: Basic_V1_Item) {
        if isUpdateTeamItem(newTeamItem: item, oldTeamItem: self.teamItem) {
            self.teamItem = item
            sort()
        }
    }

    func isUpdateTeamItem(newTeamItem: Basic_V1_Item, oldTeamItem: Basic_V1_Item) -> Bool {
        if newTeamItem.version > oldTeamItem.version {
            return true
        }
        return false
    }

    mutating func updateTeamEntity(teamEntity: Basic_V1_Team) {
        if isUpdateTeamEntity(newTeamEntity: teamEntity, oldTeamEntity: self.teamEntity) {
            self.teamEntity = teamEntity
        }
    }

    func isUpdateTeamEntity(newTeamEntity: Basic_V1_Team, oldTeamEntity: Basic_V1_Team) -> Bool {
//        if newTeamEntity.version > oldTeamEntity.version || newTeamEntity.userEntity.version > oldTeamEntity.userEntity.version {
//          return true
//        }
        if newTeamEntity.version >= oldTeamEntity.version {
            return true
        }
        return false
    }
}

extension FeedTeamItemViewModel {
    mutating func updateTeamExpanded(_ isExpanded: Bool) {
        self.isExpanded = isExpanded
    }

    mutating func updateChatSelected(_ chatEntityId: String?) {
        for i in 0..<chatModels.count {
            var chat = chatModels[i]
            chat.updateChatSelected(chatEntityId)
            chatModels[i] = chat
        }
    }

    mutating func updateBadgeStyle() {
        for j in 0..<chatModels.count {
            var chat = chatModels[j]
            chat.updateBadgeStyle()
            chatModels[j] = chat
        }
    }
}

extension FeedTeamItemViewModel {
    private mutating func sort() {
        self.chatModels.sort(by: ranking)
        updateIndexTable()
    }

    private mutating func updateIndexTable() {
        self.chatIndexMap.removeAll()
        for i in 0..<self.chatModels.count {
            let chat = self.chatModels[i]
            let id = Int(chat.chatItem.id)
            self.chatIndexMap[id] = i
        }
    }

    private func ranking(_ lhs: FeedTeamChatItemViewModel, _ rhs: FeedTeamChatItemViewModel) -> Bool {
        return lhs.chatItem.nameWeight != rhs.chatItem.nameWeight ?
            lhs.chatItem.nameWeight < rhs.chatItem.nameWeight :
            lhs.chatItem.id < rhs.chatItem.id
    }
}

extension FeedTeamItemViewModel {
    var description: String {
        return "teamItem: \(teamItem.description), "
            + "teamEntity: \(teamEntity.description), "
            + "isExpanded: \(isExpanded), "
            + "badgeInfo: \(badgeInfo?.type), \(badgeInfo?.style), "
            + "hidenCount: \(hidenCount), "
            + "chatsCount: \(chatModels.count), "
            + "perChatDesc: \(chatModels.map({ $0.description }))"
    }
}

// 显示隐藏需求：应该将业务逻辑拆出去
extension FeedTeamItemViewModel {

    mutating func removeHidenChats() {
        let hidenChatIds = self.chatModels.compactMap { chat -> Int? in
            guard let feedId = Int64(chat.chatEntity.id) else { return nil }
            if chat.chatItem.isHidden && !chat.chatEntity.uiMeta.mention.hasAtInfo && feedId != teamEntity.defaultChatID {
                return Int(chat.chatItem.id)
            }
            return nil
        }
        self.hidenCount = hidenChatIds.count
        removeChats(hidenChatIds)
    }

    mutating func removeShownChats() {
        let shownChatIds = self.chatModels.compactMap { chat -> Int? in
            guard let feedId = Int64(chat.chatEntity.id) else { return nil }
            if !chat.chatItem.isHidden || chat.chatEntity.uiMeta.mention.hasAtInfo || feedId == teamEntity.defaultChatID {
                return Int(chat.chatItem.id)
            }
            return nil
        }
        removeChats(shownChatIds)
    }

    private mutating func getBadgeInfo() -> (type: BadgeType, style: LarkBadge.BadgeStyle)? {
        var remindUnreadCount = 0
        var muteUnreadCount = 0
        chatModels.forEach { chat in
            let entity = chat.chatEntity
            if entity.basicMeta.feedCardBaseCategory != .done {
                if entity.basicMeta.isRemind {
                    remindUnreadCount += entity.basicMeta.unreadCount
                } else {
                    muteUnreadCount += entity.basicMeta.unreadCount
                }
            }
        }
        self.remindUnreadCount = remindUnreadCount
        self.muteUnreadCount = muteUnreadCount
        self.unreadCount = muteUnreadCount + remindUnreadCount

        if remindUnreadCount <= 0 && muteUnreadCount <= 0 {
            return nil
        }

        if remindUnreadCount > 0 {
            return (.label(.number(remindUnreadCount)), .strong)
        }

        switch FeedBadgeBaseConfig.badgeStyle {
        case .weakRemind: return (.label(.number(muteUnreadCount)), .weak)
        @unknown default: return (.dot(.lark), .strong)
        }
    }
}
