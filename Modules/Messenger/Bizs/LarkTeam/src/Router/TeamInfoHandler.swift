//
//  TeamInfoHandler.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/8/17.
//

import RxSwift
import Swinject
import Foundation
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkNavigator

typealias TeamInfoViewController = TeamBaseViewController

final class TeamInfoHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: TeamInfoBody, req: EENavigator.Request, res: Response) throws {
        let pushTeams = try self.userResolver.userPushCenter.observable(for: PushTeams.self)
        let teamAPI = try self.userResolver.resolve(assert: TeamAPI.self)
        let viewModel = TeamInfoViewModel(
            team: body.team,
            teamAPI: teamAPI,
            pushTeams: pushTeams,
            userResolver: userResolver)
        let vc = TeamInfoViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}
