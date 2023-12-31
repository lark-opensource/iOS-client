//
//  CreateTeamHandler.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/5.
//

import RxSwift
import Swinject
import LarkCore
import Foundation
import EENavigator
import LarkMessengerInterface
import LarkSDKInterface
import LarkNavigator

typealias CreateTeamViewController = TeamBaseViewController

final class CreateTeamHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: CreateTeamBody, req: EENavigator.Request, res: Response) throws {
        let teamAPI = try self.userResolver.resolve(assert: TeamAPI.self)
        let viewModel = CreateTeamViewModel(teamAPI: teamAPI,
                                            currentUserId: userResolver.userID,
                                            userResolver: userResolver,
                                            successCallback: body.successCallback)
        viewModel.fromVC = req.from.fromViewController
        let vc = CreateTeamViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}
