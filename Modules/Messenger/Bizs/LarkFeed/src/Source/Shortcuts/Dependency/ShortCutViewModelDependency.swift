//
//  ShortCutViewModelDependency.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/15.
//

import UIKit
import Foundation
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import LarkContainer

protocol ShortCutViewModelDependency: UserResolverWrapper {

    // 获取列表数据
    func loadShortcuts(strategy: Basic_V1_SyncDataStrategy) -> Observable<FeedContextResponse>

    // 通过拖拽更换了shortcut的位置，需要告诉server
    func update(shortcut: RustPB.Feed_V1_Shortcut, newPosition: Int) -> Observable<Void>

    func removeFeedCard(channel: Basic_V1_Channel,
                     feedPreviewPBType: RustPB.Basic_V1_FeedCard.EntityType?,
                     from vc: UIViewController?)
    // 预加载
    func preloadChatFeed(by ids: [String])

    /// shortcut的推送
    var pushShortcuts: Observable<PushShortcuts> { get }
    var pushFeedPreview: Observable<PushFeedPreview> { get }

    /// BadgeStyle的推送
    var badgeStyleObservable: Observable<Settings_V1_BadgeStyle> { get }

    /// 获取当前选中Feed的FeedId
    func getSelected() -> String?
}
