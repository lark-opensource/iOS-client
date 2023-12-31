//
//  BaseFeedsViewModelDependencyImp.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/7/14.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkMessengerInterface
import RustPB
import RxSwift
import LarkModel
import RxCocoa
import RxDataSources
import UniverseDesignToast
import UniverseDesignDialog
import ThreadSafeDataStructure
import RunloopTools
import LKCommonsLogging
import LarkPerf
import AppReciableSDK
import LarkContainer
import Swinject
import LarkOpenFeed

typealias FeedAPIProvider = () -> FeedAPI

final class BaseFeedsViewModelDependencyImp: BaseFeedsViewModelDependency {
    let userResolver: UserResolver

    private let disposeBag = DisposeBag()
    private let feedAPI: FeedAPI
    private let feedDependency: FeedDependency
    private let feedGuideDependency: FeedGuideDependency
    private let feedSelection: FeedSelectionService
    private let chatterAPI: ChatterAPI

    // Push: PushInboxCardsHandler
    let pushFeedPreview: Observable<PushFeedPreview>
    // Push: BadgeStyle
    let badgeStyleObservable: Observable<Settings_V1_BadgeStyle>
    // Push: PushThreadFeedAvatarChangesHandler
    let pushThreadFeedAvatarChanges: Observable<PushThreadFeedAvatarChanges>
    let is24HourTime: BehaviorRelay<Bool>
    let feedCardModuleManager: FeedCardModuleManager
    let actionSettingStore: FeedSettingStore
    init(resolver: UserResolver,
         badgeStyleObservable: Observable<Settings_V1_BadgeStyle>,
         is24HourTime: BehaviorRelay<Bool>) throws {
        let pushCenter = try resolver.userPushCenter
        self.userResolver = resolver
        self.feedAPI = try resolver.resolve(assert: FeedAPI.self)
        self.feedDependency = try resolver.resolve(assert: FeedDependency.self)
        self.feedGuideDependency = try resolver.resolve(assert: FeedGuideDependency.self)
        self.feedSelection = try resolver.resolve(assert: FeedSelectionService.self)
        self.chatterAPI = try resolver.resolve(assert: ChatterAPI.self)
        self.pushFeedPreview = pushCenter.observable(for: LarkFeed.PushFeedPreview.self)
        self.pushThreadFeedAvatarChanges = pushCenter.observable(for: PushThreadFeedAvatarChanges.self)
        self.badgeStyleObservable = badgeStyleObservable
        self.is24HourTime = is24HourTime
        self.feedCardModuleManager = try resolver.resolve(assert: FeedCardModuleManager.self)
        self.actionSettingStore = try resolver.resolve(assert: FeedSettingStore.self)
    }

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
    func removeFeedCard(channel: Basic_V1_Channel,
                     feedPreviewPBType: RustPB.Basic_V1_FeedCard.EntityType?,
                     from vc: UIViewController?) {
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.LarkFeed.Lark_IM_YouAreNotInThisChat_Text, numberOfLines: 0)
        dialog.addPrimaryButton(text: BundleI18n.LarkFeed.Lark_Legacy_IKnow, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.feedAPI.removeFeedCard(channel: channel, feedType: feedPreviewPBType).subscribe().disposed(by: self.disposeBag)
        })
        vc?.present(dialog, animated: true, completion: nil)
    }

    func observeSelect() -> Observable<String?> {
        feedSelection.observeSelect()
    }

    /// 设置Feed选中
    func setSelected(feedId: String?) {
        feedSelection.setSelected(feedId: feedId)
    }

    /// 获取上/下一次选中的记录
    func selectedRecordID(prev: Bool) -> String? {
        return feedSelection.selectedRecordID(prev: prev)
    }

    /// 获取当前选中Feed的FeedId
    func getSelected() -> String? {
        feedSelection.getSelected()
    }
}
