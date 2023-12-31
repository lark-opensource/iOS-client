//
//  BindItemInToTeamHandler.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/12/29.
//

import Foundation
import LarkOpenFeed
import LarkSDKInterface
import EENavigator
import Swinject
import RxSwift
import RxCocoa
import LarkAccountInterface
import LarkNavigator
import LarkMessengerInterface
import UniverseDesignDialog
import UniverseDesignToast

final class BindItemInToTeamHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Feed.userScopeCompatibleMode }

    func handle(_ body: BindItemInToTeamBody, req: EENavigator.Request, res: Response) throws {
        guard let currentVC = req.from.fromViewController else { return }
        let resolver = self.userResolver
        let teamAPI = try resolver.resolve(assert: TeamAPI.self)
        let pushFeedPreview = try resolver.userPushCenter.observable(for: PushFeedPreview.self)
        let feedTeamViewModel = try resolver.resolve(assert: FeedTeamViewModel.self)
        let teamAction = try resolver.resolve(assert: TeamActionService.self)
        let viewModel = TeamListViewModel(userResolver: resolver,
                                          teamAPI: teamAPI,
                                          pushFeedPreview: pushFeedPreview,
                                          feedPreview: body.feedPreview,
                                          feedTeamViewModel: feedTeamViewModel,
                                          teamAction: teamAction)
        FeedTracker.Team.View.AddChatToTeamMenuView()
        res.end(resource: TeamListController(viewModel: viewModel))
    }
}
