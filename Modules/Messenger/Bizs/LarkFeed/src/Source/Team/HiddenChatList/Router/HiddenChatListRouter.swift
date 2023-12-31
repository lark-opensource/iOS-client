//
//  HiddenChatListRouter.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/27.
//

import Foundation
import LarkMessengerInterface
import Swinject
import LarkUIKit
import EENavigator
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import LarkModel
import LarkAccountInterface
import LarkNavigator
import LarkFeedBase
import LarkOpenFeed

struct HiddenTeamChatListBody: PlainBody {
    public static let pattern = "//client/team/hiddenlist"
    let teamViewModel: FeedTeamItemViewModel

    public init(teamViewModel: FeedTeamItemViewModel) {
        self.teamViewModel = teamViewModel
    }
}

final class HiddenChatListHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }
    func handle(_ body: HiddenTeamChatListBody, req: EENavigator.Request, res: Response) throws {
        let resolver = self.userResolver
        let pushCenter = try resolver.userPushCenter
        let context = try resolver.resolve(assert: FeedContextService.self)
        let pushItems = pushCenter.observable(for: Im_V1_PushItems.self)
        let pushTeams = pushCenter.observable(for: Im_V1_PushTeams.self)
        let pushItemExpired = pushCenter.observable(for: Im_V1_PushItemExpired.self)
        let pushFeedPreview = pushCenter.observable(for: LarkFeed.PushFeedPreview.self)
        let pushTeamItemChats = pushCenter.observable(for: LarkFeed.PushTeamItemChats.self)
        let badgeStyleObservable = try resolver.resolve(assert: FeedBadgeConfigService.self).badgeStyleObservable
        let pushWebSocketStatus = pushCenter.observable(for: PushWebSocketStatus.self)
        let batchClearBagdeService = try resolver.resolve(assert: BatchClearBagdeService.self)
        let batchMuteFeedCardsService = try resolver.resolve(assert: BatchMuteFeedCardsService.self)
        let feedGuideDependency = try resolver.resolve(assert: FeedGuideDependency.self)
        let filterDataStore = try resolver.resolve(assert: FilterDataStore.self)

        let dependency = try FeedTeamDependencyImpl(
            resolver: resolver,
            pushItems: pushItems,
            pushTeams: pushTeams,
            pushItemExpired: pushItemExpired,
            pushFeedPreview: pushFeedPreview,
            pushTeamItemChats: pushTeamItemChats,
            badgeStyleObservable: badgeStyleObservable,
            pushWebSocketStatus: pushWebSocketStatus,
            batchClearBadgeService: batchClearBagdeService,
            batchMuteFeedCardsService: batchMuteFeedCardsService,
            feedGuideDependency: feedGuideDependency,
            context: context,
            filterDataStore: filterDataStore)
        let teamVM = FeedTeamItemViewModel(item: body.teamViewModel.teamItem, teamEntity: body.teamViewModel.teamEntity)
        let vm = HiddenChatListViewModel(teamViewModel: teamVM, dependency: dependency)
        let vc = HiddenChatListViewController(viewModel: vm)
        res.end(resource: vc)
    }
}
