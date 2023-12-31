//
//  HiddenChatListViewModel+Bind.swift
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

extension HiddenChatListViewModel {

    func bind() {
        getChats(teamId: teamItemId)

        dependency.pushItems.subscribe(onNext: { [weak self] (pushItems) in
            guard let self = self else { return }
            if pushItems.action == .update {
                var chatItems: [Basic_V1_Item] = []
                pushItems.items.forEach { item in
                    if item.entityType == .chat {
                        if item.parentID == self.teamItemId {
                            chatItems.append(item)
                        }
                    }
                }
                if !chatItems.isEmpty {
                    self.updateChatItems(chatItems)
                }
            } else if pushItems.action == .delete {
                var removeTeamItemIds = [Int]()
                var removeChatItems = [Int]()
                pushItems.items.forEach { item in
                    if item.entityType == .team {
                        removeTeamItemIds.append(Int(item.id))
                    } else if item.entityType == .chat {
                        if item.parentID == self.teamItemId {
                            removeChatItems.append(Int(item.id))
                        }
                    }
                }
                if removeTeamItemIds.contains(self.teamItemId) {
                    self.removeAll()
                }
                self.removeChats(removeChatItems)
            }
        }).disposed(by: disposeBag)

        dependency.pushFeedPreview.subscribe(onNext: { [weak self] (feeds) in
            guard let self = self else { return }
            var updateFeeds = [FeedPreview]()
            feeds.updateFeeds.compactMap { (_: String, feedInfo: PushFeedInfo) in
                let feed = feedInfo.feedPreview
                for item in feed.preview.chatData.items {
                    let isHidden = item.isHidden
                    if feedInfo.types.contains(.team),
                       item.hasParentID,
                       isHidden,
                       item.parentID == self.teamItemId {
                        updateFeeds.append(feed)
                    }
                }
            }
            guard !updateFeeds.isEmpty else { return }
            let update = FeedTeamDataSource.transform(feeds: updateFeeds)
            let chatItems = update.chatItems
            let chatEntities = update.chatEntities
            if chatItems.keys.isEmpty || chatEntities.keys.isEmpty {
                return
            }
            guard let chatItemslist = chatItems[self.teamItemId] else { return }
            self.updateChats(
                chatItems: chatItemslist,
                chatEntities: chatEntities)
        }).disposed(by: disposeBag)

        dependency.pushTeamItemChats.subscribe(onNext: { [weak self] (pushTeamItemChats) in
            guard let self = self else { return }
            var updateFeeds = [FeedPreview]()
            pushTeamItemChats.teamChats.compactMap { (feed: FeedPreview) in
                for item in feed.preview.chatData.items {
                    let isHidden = item.isHidden
                    if item.hasParentID,
                       isHidden,
                       item.parentID == self.teamItemId {
                        updateFeeds.append(feed)
                    }
                }
            }
            guard !updateFeeds.isEmpty else { return }
            let update = FeedTeamDataSource.transform(feeds: updateFeeds)
            let chatItems = update.chatItems
            let chatEntities = update.chatEntities
            if chatItems.keys.isEmpty || chatEntities.keys.isEmpty {
                return
            }
            guard let chatItemslist = chatItems[self.teamItemId] else { return }
            self.updateChats(
                chatItems: chatItemslist,
                chatEntities: chatEntities)
        }).disposed(by: disposeBag)

        dependency.badgeStyleObservable
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] _ in
            self?.handleBadgeStyle()
        }).disposed(by: disposeBag)
    }

    func getChats(teamId: Int) {
        dependency.getChats(teamIds: [teamId])
            .subscribe(onNext: { [weak self] (response: GetChatsResult) in
            guard let self = self else { return }
            guard let chatItems = response.chatItems[teamId] else { return }
            self.updateChats(chatItems: chatItems,
                             chatEntities: response.chatEntities)
            self.sendLoadingState(false)
        }).disposed(by: disposeBag)
    }

    func handleBadgeStyle() {
        updateBadgeStyle()
    }

    func sendLoadingState(_ shouldLoading: Bool) {
        loadingStateRelay.accept(shouldLoading)
    }
}
