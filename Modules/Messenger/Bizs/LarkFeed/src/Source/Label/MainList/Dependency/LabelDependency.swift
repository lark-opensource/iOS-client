//
//  LabelDependency.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/21.
//

import Foundation
import LarkSDKInterface
import LarkMessengerInterface
import RxSwift
import RxRelay
import RustPB
import LarkModel
import LarkRustClient
import SwiftProtobuf
import RunloopTools
import LarkContainer
import LarkOpenFeed

protocol LabelDependency: UserResolverWrapper {
    // MARK: 标签API
    var pushLabels: Observable<PushLabel> { get }

    // 批量清理badge
    var batchClearBadgeService: BatchClearBagdeService { get }

    // 批量免打扰
    var batchMuteFeedCardsService: BatchMuteFeedCardsService { get }

    var feedGuideDependency: FeedGuideDependency { get }

    // 获取标签列表（一级列表）
    func getLabels(nextPosition: Int64?, count: Int32) -> Observable<GetLabelsResponse>

    // 获取指定标签下的feed（二级列表）
    func getLabelFeeds(labelId: Int, nextCursor: Feed_V1_GroupCursor?, count: Int32, orderBy: Feed_V1_FeedGroupItemOrderRule) -> Observable<GetLabelFeedsResponse>

    // 删除标签
    func deleteLabel(id: Int64) -> Observable<UpdateLabelResponse>

    // 清除标签中全部未读
    func clearLabelBadage(label: LabelViewModel, taskID: String)

    // 查询是否存在 免打扰、at all 提醒的feed
    func getBatchFeedsActionState(label: LabelViewModel, queryMuteAtAll: Bool) -> Observable<RustPB.Feed_V1_QueryMuteFeedCardsResponse>

    // 批量操作：免打扰、at all 提醒
    func setBatchFeedsState(label: LabelViewModel, taskID: String, action: Feed_V1_BatchMuteFeedCardsRequest.MuteActionType)

    // MARK: feed全局API
    var pushFeedPreview: Observable<PushFeedPreview> { get }
    /// Feed选中
    var selectFeedObservable: Observable<FeedSelection?> { get }
    func setSelected(feedId: String?)

    var badgeStyleObservable: Observable<Settings_V1_BadgeStyle> { get }

    // MARK: feed全局chat下的API
    func preloadChatFeed(by ids: [String]) -> Observable<Void>
    /// 获取被踢出群的原因
    func getKickInfo(chatId: String) -> Observable<String>
    /// 被踢出群聊时，点击进入Chat，需要进行弹框拦截，同时移除该Feed
    func removeFeedCard(channel: Basic_V1_Channel,
                        feedPreviewPBType: Basic_V1_FeedCard.EntityType?)

    /// 更新二级标签的消息展示设置规则
    func updateMsgDisplayRuleMap(_ feedGroupDisplayFeedRule: [Int64: Feed_V1_DisplayFeedRule]) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse>

    var feedCardModuleManager: FeedCardModuleManager { get }

    var iPadStatus: String? { get }
}
