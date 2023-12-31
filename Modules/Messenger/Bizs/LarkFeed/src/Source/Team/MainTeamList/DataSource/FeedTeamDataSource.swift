//
//  FeedTeamDataSource.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
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

struct FeedTeamDataSource: FeedTeamDataSourceInterface {
    private var teamIndexMap = [Int: Int]()
    var teamModels = [FeedTeamItemViewModel]()
    var dataFrom: DataFrom = .unknown
    var renderType: RenderType = .fullReload
    var dataState: DataState = .idle
}

// MARK: 一级列表的数据read处理
extension FeedTeamDataSource {
    func getTeam(teamItem: Basic_V1_Item) -> FeedTeamItemViewModel? {
        guard let teamIndex = teamIndexMap[Int(teamItem.id)] else { return nil }
        return teamModels[teamIndex]
    }

    func getChat(chatItem: Basic_V1_Item) -> FeedTeamChatItemViewModel? {
        guard let teamIndex = teamIndexMap[Int(chatItem.parentID)] else { return nil }
        let team = teamModels[teamIndex]
        guard let chatIndex = team.chatIndexMap[Int(chatItem.id)] else { return nil }
        let chat = team.chatModels[chatIndex]
        return chat
    }

    func getTeamIndex(teamItem: Basic_V1_Item) -> Int? {
        let index = teamIndexMap[Int(teamItem.id)]
        return index
    }

    func getChatIndexPath(chatItem: Basic_V1_Item) -> IndexPath? {
        guard let teamIndex = teamIndexMap[Int(chatItem.parentID)] else { return nil }
        let team = teamModels[teamIndex]
        guard let chatIndex = team.chatIndexMap[Int(chatItem.id)] else { return nil }
        return IndexPath(item: chatIndex, section: teamIndex)
    }

    // 为了避免直接从array里取数据（某些极端case可能会出现越界），定了下面两个方法，来避免越界
    func getTeam(section: Int) -> FeedTeamItemViewModel? {
        guard section < teamModels.count else { return nil }
        let team = teamModels[section]
        return team
    }

    func getChat(indexPath: IndexPath) -> FeedTeamChatItemViewModel? {
        guard let team = getTeam(section: indexPath.section) else { return nil }
        let chatModels = team.chatModels
        guard indexPath.row < chatModels.count else { return nil }
        let chat = chatModels[indexPath.row]
        return chat
    }
}

// MARK: 一级列表的数据write处理
extension FeedTeamDataSource {
    // getTeams + pushItems(add/update)
    mutating
    func updateTeams(teamItems: [Basic_V1_Item],
                     teamEntities: [Int: Basic_V1_Team]) {
        var errorIds = [Int]()
        teamItems.forEach { teamItem in
            guard let teamEntityId = Int(teamItem.entityID) else { return }
            if let index = self.teamIndexMap[Int(teamItem.id)], index < self.teamModels.count {
                var oldTeamModel = self.teamModels[index]
                oldTeamModel.updateTeamItem(item: teamItem)
                if let teamEntity = teamEntities[teamEntityId] {
                    oldTeamModel.updateTeamEntity(teamEntity: teamEntity)
                }
                self.teamModels[index] = oldTeamModel
            } else {
                guard let teamEntity = teamEntities[teamEntityId], teamEntity.status == .active else {
                    errorIds.append(teamEntityId)
                    return
                }
                let newTeamModel = FeedTeamItemViewModel(item: teamItem, teamEntity: teamEntity)
                self.teamModels.append(newTeamModel)
            }
        }
        if !errorIds.isEmpty {
            FeedContext.log.error("teamlog/updateTeams. teamitem and teamEntity don't match, could not find a teamEntity to add/update: \(errorIds)")
        }
        sort()
    }

    // pushItems(delete) + pushExpired
    mutating func removeTeams(_ teamItemIds: [Int]) {
        teamItemIds.forEach { teamItemId in
            if let index = teamModels.firstIndex(where: { $0.teamItem.id == teamItemId }), index < teamModels.count {
                self.teamModels.remove(at: index)
            }
        }
        sort()
    }

    mutating func removeAllTeams() {
        self.teamModels.removeAll()
        self.teamIndexMap.removeAll()
    }

    mutating func updateTeamEntities(_ teamEntities: [Int: Basic_V1_Team]) {
        teamEntities.forEach { (teamEntityId: Int, teamEntity: Basic_V1_Team) in
            for i in 0..<self.teamModels.count {
                var oldTeamModel = self.teamModels[i]
                guard teamEntityId == Int(oldTeamModel.teamEntity.id) else {
                    continue
                }
                if oldTeamModel.isUpdateTeamEntity(newTeamEntity: teamEntity, oldTeamEntity: oldTeamModel.teamEntity) {
                    oldTeamModel.updateTeamEntity(teamEntity: teamEntity)
                    self.teamModels[i] = oldTeamModel
                }
            }
        }
    }
}

// MARK: 二级列表的数据处理
extension FeedTeamDataSource {
    mutating
    func updateChats(chatItems: [Int: [RustPB.Basic_V1_Item]],
                     chatEntities: [Int: FeedPreview]) {
        var errorIds = [Int]()
        chatItems.forEach { (teamItemId: Int, chatItems: [Basic_V1_Item]) in
            guard let teamIndex = self.teamIndexMap[teamItemId] else {
                errorIds.append(teamItemId)
                return
            }
            var team = self.teamModels[teamIndex]
            team.updateChats(chatItems: chatItems,
                             chatEntities: chatEntities)
            self.teamModels[teamIndex] = team
        }
        if !errorIds.isEmpty {
            FeedContext.log.error("teamlog/updateChats. team could not be found locally, teamItemIds: \(errorIds)")
        }
    }

    mutating
    func updateChatItems(_ chatItems: [RustPB.Basic_V1_Item]) {
        var errorIds = [Int]()
        chatItems.forEach { chatItem in
            let teamItemId = Int(chatItem.parentID)
            guard let teamIndex = self.teamIndexMap[teamItemId] else {
                errorIds.append(teamItemId)
                return
            }
            var team = self.teamModels[teamIndex]
            team.updateChatItems(chatItems)
            self.teamModels[teamIndex] = team
        }
        if !errorIds.isEmpty {
            FeedContext.log.error("teamlog/updateChats. team could not be found locally, teamItemIds: \(errorIds)")
        }
    }

    mutating func removeChats(_ chatItems: [Basic_V1_Item]) {
        chatItems.forEach { chatItem in
            guard let teamIndex = self.teamIndexMap[Int(chatItem.parentID)],
                  teamIndex < self.teamModels.count else { return }
            var teamModel = self.teamModels[teamIndex]
            let chatItemId = Int(chatItem.id)
            guard teamModel.chatIndexMap[chatItemId] != nil else { return }
            teamModel.removeChats([chatItemId])
            self.teamModels[teamIndex] = teamModel
        }
    }
}

// MARK: UI 交互
extension FeedTeamDataSource {
    mutating func updateTeamExpanded(_ teamItemId: Int, isExpanded: Bool) {
        guard let index = self.teamIndexMap[teamItemId] else { return }
        var teamModel = self.teamModels[index]
        teamModel.updateTeamExpanded(isExpanded)
        self.teamModels[index] = teamModel
    }

    mutating func updateChatSelected(_ chatEntityId: String?) {
        for i in 0..<teamModels.count {
            var team = teamModels[i]
            team.updateChatSelected(chatEntityId)
            teamModels[i] = team
        }
    }

    mutating func updateBadgeStyle() {
        for i in 0..<self.teamModels.count {
            var team = self.teamModels[i]
            team.updateBadgeStyle()
            self.teamModels[i] = team
        }
    }
}

extension FeedTeamDataSource {
    static func transform(feeds: [FeedPreview]) -> (chatItems: [Int: [Basic_V1_Item]], chatEntities: [Int: FeedPreview]) {
        var chatItems = [Int: [RustPB.Basic_V1_Item]]()
        var chatEntities = [Int: FeedPreview]()
        for feed in feeds {
            guard let chatEntityId = Int(feed.preview.chatData.items.first?.entityID ?? "") else {
                FeedContext.log.error("teamlog/transformFeeds. error: \(feed.preview.chatData.items.first?.entityID)")
                continue
            }
            chatEntities[chatEntityId] = feed
            for item in feed.preview.chatData.items {
                let teamItemId = Int(item.parentID)
                if var items = chatItems[teamItemId] {
                    items.append(item)
                    chatItems[teamItemId] = items
                } else {
                    chatItems[teamItemId] = [item]
                }
            }
        }
        return (chatItems, chatEntities)
    }
}

extension FeedTeamDataSource {
    private mutating func sort() {
        self.teamModels.sort(by: ranking)
        updateIndexTable()
    }

    private mutating func updateIndexTable() {
        self.teamIndexMap.removeAll()
        for i in 0..<self.teamModels.count {
            let id = Int(self.teamModels[i].teamItem.id)
            self.teamIndexMap[id] = i
        }
    }

    private func ranking(_ lhs: FeedTeamItemViewModel, _ rhs: FeedTeamItemViewModel) -> Bool {
        return lhs.teamItem.orderWeight != rhs.teamItem.orderWeight ?
            lhs.teamItem.orderWeight < rhs.teamItem.orderWeight :
            lhs.teamItem.id < rhs.teamItem.id
    }
}

extension FeedTeamDataSource {
    var uiDescription: String {
        return "teamsCount: \(teamModels.count), "
            + "dataFrom: \(dataFrom), "
            + "renderType: \(renderType), "
            + "dataState: \(dataState)"
    }

    var description: String {
        return "teamsCount: \(teamModels.count), "
            + "dataFrom: \(dataFrom), "
            + "renderType: \(renderType), "
            + "dataState: \(dataState), "
            + "detail: \(teamModels.map({ $0.description }))"
    }
}

// 显示隐藏需求：应该将业务逻辑拆出去
extension FeedTeamDataSource {
    mutating func removeHidenChats() {
        for i in 0..<self.teamModels.count {
            var team = self.teamModels[i]
            team.removeHidenChats()
            self.teamModels[i] = team
        }
    }

    mutating func removeShownChats() {
        for i in 0..<self.teamModels.count {
            var team = self.teamModels[i]
            team.removeShownChats()
            self.teamModels[i] = team
        }
    }
}
