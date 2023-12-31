//
//  FeedTeamDependency.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
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

protocol FeedTeamDependency: UserResolverWrapper {
    var pushItems: Observable<Im_V1_PushItems> { get }
    var pushTeams: Observable<Im_V1_PushTeams> { get }
    var pushItemExpired: Observable<Im_V1_PushItemExpired> { get }
    var pushFeedPreview: Observable<PushFeedPreview> { get }
    var pushTeamItemChats: Observable<PushTeamItemChats> { get }
    var badgeStyleObservable: Observable<Settings_V1_BadgeStyle> { get }
    var pushWebSocketStatus: Observable<PushWebSocketStatus> { get }
    var batchClearBadgeService: BatchClearBagdeService { get } // 批量清理badge
    var batchMuteFeedCardsService: BatchMuteFeedCardsService { get } // 批量免打扰
    var feedGuideDependency: FeedGuideDependency { get }
    var filterDataStore: FilterDataStore { get }
    //获取团队列表
    func getTeams() -> Observable<GetTeamsResult>

    //获取团队下的群组列表
    func getChats(teamIds: [Int]) -> Observable<GetChatsResult>

    //预加载群组列表 在UI显示时，客户端调用以加载团队下群组列表
    func preloadItems(parentIds: [Int]) -> Observable<Im_V1_PreloadItemsResponse>

    func preloadChatFeed(by ids: [String]) -> Observable<Void>

    func observeSelect() -> Observable<String?>
    var selectFeedObservable: Observable<FeedSelection?> { get }

    /// 设置Feed选中
    func setSelected(feedId: String?)

    /// 获取当前选中Feed的FeedId
    func getSelected() -> String?

    func createShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void>

    func deleteShortcuts(_ shortcuts: [Feed_V1_Shortcut]) -> Observable<Void>

    func flagFeedCard(_ id: String, isFlaged: Bool, entityType: Basic_V1_FeedCard.EntityType) -> Observable<Void>

    func markFeedCard(_ id: String, isDelayed: Bool) -> Observable<FeedPreview>

    /// 被踢出群聊时，点击进入Chat，需要进行弹框拦截，同时移除该Feed
    func removeFeedCard(channel: Basic_V1_Channel,
                        feedPreviewPBType: Basic_V1_FeedCard.EntityType?)

    /// 获取被踢出群的原因
    func getKickInfo(chatId: String) -> Observable<String>

    var isByteDancer: Bool { get }
    /// 创建群组
    func createTeamGroup(teamId: Int64, ownerID: Int64, defaultChatId: Int64, memberCount: Int32, allowCreate: Bool, isAllowAddTeamPrivateChat: Bool)

    /// 绑定已有群组到团队
    func addTeamGroup(teamId: Int64, teamName: String, isAllowAddTeamPrivateChat: Bool)

    /// 添加团队成员
    func openAddTeamMemberPicker(teamId: Int64, defaultChatID: Int64, ownerID: Int64)

    func hideTeamChat(chatId: Int, isHidden: Bool) -> Observable<Im_V1_PatchItemResponse>

    func transform(feed: FeedPreview, teamID: Int64) -> ChatData

    // 清除团队所有未读
    func clearTeamBadge(teamID: Int64, taskID: String)

    // 查询是否存在 免打扰、at all 提醒的feed
    func getBatchFeedsActionState(teamID: Int64, queryMuteAtAll: Bool) -> Observable<RustPB.Feed_V1_QueryMuteFeedCardsResponse>

    // 批量操作：免打扰、at all 提醒
    func setBatchFeedsState(teamID: Int64, taskID: String, action: Feed_V1_BatchMuteFeedCardsRequest.MuteActionType)

    func deleteTeamMemberRequest(teamId: Int64,
                                 chatterIds: [Int64],
                                 newOwnerId: Int64?) -> Observable<DeleteTeamMemberResponse>
}
