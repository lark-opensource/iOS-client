//
//  MockBaseFeedListViewModelDependency.swift
//  LarkFeed-Unit-Tests
//
//  Created by 白镜吾 on 2023/8/24.
//

import Foundation
import RxSwift
import RxRelay
import RustPB
import LarkModel
import LarkSDKInterface
import LarkOpenFeed
import LarkContainer
import LarkAvatar
@testable import LarkFeed

final class BaseFeedsViewModelService {
//    static var hideChannelSubject = PublishSubject<Void>()
//    static var clearSignleBadgeSubject = PublishSubject<Void>()
    static var updateChatForbiddenStateSubject = PublishSubject<Void>()
    static var observeSelectSubject = PublishSubject<String?>()
}

final class MockBaseFeedsViewModelDependency: BaseFeedsViewModelDependency {

    func removeFeedCard(channel: RustPB.Basic_V1_Channel, feedPreviewPBType: RustPB.Basic_V1_FeedCard.EntityType?, from vc: UIViewController?) {}

    func moveToDone(feedId: String, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void> {
        feedAPI.moveToDone(feedId: feedId, entityType: entityType)
    }

    func createShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void> {
        feedAPI.createShortcuts(shortcuts)
    }

    func deleteShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void> {
        feedAPI.deleteShortcuts(shortcuts)
    }

    func flagFeedCard(_ id: String, isFlaged: Bool, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void> {
        feedAPI.flagFeedCard(id, isFlaged: isFlaged, entityType: entityType)
    }

    func markFeedCard(_ id: String, isDelayed: Bool) -> Observable<FeedPreview> {
        feedAPI.markFeedCard(id, isDelayed: isDelayed)
    }

    func updateChatForbiddenState(chatterID: String, isForbidden: Bool) -> Observable<Void> {
        return BaseFeedsViewModelService.updateChatForbiddenStateSubject.asObserver()
    }

    /// iPad选中态监听
    func observeSelect() -> Observable<String?> {
        return BaseFeedsViewModelService.observeSelectSubject.asObserver()
    }

    func setSelected(feedId: String?) {}
    func selectedRecordID(prev: Bool) -> String? { return nil }
    func getSelected() -> String? { return nil }
    func hideChannel(channel: Basic_V1_Channel, feedType: RustPB.Basic_V1_FeedCard.EntityType?, from vc: UIViewController?) {}
    func clearSignleBadge(feedID: String, feedEntityPBType feedEntityType: Basic_V1_FeedCard.EntityType, from vc: UIViewController) {}

    let userResolver: UserResolver
    private let feedAPI: FeedAPI
//    private let feedDependency: FeedDependency
//    private let feedGuideDependency: FeedGuideDependency
//    private let feedSelection: FeedSelectionService

    let pushFeedPreview: Observable<PushFeedPreview>
    let badgeStyleObservable: Observable<Settings_V1_BadgeStyle>
    let pushThreadFeedAvatarChanges: Observable<PushThreadFeedAvatarChanges>
    let is24HourTime: BehaviorRelay<Bool>
    let feedCardModuleManager: FeedCardModuleManager
    let actionSettingStore: FeedSettingStore
    init(resolver: UserResolver) throws {
        let pushCenter = try resolver.userPushCenter
        self.userResolver = resolver
        self.feedAPI = try resolver.resolve(assert: FeedAPI.self)
//        self.feedDependency = try resolver.resolve(assert: FeedDependency.self)
//        self.feedGuideDependency = try resolver.resolve(assert: FeedGuideDependency.self)
//        self.feedSelection = try resolver.resolve(assert: FeedSelectionService.self)
        self.pushFeedPreview = pushCenter.observable(for: LarkFeed.PushFeedPreview.self)
        self.pushThreadFeedAvatarChanges = pushCenter.observable(for: PushThreadFeedAvatarChanges.self)
        self.badgeStyleObservable = .just(.strongRemind)
        self.is24HourTime = BehaviorRelay<Bool>(value: false)
        self.feedCardModuleManager = try resolver.resolve(assert: FeedCardModuleManager.self)
        self.actionSettingStore = try resolver.resolve(assert: FeedSettingStore.self)
    }
}
