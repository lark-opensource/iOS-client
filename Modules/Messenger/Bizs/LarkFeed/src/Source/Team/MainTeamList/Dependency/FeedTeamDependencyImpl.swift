//
//  FeedTeamDependencyImpl.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/13.
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

final class FeedTeamDependencyImpl: FeedTeamDependency {
    let userResolver: UserResolver

    private let feedAPI: FeedAPI
    private let feedSelection: FeedSelectionService
    private let chatAPI: ChatAPI
    private let teamAPI: TeamAPI
    private let passportUserService: PassportUserService
    let batchClearBadgeService: BatchClearBagdeService
    let batchMuteFeedCardsService: BatchMuteFeedCardsService
    let feedGuideDependency: FeedGuideDependency
    let filterDataStore: FilterDataStore

    var selectFeedObservable: Observable<FeedSelection?> {
        return feedSelection.selectFeedObservable
    }

    let pushItems: Observable<Im_V1_PushItems>
    let pushTeams: Observable<Im_V1_PushTeams>
    let pushItemExpired: Observable<Im_V1_PushItemExpired>
    let pushFeedPreview: Observable<PushFeedPreview>
    let pushTeamItemChats: Observable<PushTeamItemChats>
    let badgeStyleObservable: Observable<Settings_V1_BadgeStyle>
    let pushWebSocketStatus: Observable<PushWebSocketStatus>
    private let context: FeedContextService
    private let disposeBag = DisposeBag()

    init(resolver: UserResolver,
         pushItems: Observable<Im_V1_PushItems>,
         pushTeams: Observable<Im_V1_PushTeams>,
         pushItemExpired: Observable<Im_V1_PushItemExpired>,
         pushFeedPreview: Observable<PushFeedPreview>,
         pushTeamItemChats: Observable<PushTeamItemChats>,
         badgeStyleObservable: Observable<Settings_V1_BadgeStyle>,
         pushWebSocketStatus: Observable<PushWebSocketStatus>,
         batchClearBadgeService: BatchClearBagdeService,
         batchMuteFeedCardsService: BatchMuteFeedCardsService,
         feedGuideDependency: FeedGuideDependency,
         context: FeedContextService,
         filterDataStore: FilterDataStore
    ) throws {
        self.userResolver = resolver
        self.feedAPI = try resolver.resolve(assert: FeedAPI.self)
        self.feedSelection = try resolver.resolve(assert: FeedSelectionService.self)
        self.chatAPI = try resolver.resolve(assert: ChatAPI.self)
        self.teamAPI = try resolver.resolve(assert: TeamAPI.self)
        self.passportUserService = try resolver.resolve(assert: PassportUserService.self)
        self.feedGuideDependency = feedGuideDependency

        self.pushItems = pushItems
        self.pushTeams = pushTeams
        self.pushItemExpired = pushItemExpired
        self.pushFeedPreview = pushFeedPreview
        self.pushTeamItemChats = pushTeamItemChats
        self.badgeStyleObservable = badgeStyleObservable
        self.pushWebSocketStatus = pushWebSocketStatus
        self.batchClearBadgeService = batchClearBadgeService
        self.batchMuteFeedCardsService = batchMuteFeedCardsService
        self.context = context
        self.filterDataStore = filterDataStore
    }

    //获取团队列表
    func getTeams() -> Observable<GetTeamsResult> {
        return feedAPI.getTeams()
    }

    //获取团队下的群组列表
    func getChats(teamIds: [Int]) -> Observable<GetChatsResult> {
        return feedAPI.getChats(parentIDs: teamIds)
    }

    //预加载群组列表 在UI显示时，客户端调用以加载团队下群组列表
    func preloadItems(parentIds: [Int]) -> Observable<Im_V1_PreloadItemsResponse> {
        return feedAPI.preloadItems(parentIds: parentIds)
    }

    func preloadChatFeed(by ids: [String]) -> Observable<Void> {
        feedAPI.preloadFeedCards(by: ids, feedPosition: nil)
    }

    func observeSelect() -> Observable<String?> {
        feedSelection.observeSelect()
    }

    /// 设置Feed选中
    func setSelected(feedId: String?) {
        feedSelection.setSelected(feedId: feedId)
    }

    /// 获取当前选中Feed的FeedId
    func getSelected() -> String? {
        feedSelection.getSelected()
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

    var isByteDancer: Bool {
        return passportUserService.userTenant.isByteDancer
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

    /// 创建群组
    func createTeamGroup(teamId: Int64, ownerID: Int64, defaultChatId: Int64, memberCount: Int32, allowCreate: Bool, isAllowAddTeamPrivateChat: Bool) {
        guard let from = self.context.page else { return }
        if !allowCreate, "\(ownerID)" != passportUserService.user.userID, let window = self.context.page?.view.window {
            UDToast.showTips(with: BundleI18n.LarkTeam.Project_MV_AdminSetCantTeams, on: window)
            return
        }
        navigator.present(body: TeamCreateGroupBody(teamId: teamId,
                                                           chatId: "\(defaultChatId)",
                                                           ownerId: ownerID,
                                                           isAllowAddTeamPrivateChat: isAllowAddTeamPrivateChat),
                                 wrap: LkNavigationController.self,
                                 from: from,
                                 prepare: {
                                    $0.modalPresentationStyle = .formSheet
        })
    }
    func deleteTeamMemberRequest(teamId: Int64,
                                 chatterIds: [Int64],
                                 newOwnerId: Int64?) -> Observable<DeleteTeamMemberResponse> {
        self.teamAPI.deleteTeamMemberRequest(teamId: teamId,
                                             chatterIds: chatterIds,
                                             chatIds: [],
                                             newOwnerId: nil)
    }

    /// 绑定已有群组到团队
    func addTeamGroup(teamId: Int64,
                      teamName: String,
                      isAllowAddTeamPrivateChat: Bool) {
        guard let from = self.context.page else { return }
        var body = TeamBindGroupBody(teamId: teamId)
        navigator.present(
            body: body,
            from: from,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    /// 添加团队成员
    func openAddTeamMemberPicker(teamId: Int64, defaultChatID: Int64, ownerID: Int64) {
        guard let from = self.context.page else { return }
        let body = TeamAddMemberBody(teamId: teamId,
                                     forceSelectedChatterIds: [ownerID])
        navigator.present(
            body: body,
            from: from,
            prepare: { $0.modalPresentationStyle = .formSheet }
        )
    }

    func hideTeamChat(chatId: Int, isHidden: Bool) -> Observable<Im_V1_PatchItemResponse> {
        return feedAPI.hideTeamChat(chatId: chatId, isHidden: isHidden)
    }

    func transform(feed: FeedPreview, teamID: Int64) -> ChatData {
        return ChatData.transform(chatAPI: chatAPI, feed: feed, teamID: teamID)
    }

    func clearTeamBadge(teamID: Int64, taskID: String) {
        feedAPI.clearTeamBadge(taskID: taskID, teams: [teamID]).subscribe().disposed(by: disposeBag)
    }
    // 查询是否存在 免打扰、at all 提醒的feed
    func getBatchFeedsActionState(teamID: Int64, queryMuteAtAll: Bool) -> Observable<Feed_V1_QueryMuteFeedCardsResponse> {
        var teams: [Int64] = []
        teams.append(teamID)
        return feedAPI.getBatchFeedsActionState(feeds: [], filters: [], teams: teams, tags: [], queryMuteAtAll: queryMuteAtAll)
    }

    // 批量操作：免打扰、at all 提醒
    func setBatchFeedsState(teamID: Int64, taskID: String, action: Feed_V1_BatchMuteFeedCardsRequest.MuteActionType) {
        var teams: [Int64] = []
        teams.append(teamID)
        feedAPI.setBatchFeedsState(taskID: taskID, feeds: [], filters: [], teams: teams, tags: [], action: action).subscribe().disposed(by: disposeBag)
    }
}
