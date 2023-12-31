//
//  LabelDependencyImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/21.
//

import Foundation
import LarkUIKit
import LarkSDKInterface
import LarkMessengerInterface
import LarkOpenFeed
import RxSwift
import RxRelay
import RustPB
import LarkModel
import LarkRustClient
import SwiftProtobuf
import RunloopTools
import LarkAccountInterface
import EENavigator
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignDialog
import LarkBizAvatar
import LarkNavigation
import Swinject
import LarkContainer

final class LabelDependencyImpl: LabelDependency {
    let userResolver: UserResolver
    private let feedAPI: FeedAPI
    private let feedSelection: FeedSelectionService
    private let chatAPI: ChatAPI
    let batchClearBadgeService: BatchClearBagdeService
    let batchMuteFeedCardsService: BatchMuteFeedCardsService
    let feedGuideDependency: FeedGuideDependency

    let pushLabels: Observable<PushLabel>
    let pushFeedPreview: Observable<PushFeedPreview>
    let badgeStyleObservable: Observable<Settings_V1_BadgeStyle>

    let feedCardModuleManager: FeedCardModuleManager

    private let context: FeedContextService
    private let disposeBag = DisposeBag()

    private let threeBarService: FeedThreeBarService?

    init(resolver: UserResolver,
         pushLabels: Observable<PushLabel>,
         pushFeedPreview: Observable<PushFeedPreview>,
         badgeStyleObservable: Observable<Settings_V1_BadgeStyle>,
         batchClearBadgeService: BatchClearBagdeService,
         batchMuteFeedCardsService: BatchMuteFeedCardsService,
         feedGuideDependency: FeedGuideDependency,
         context: FeedContextService
    ) throws {
        self.userResolver = resolver
        self.feedAPI = try resolver.resolve(assert: FeedAPI.self)
        self.feedSelection = try resolver.resolve(assert: FeedSelectionService.self)
        self.chatAPI = try resolver.resolve(assert: ChatAPI.self)

        self.pushLabels = pushLabels
        self.pushFeedPreview = pushFeedPreview
        self.badgeStyleObservable = badgeStyleObservable
        self.batchClearBadgeService = batchClearBadgeService
        self.batchMuteFeedCardsService = batchMuteFeedCardsService
        self.feedGuideDependency = feedGuideDependency
        self.context = context
        self.feedCardModuleManager = try resolver.resolve(assert: FeedCardModuleManager.self)
        self.threeBarService = try? resolver.resolve(assert: FeedThreeBarService.self)
    }

    var iPadStatus: String? {
        if let unfold = threeBarService?.padUnfoldStatus {
            return unfold ? "unfold" : "fold"
        }
        return nil
    }
}

// MARK: 标签API
extension LabelDependencyImpl {
    // 获取标签列表（一级列表）
    func getLabels(nextPosition: Int64?, count: Int32) -> Observable<GetLabelsResponse> {
        return feedAPI.getLabels(position: nextPosition, count: count)
    }

    // 获取指定标签下的feeds（二级列表）
    func getLabelFeeds(labelId: Int, nextCursor: Feed_V1_GroupCursor?, count: Int32, orderBy: Feed_V1_FeedGroupItemOrderRule) -> Observable<GetLabelFeedsResponse> {
        return feedAPI.getLabelFeeds(labelId: Int64(labelId), nextCursor: nextCursor, count: count, orderBy: orderBy)
    }

    // 删除标签
    func deleteLabel(id: Int64) -> Observable<UpdateLabelResponse> {
        return feedAPI.deleteLabel(id: id)
    }

    func clearLabelBadage(label: LabelViewModel, taskID: String) {
        var labelPB = Feed_V1_TagIdentity()
        labelPB.tagID = label.meta.feedGroup.id
        labelPB.feedGroupType = Int32(label.meta.feedGroup.type.rawValue)
        feedAPI.clearLabelBadge(taskID: taskID, labels: [labelPB]).subscribe().disposed(by: disposeBag)
    }
    // 查询是否存在 免打扰、at all 提醒的feed
    func getBatchFeedsActionState(label: LabelViewModel, queryMuteAtAll: Bool) -> Observable<RustPB.Feed_V1_QueryMuteFeedCardsResponse> {
        var tags: [Feed_V1_TagIdentity] = []
        var tag = Feed_V1_TagIdentity()
        tag.tagID = label.meta.feedGroup.id
        tag.feedGroupType = Int32(label.meta.feedGroup.type.rawValue)
        tags.append(tag)
        return feedAPI.getBatchFeedsActionState(feeds: [], filters: [], teams: [], tags: tags, queryMuteAtAll: queryMuteAtAll)
    }

    // 批量操作：免打扰、at all 提醒
    func setBatchFeedsState(label: LabelViewModel, taskID: String, action: Feed_V1_BatchMuteFeedCardsRequest.MuteActionType) {
        var tags: [Feed_V1_TagIdentity] = []
        var tag = Feed_V1_TagIdentity()
        tag.tagID = label.meta.feedGroup.id
        tag.feedGroupType = Int32(label.meta.feedGroup.type.rawValue)
        tags.append(tag)
        feedAPI.setBatchFeedsState(taskID: taskID, feeds: [], filters: [], teams: [], tags: tags, action: action)
            .subscribe()
            .disposed(by: disposeBag)
    }

    func updateMsgDisplayRuleMap(_ feedGroupDisplayFeedRule: [Int64: Feed_V1_DisplayFeedRule]) -> Observable<Feed_V1_UpdateFeedFilterSettingsResponse> {
        return feedAPI.updateMsgDisplayRuleMap(nil, feedGroupDisplayFeedRule)
    }
}

// MARK: feed全局API
extension LabelDependencyImpl {
    var selectFeedObservable: Observable<FeedSelection?> {
        feedSelection.selectFeedObservable
    }

    /// 设置Feed选中
    func setSelected(feedId: String?) {
        feedSelection.setSelected(feedId: feedId)
    }
}

// MARK: feed全局chat下的API
extension LabelDependencyImpl {
    func preloadChatFeed(by ids: [String]) -> Observable<Void> {
        feedAPI.preloadFeedCards(by: ids, feedPosition: nil)
    }

    func removeFeedCard(channel: Basic_V1_Channel,
                        feedPreviewPBType: Basic_V1_FeedCard.EntityType?) {
        return feedAPI.removeFeedCard(channel: channel, feedType: feedPreviewPBType)
            .subscribe()
            .disposed(by: disposeBag)
    }

    func getKickInfo(chatId: String) -> Observable<String> {
        return chatAPI.getKickInfo(chatId: chatId)
    }
}
