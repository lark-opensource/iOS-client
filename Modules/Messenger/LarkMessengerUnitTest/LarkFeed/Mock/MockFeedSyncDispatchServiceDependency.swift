//
//  MockFeedSyncDispatchServiceDependency.swift
//  LarkMessengerUnitTest
//
//  Created by 袁平 on 2020/9/11.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RustPB
import LarkModel
import LarkSDKInterface
@testable import LarkFeed

class MockFeedSyncDispatchServiceDependency: FeedSyncDispatchServiceDependency {
    var getLocalChatsBuilder: ((_ ids: [String]) -> [String: Chat])?
    var feedCellViewModelsBuilder: (() -> [BaseFeedTableCellViewModel])?
    var fetchMessagesMapBuilder: ((_ ids: [String], _ needTryLocal: Bool) -> Observable<[String: Message]>)?
    var fetchChatsBuilder: ((_ ids: [String], _ forceRemote: Bool) -> Observable<[String: Chat]>)?

    var netStatusPush: Observable<PushDynamicNetStatus> {
        let push = PushDynamicNetStatus(dynamicNetStatus: .excellent)
        return .just(push)
    }

    var feedLoadStatusPush: Observable<Feed_V1_PushLoadFeedCardsStatus> {
        return .just(Feed_V1_PushLoadFeedCardsStatus())
    }

    var shortcutIds: [String] {
        ["1", "2", "3"]
    }

    var feedCellViewModels: [BaseFeedTableCellViewModel] {
        feedCellViewModelsBuilder!()
    }

    func getLocalChats(_ ids: [String]) throws -> [String: Chat] {
        return getLocalChatsBuilder!(ids)
    }

    func fetchChats(by ids: [String], forceRemote: Bool) -> Observable<[String: Chat]> {
        return fetchChatsBuilder!(ids, forceRemote)
    }

    func fetchMessagesMap(ids: [String], needTryLocal: Bool) -> Observable<[String: Message]> {
        return fetchMessagesMapBuilder!(ids, needTryLocal)
    }
}
