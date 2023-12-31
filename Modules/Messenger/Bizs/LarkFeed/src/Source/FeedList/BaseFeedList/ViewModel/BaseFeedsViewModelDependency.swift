//
//  BaseFeedsViewModelDependency.swift
//  LarkFeed
//
//  Created by 袁平 on 2020/7/2.
//

import UIKit
import Foundation
import RustPB
import RxSwift
import LarkModel
import RxCocoa
import RxDataSources
import LarkSDKInterface
import UniverseDesignToast
import ThreadSafeDataStructure
import RunloopTools
import LKCommonsLogging
import LarkPerf
import AppReciableSDK
import LarkContainer
import LarkOpenFeed

protocol BaseFeedsViewModelDependency: UserResolverWrapper {

    func moveToDone(feedId: String, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void>

    func createShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void>

    func deleteShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void>

    func flagFeedCard(_ id: String, isFlaged: Bool, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void>

    func markFeedCard(_ id: String, isDelayed: Bool) -> Observable<FeedPreview>

    func removeFeedCard(channel: Basic_V1_Channel,
                     feedPreviewPBType: RustPB.Basic_V1_FeedCard.EntityType?,
                     from vc: UIViewController?)

    /// iPad选中态监听
    func observeSelect() -> Observable<String?>

    /// 设置Feed选中
    func setSelected(feedId: String?)

    /// 获取上/下一次选中的 ID 记录
    func selectedRecordID(prev: Bool) -> String?

    /// 获取当前选中Feed的FeedId
    func getSelected() -> String?

    // Push: PushInboxCardsHandler
    var pushFeedPreview: Observable<PushFeedPreview> { get }
    // Push: BadgeStyle
    var badgeStyleObservable: Observable<Settings_V1_BadgeStyle> { get }
    // Push: PushThreadFeedAvatarChangesHandler
    var pushThreadFeedAvatarChanges: Observable<PushThreadFeedAvatarChanges> { get }
    var is24HourTime: BehaviorRelay<Bool> { get }

    var feedCardModuleManager: FeedCardModuleManager { get }

    var actionSettingStore: FeedSettingStore { get }
}
