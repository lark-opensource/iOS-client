//
//  PushLabelHandler.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/21.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel
import LarkSDKInterface

struct PushLabel: PushMessage {
    var updateLabels: [Feed_V1_FeedGroupPreview]
    let removeLabels: [Feed_V1_FeedGroup]
    let updatedFeedEntitys: [FeedPreview]
    let updatedFeedRelations: [EntityItem]
    let removedFeeds: [Feed_V1_FeedGroupItem]

    init(updateLabels: [Feed_V1_FeedGroupPreview],
         removeLabels: [Feed_V1_FeedGroup],
         updatedFeedEntitys: [FeedPreview],
         updatedFeedRelations: [EntityItem],
         removedFeeds: [Feed_V1_FeedGroupItem]) {
        self.updateLabels = updateLabels
        self.removeLabels = removeLabels
        self.updatedFeedEntitys = updatedFeedEntitys
        self.updatedFeedRelations = updatedFeedRelations
        self.removedFeeds = removedFeeds
    }

    var description: String {
        let info = "updateLabels: count: \(updateLabels.count), info: \(updateLabels.map({ $0.description })), "
            + "removeLabels: count \(removeLabels.count), \(removeLabels.map { $0.description }), "
            + "updatedFeedEntitys: count \(updatedFeedEntitys.count), \(updatedFeedEntitys.map { $0.description }), "
            + "updatedFeedRelations: count \(updatedFeedRelations.count), \(updatedFeedRelations.map { $0.description }), "
            + "removedFeeds: count \(removedFeeds.count), \(removedFeeds.map { $0.description })"
        return info
    }
}

final class PushLabelHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Feed_V1_PushFeedGroup) throws {
        guard let pushCenter = self.pushCenter else { return }
        var updatedFeedEntitys: [FeedPreview] = []
        var updatedFeedRelations: [EntityItem] = []

        for item in message.updateGroupItems {
            let feedEntity = FeedPreview.transformByEntityPreview(item.feedEntityPreview)
            updatedFeedEntitys.append(feedEntity)
            for groupItem in item.groupItems {
                updatedFeedRelations.append(EntityItem(id: Int(groupItem.feedCardID),
                                                       parentId: Int(groupItem.groupID),
                                                       position: groupItem.position,
                                                       updateTime: groupItem.updateTime))
            }
        }
        let pushLabel = PushLabel(
            updateLabels: message.updateGroups,
            removeLabels: message.removeGroups,
            updatedFeedEntitys: updatedFeedEntitys,
            updatedFeedRelations: updatedFeedRelations,
            removedFeeds: message.removeGroupItems)
        let logs = pushLabel.description.logFragment()
        for i in 0..<logs.count {
            let log = logs[i]
            FeedContext.log.info("feedlog/label/push/<\(i)>. \(log)")
        }
        pushCenter.post(pushLabel)
    }
}
