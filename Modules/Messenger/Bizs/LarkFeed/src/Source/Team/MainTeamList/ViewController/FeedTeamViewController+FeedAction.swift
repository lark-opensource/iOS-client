//
//  FeedTeamViewController+FeedAction.swift
//  LarkFeed
//
//  Created by liuxianyu on 2023/7/27.
//

import LarkOpenFeed

// MARK: - FeedActionService
extension FeedTeamViewController {
    func getActionItems(team: FeedTeamItemViewModel, feed: FeedTeamChatItemViewModel, event: FeedActionEvent) -> [FeedActionBaseItem] {
        guard let feedAction = feedActionService else { return [] }
        let model = FeedActionModel(feedPreview: feed.chatEntity,
                                    channel: feed.channel,
                                    event: event,
                                    groupType: .team,
                                    bizType: .inbox,
                                    chatItem: feed.chatItem,
                                    fromVC: self)
        let types = feedAction.getSupplementTypes(model: model, event: event)
        let actionItems = feedAction.transformToActionItems(model: model, types: types, event: event)
        subscribeActionStatus(actionItems: actionItems, team: team, feed: feed, event: event)
        return actionItems
    }

    private func subscribeActionStatus(actionItems: [FeedActionBaseItem],
                                       team: FeedTeamItemViewModel,
                                       feed: FeedTeamChatItemViewModel,
                                       event: FeedActionEvent) {
        let needSubscribeItems = actionItems.filter({ [.debug].contains($0.type) })
        needSubscribeItems.forEach { item in
            item.handler.actionStatus.subscribe(onNext: { status in
                switch item.type {
                case .debug:
                    if case .didHandle(_) = status {
                        let info = "TeamLog/debug/feed: \(team.description), "
                                 + "feed: \(feed.chatEntity.description), "
                                 + "feedItem: \(feed.chatItem.description)"
                        FeedContext.log.info(info)
                    }
                default:
                    break
                }
            }).disposed(by: self.disposeBag)
        }
    }
}
