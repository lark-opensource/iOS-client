//
//  ImagePreloader+Feed.swift
//  LarkMessageCore
//
//  Created by Saafo on 2023/1/3.
//

import ByteWebImage
import Foundation
import LarkOpenFeed
import LarkModel
import LarkSDKInterface

public final class FeedImagePreloadListener: FeedListenerItem {

    public init() {}

    public var needListenFeedData: Bool { LarkImageService.shared.imagePreloadConfig.preloadEnable }

    public func feedDataChanged(feeds: [FeedPreview], context: FeedContextService?) {
        var messageAPI: MessageAPI?
        feeds
            .filter { feed in
                feed.isRemind && feed.type == .chat && feed.chatType == .p2P && !feed.isCrypto &&
                [.image, .media].contains(feed.lastMessageType)
            }
            .map { feed in
                if messageAPI == nil {
                    // 避免本次循环内，messageAPI反复从容器中取
                    messageAPI = try? context?.userResolver.resolve(assert: MessageAPI.self)
                }
                ImagePreloader.shared.preload(scene: .feed, sceneID: feed.id, messageID: feed.lastVisibleMessageID, messageAPI: messageAPI)
            }
    }
}
