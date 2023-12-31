//
//  FlagAPI.swift
//  LarkSDKInterface
//
//  Created by phoenix on 2022/5/9.
//

import Foundation
import RxSwift
import LarkModel
import RustPB
import ServerPB

public struct GetFlagsResult {
    // 标记的单位实体
    public let flags: [RustPB.Feed_V1_FlagItem]
    // 标记的feed用到数据
    public let flagFeeds: RustPB.Feed_V1_FeedFlags
    // 标记的消息用到的数据
    public let flagMessages: RustPB.Feed_V1_MessageFlags
    // 分页游标
    public let nextCursor: RustPB.Feed_V1_FeedCursor

    public init(flags: [RustPB.Feed_V1_FlagItem],
                flagFeeds: RustPB.Feed_V1_FeedFlags,
                flagMessages: RustPB.Feed_V1_MessageFlags,
                nextCursor: RustPB.Feed_V1_FeedCursor) {
        self.flags = flags
        self.flagFeeds = flagFeeds
        self.flagMessages = flagMessages
        self.nextCursor = nextCursor
    }
}

public protocol FlagAPI: AnyObject {

    func updateChat(isFlaged: Bool, chatId: String) -> Observable<Void>

    func updateMessage(isFlaged: Bool, messageId: String) -> Observable<Void>

    func updateFeed(isFlaged: Bool, feedId: String, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void>

    func getFlags(cursor: Feed_V1_FeedCursor?, count: Int, sortingRule: Feed_V1_FlagSortingRule) -> Observable<GetFlagsResult>
}

public typealias FlagAPIAPIProvider = () -> FlagAPI
