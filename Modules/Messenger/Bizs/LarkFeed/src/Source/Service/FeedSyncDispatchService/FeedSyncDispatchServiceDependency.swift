//
//  FeedSyncDispatchServiceDependency.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/6/8.
//

import Foundation
import LarkModel
import RxSwift
import LarkSDKInterface
import RustPB

// 后续外部自己调Rust接口，不从Feed取，可移除
protocol FeedSyncDispatchServiceDependency {

    // 网络状态
    var pushDynamicNetStatus: Observable<PushDynamicNetStatus> { get }

    // Feed加载状态
    var pushLoadFeedCardsStatus: Observable<Feed_V1_PushLoadFeedCardsStatus> { get }

    /// 当前置顶Id
    var shortcutIds: [String] { get }

    /// 当前Feed Cell VM
    var allFeedCellViewModels: [FeedCardCellViewModel] { get }

    // MARK: - ChatAPI
    func getLocalChats(_ ids: [String]) throws -> [String: Chat]

    func fetchLocalChats(_ ids: [String]) -> Observable<[String: Chat]>

    func fetchChats(by ids: [String], forceRemote: Bool) -> Observable<[String: Chat]>

    // MARK: - MessageAPI
    func fetchMessagesMap(ids: [String], needTryLocal: Bool) -> Observable<[String: Message]>
}
