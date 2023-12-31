//
//  TeamNameConfigHandler.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/18.
//

import RxSwift
import Swinject
import LarkCore
import Foundation
import EENavigator
import LarkMessengerInterface
import LarkContainer
import LarkSDKInterface
import LarkNavigator

final class TeamNameConfigHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: TeamNameConfigBody, req: EENavigator.Request, res: Response) throws {
        let teamAPI = try userResolver.resolve(assert: TeamAPI.self)
        let vc = TeamNameConfigViewController(team: body.team,
                                              teamAPI: teamAPI,
                                              hasAccess: body.hasAccess,
                                              navigator: userResolver.navigator)
        res.end(resource: vc)
    }
}
