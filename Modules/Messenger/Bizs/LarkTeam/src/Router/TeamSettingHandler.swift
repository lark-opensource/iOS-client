//
//  TeamSettingHandler.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/9.
//

import RxSwift
import Swinject
import Foundation
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import LarkNavigator

typealias TeamSettingViewController = TeamBaseViewController

final class TeamSettingHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: TeamSettingBody, req: EENavigator.Request, res: Response) throws {
        let teamAPI = try userResolver.resolve(assert: TeamAPI.self)
        let pushCenter = try userResolver.userPushCenter
        let currentUserId = userResolver.userID
        let rustConfigurationService = try userResolver.resolve(assert: RustConfigurationService.self)
        let viewModel = TeamSettingViewModel(team: body.team,
                                             teamMembersMaxCount: rustConfigurationService.preloadGroupPreviewChatterCount,
                                             currentUserId: currentUserId,
                                             teamAPI: teamAPI,
                                             pushTeams: pushCenter.observable(for: PushTeams.self),
                                             pushItems: pushCenter.observable(for: PushItems.self),
                                             navigator: userResolver.navigator)
        let vc = TeamSettingViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}
