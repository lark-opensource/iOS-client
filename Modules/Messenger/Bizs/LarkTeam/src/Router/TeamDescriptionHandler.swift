//
//  TeamDescriptionHandler.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/8/19.
//

import RxSwift
import Swinject
import Foundation
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkNavigator

final class TeamDescriptionHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: TeamDescriptionBody, req: EENavigator.Request, res: Response) throws {
        let teamAPI = try self.userResolver.resolve(assert: TeamAPI.self)
        let vc = TeamDescriptionViewController(team: body.team,
                                               teamAPI: teamAPI,
                                               navigator: userResolver.navigator)
        res.end(resource: vc)
    }
}
