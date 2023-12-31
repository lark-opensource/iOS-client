//
//  FeedTeamViewModel+Bind.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
//

import Foundation
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift
import RxRelay
import RustPB
import LarkModel
import LarkRustClient
import SwiftProtobuf
import RunloopTools

extension FeedTeamViewModel {

    func bind() {
        getTeams()

        dependency.pushItems.subscribe(onNext: { [weak self] (pushItems) in
            guard let self = self else { return }
            if pushItems.action == .update {
                var teamEntities = [Int: Basic_V1_Team]()
                for (key, value) in pushItems.teams {
                    teamEntities[Int(key)] = value
                }
                var teamItems: [Basic_V1_Item] = []
                var chatItems: [Basic_V1_Item] = []
                pushItems.items.forEach { item in
                    if item.entityType == .team {
                        teamItems.append(item)
                    }
                    if item.entityType == .chat {
                        chatItems.append(item)
                    }
                }

                if !teamItems.isEmpty {
                    self.addTask {
                        let teamItemIdsForMissedChats = teamItems.compactMap { teamItem -> Int? in
                            if let teamModel = self.dataSourceCache.getTeam(teamItem: teamItem) {
                                if teamModel.chatModels.isEmpty {
                                    return Int(teamItem.id)
                                } else {
                                    return nil
                                }
                            } else {
                                return Int(teamItem.id)
                            }
                        }
                        self.updateTeams(teamItems: teamItems,
                                         teamEntities: teamEntities,
                                         dataFrom: .pushItemsUpdateTeam)
                        // 本地没有该team或者该team下没有chat时，需要拉取该team下的chat列表
                        self.fetchMissedChats(teamItemIdsForMissedChats, dataFrom: .fetchMissedChatsForPushItem)
                    }
                }

                if !chatItems.isEmpty {
                    self.updateChatItems(chatItems,
                                         dataFrom: .pushItemsUpdateTeam)
                }
            } else if pushItems.action == .delete {
                var removeTeamItemIds = [Int]()
                var removeChatItems = [Basic_V1_Item]()
                pushItems.items.forEach { item in
                    if item.entityType == .team {
                        removeTeamItemIds.append(Int(item.id))
                    } else if item.entityType == .chat {
                        removeChatItems.append(item)
                    }
                }
                if !removeTeamItemIds.isEmpty {
                    self.removeTeams(removeTeamItemIds, dataFrom: .pushItemsRemoveTeam)
                }
                if !removeChatItems.isEmpty {
                    self.removeChats(removeChatItems)
                }
            }
        }).disposed(by: disposeBag)

        dependency.pushTeams.subscribe(onNext: { [weak self] (pushTeams) in
            guard let self = self else { return }
            var entities = [Int: Basic_V1_Team]()
            for (key, value) in pushTeams.teams {
                entities[Int(key)] = value
            }
            guard !entities.keys.isEmpty else { return }
            self.updateTeamEntities(entities)
        }).disposed(by: disposeBag)

        dependency.pushItemExpired.subscribe(onNext: { [weak self] (pushItemExpired) in
            guard let self = self else { return }
            if pushItemExpired.hasParentID {
                let parentID = Int(pushItemExpired.parentID)
                if parentID == 0 {
                    // 删除所有数据
                    self.removeAllTeams()
                } else {
                    // 删除指定的团队
                    self.removeTeams([parentID], dataFrom: .pushExpired)
                }
            }
        }).disposed(by: disposeBag)

        dependency.pushFeedPreview.subscribe(onNext: { [weak self] (feeds) in
            guard let self = self else { return }
            var updateFeeds = [FeedPreview]()
            feeds.updateFeeds.compactMap { (_: String, feedInfo: PushFeedInfo) in
                let feed = feedInfo.feedPreview
                if feedInfo.types.contains(.team) {
                    updateFeeds.append(feed)
                }
            }
            guard !updateFeeds.isEmpty else { return }
            let update = FeedTeamDataSource.transform(feeds: updateFeeds)
            let chatItems = update.chatItems
            let chatEntities = update.chatEntities
            if chatItems.keys.isEmpty || chatEntities.keys.isEmpty {
                return
            }
            self.updateChats(
                chatItems: chatItems,
                chatEntities: chatEntities,
                dataFrom: .pushInboxCard)
        }).disposed(by: disposeBag)

        dependency.pushTeamItemChats.subscribe(onNext: { [weak self] (pushTeamItemChats) in
            guard let self = self else { return }
            var updateFeeds = [FeedPreview]()
            pushTeamItemChats.teamChats.compactMap { (feed: FeedPreview) in
                updateFeeds.append(feed)
            }
            guard !updateFeeds.isEmpty else { return }
            let update = FeedTeamDataSource.transform(feeds: updateFeeds)
            let chatItems = update.chatItems
            let chatEntities = update.chatEntities
            if chatItems.keys.isEmpty || chatEntities.keys.isEmpty {
                return
            }
            self.updateChats(
                chatItems: chatItems,
                chatEntities: chatEntities,
                dataFrom: .pushTeamItemChats)
        }).disposed(by: disposeBag)

        dependency.badgeStyleObservable
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
            self?.handleBadgeStyle()
        }).disposed(by: disposeBag)

        // 断线重连需要重刷
        dependency.pushWebSocketStatus.skip(1).subscribe(onNext: { [weak self] status in
            guard let self = self else { return }
            guard status.status == .success else { return }
            FeedContext.log.info("teamlog/pushWebSocketStatus. success")
            if self.isReGetData {
                FeedContext.log.info("teamlog/pushWebSocketStatus. re getData")
                self.sendLoadingState(true)
                self.removeAllTeams()
                self.getTeams()
            }
        }).disposed(by: disposeBag)

        observeApplicationNotification()
    }

    func getTeams() {
        dependency.getTeams()
            .subscribe(onNext: { [weak self] (response: GetTeamsResult) in
                guard let self = self else { return }
                self.updateTeams(teamItems: response.teamItems,
                                 teamEntities: response.teamEntities,
                                 dataFrom: .getTeams)
                self.handleTeamLastExpandedState()
                let teamIds = response.teamItems.map({ Int($0.id) })
                teamIds.forEach { teamId in
                    self.getChats(teamIds: [teamId], dataFrom: .getChats)
                }
                self.sendLoadingState(false)
                self.isReGetData = false
            }, onError: { [weak self] _ in
                self?.sendLoadingState(false)
                self?.isReGetData = true
            }).disposed(by: disposeBag)
    }

    func sendLoadingState(_ shouldLoading: Bool) {
        loadingStateRelay.accept(shouldLoading)
    }

    func getChats(teamIds: [Int], dataFrom: DataFrom) {
        guard !teamIds.isEmpty else { return }
        dependency.getChats(teamIds: teamIds)
            .subscribe(onNext: { [weak self] (response: GetChatsResult) in
            guard let self = self else { return }
                self.updateChats(chatItems: response.chatItems,
                                 chatEntities: response.chatEntities,
                                 dataFrom: dataFrom)
        }).disposed(by: disposeBag)
    }

    // 补偿兜底逻辑：在即将展开时，再重新拉下二级列表；或者在接收到pushItem时，本地没有该team或者该team下没有chat时，需要拉取该team下的chat列表
    func fetchMissedChats(_ teamIds: [Int], dataFrom: DataFrom) {
        FeedContext.log.error("teamlog/fetchMissedChats. \(dataFrom), \(teamIds)")
        self.getChats(teamIds: teamIds, dataFrom: dataFrom)
    }

    func handleBadgeStyle() {
        updateBadgeStyle()
    }
}
