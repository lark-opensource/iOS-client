//
//  TeamCreateGroupHandler.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/9.
//

import RxSwift
import Swinject
import LarkCore
import Foundation
import EENavigator
import UniverseDesignToast
import LarkMessengerInterface
import LarkSDKInterface
import LarkNavigator

typealias CreateTeamGroupViewController = TeamBaseViewController

final class TeamCreateGroupHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: TeamCreateGroupBody, req: EENavigator.Request, res: Response) throws {
        let teamAPI = try self.userResolver.resolve(assert: TeamAPI.self)
        let viewModel = CreateTeamGroupViewModel(teamId: body.teamId,
                                                 chatId: body.chatId,
                                                 isAllowAddTeamPrivateChat: body.isAllowAddTeamPrivateChat,
                                                 teamAPI: teamAPI,
                                                 userResolver: userResolver)
        viewModel.fromVC = req.from.fromViewController
        let vc = CreateTeamGroupViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}
