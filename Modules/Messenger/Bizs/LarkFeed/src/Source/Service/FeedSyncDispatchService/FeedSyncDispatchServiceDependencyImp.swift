//
//  FeedSyncDispatchServiceDependencyImp.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/8.
//

import Foundation
import LarkModel
import RxSwift
import LarkSDKInterface
import RustPB
import LarkContainer
import Swinject

final class FeedSyncDispatchServiceDependencyImp: FeedSyncDispatchServiceDependency, UserResolverWrapper {
    let userResolver: UserResolver
    let chatAPI: ChatAPI
    let messageAPI: MessageAPI

    @ScopedInjectedLazy var allFeedsViewModel: AllFeedListViewModel?
    @ScopedInjectedLazy var shortcutsVM: ShortcutsViewModel?
    // 网络状态
    let pushDynamicNetStatus: Observable<PushDynamicNetStatus>

    // Feed加载状态
    let pushLoadFeedCardsStatus: Observable<Feed_V1_PushLoadFeedCardsStatus>

    /// 获取内存中所有置顶数据
    var shortcutIds: [String] {
        return shortcutsVM?.dataSource.compactMap({ $0.id }) ?? []
    }

    var allFeedCellViewModels: [FeedCardCellViewModel] {
        return allFeedsViewModel?.currentFeedsCellVM() ?? []
    }

    init(resolver: UserResolver,
         pushDynamicNetStatus: Observable<PushDynamicNetStatus>,
         pushLoadFeedCardsStatus: Observable<Feed_V1_PushLoadFeedCardsStatus>
    ) throws {
        self.userResolver = resolver
        self.chatAPI = try resolver.resolve(assert: ChatAPI.self)
        self.messageAPI = try resolver.resolve(assert: MessageAPI.self)

        self.pushDynamicNetStatus = pushDynamicNetStatus
        self.pushLoadFeedCardsStatus = pushLoadFeedCardsStatus
    }

    // MARK: - ChatAPI
    func getLocalChats(_ ids: [String]) throws -> [String: Chat] {
        return try chatAPI.getLocalChats(ids)
    }

    func fetchLocalChats(_ ids: [String]) -> Observable<[String: Chat]> {
        return chatAPI.fetchLocalChats(ids)
    }

    func fetchChats(by ids: [String], forceRemote: Bool) -> Observable<[String: Chat]> {
        return chatAPI.fetchChats(by: ids, forceRemote: forceRemote)
    }

    // MARK: - MessageAPI
    func fetchMessagesMap(ids: [String], needTryLocal: Bool) -> Observable<[String: Message]> {
        return messageAPI.fetchMessagesMap(ids: ids, needTryLocal: needTryLocal)
    }
}
