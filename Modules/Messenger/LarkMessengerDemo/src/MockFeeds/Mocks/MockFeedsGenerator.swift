//
// Created by bytedance on 2020/5/18.
// Copyright (c) 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import LarkModel

class MockFeedsGenerator {

    static func getRandomPairWithType(_ type: Basic_V1_FeedCard.EntityType) -> CardPair {
        var pair = CardPair()
        pair.id = getRandomID()
        pair.type = type
        return pair
    }

    static func getRandomPair() -> CardPair {
        getRandomPairWithType(Basic_V1_FeedCard.EntityType.allCases.randomElement()!)
    }

    static func getRandomID(_ length: Int = 19) -> String {
        let letters = "1234567890"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    ///
    /// 根据index生成随机内容的FeedCardPreview，按照index的升序生成rankTime，即index越小，rankTime越靠近当下
    /// 不保证一定能显示，可能会触发一些判断而导致FeedCell不显示
    ///
    static func getRandomFeed(_ feedType: FeedCard.FeedType, _ index: Int) -> FeedCardPreview {
        var feed = FeedCardPreview()
        feed.avatarKey = "834e000a1c1e7e1d71df"  // 暂时复用固定的avatarKey
        feed.name = "Feed cell name #\(index)"
        feed.displayTime = Int64(NSDate().timeIntervalSince1970) - Int64(index * 60 * 60 * 24)  // 每个feed都递减1天的时间，来保持同一批次获得Feeds之间的排序
        feed.rankTime = feed.displayTime
        feed.updateTime = feed.displayTime

        // 下面是完全随机的
        feed.avatarPath = ""
        feed.chatDescription = getRandomLocalizedMessage(20)
        feed.chatMode = Basic_V1_Chat.ChatMode.allCases.randomElement()!
        feed.chatMuteable = Bool.random()
        feed.chatRole = Basic_V1_Chat.Role.allCases.randomElement()!
        feed.chatterID = getRandomID()
        feed.chatterType = Basic_V1_Chatter.TypeEnum.allCases.randomElement()!
        feed.chatType = Basic_V1_Chat.TypeEnum.allCases.randomElement()!
        feed.crossTenant = Bool.random()
        feed.doNotDisturbEndTime = Int64(NSDate().timeIntervalSince1970) + Int64.random(in: 0...60)
        feed.entityStatus = Feed_V1_FeedCardPreview.EntityStatus.allCases.randomElement()!
        feed.feedType = feedType
        feed.isCrypto = Bool.random()
        feed.isDelayed = Bool.random()
        feed.isDepartment = Bool.random()
        feed.isMeeting = Bool.random()
        feed.isMember = Bool.random()
        feed.isNewBox = Bool.random()
        feed.isPublicV2 = Bool.random()
        feed.isRemind = Bool.random()
        feed.isShortcut = Bool.random()
        feed.isSupportView = Bool.random()
        feed.lastMessagePosition = Int32.random(in: 0...100)  // value >= 0 则 CellViewModel.isShow == true
        feed.lastMessageType = Basic_V1_Message.TypeEnum.allCases.randomElement()!
        feed.lastVisibleMessageID = getRandomID()
        feed.localizedDigestMessage = getRandomLocalizedMessage(200)
        feed.miniAvatarKey = "834e000a1c1e7e1d71df"
        feed.parentCardID = getRandomID()
        feed.tags = getRandomTags(3)
        feed.tenantChat = Bool.random()
        feed.unreadCount = Bool.random() ? 0 : Int32.random(in: 1...1000)  // 这里调整下，有无未读是一个大分类，然后才是具体的count
        feed.updateTime = Int64(NSDate().timeIntervalSince1970)
        feed.withBotTag = Bool.random() ? getRandomLocalizedMessage(5) : ""  // 50%的几率没有 bottag
        return feed
    }

    static func getRandomTags(_ count: Int = 1) -> [Basic_V1_Tag] {
        var tags = [Basic_V1_Tag]()

        for _ in 0..<count {
            let tag = Basic_V1_Tag.allCases.filter { tag in tag != .unknownTag }.randomElement()!
            tags.append(tag)
        }

        return tags
    }

    static func getRandomCursorPair() -> Cursor {
        var cursor = Cursor()
        cursor.maxCursor = Int64.random(in: 10_000...Int64.max)
        cursor.minCursor = Int64.random(in: 0..<cursor.maxCursor)
        return cursor
    }

    // 至少返回1个字符
    static func getRandomLocalizedMessage(_ maxLength: Int = 100) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let messageLength = Int.random(in: 1...maxLength)
        return String((0..<messageLength).map { _ in letters.randomElement()! })
    }

    ///
    /// 符合Feeds服务端的生成逻辑，即maxCursor来自feeds中rankTime最大值，minCursor来自最小值
    /// https://bytedance.feishu.cn/docs/doccnlkrW6XSbsRwpkBSqpwF6Kr
    ///
    static func getCursorPairForFeeds(_ feeds: [FeedCardPreview]) -> Cursor {
        // 如果传入的feeds array为空，返回随机的CursorPair
        if feeds.isEmpty {
            return getRandomCursorPair()
        }

        var cursor = Cursor()
        let rankTimeArray = feeds.map { $0.rankTime }
        cursor.maxCursor = rankTimeArray.max()!
        cursor.minCursor = rankTimeArray.min()!
        return cursor
    }
}
