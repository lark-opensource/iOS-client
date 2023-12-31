//
//  TeamEventHandler.swift
//  LarkTeam
//
//  Created by chaishenghua on 2022/8/31.
//

import RxSwift
import Swinject
import LarkCore
import Foundation
import EENavigator
import UniverseDesignToast
import LarkMessengerInterface
import LarkSDKInterface
import LarkContainer
import LarkNavigator

final class TeamEventHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: TeamEventBody, req: EENavigator.Request, res: Response) throws {
        let teamAPI = try self.userResolver.resolve(assert: TeamAPI.self)
        let chatAPI = try self.userResolver.resolve(assert: ChatAPI.self)
        let dependency = TeamEventDependencyImpl(teamAPI: teamAPI, chatAPI: chatAPI, userResolver: userResolver)
        let viewModel = TeamEventViewModel(teamEventDependency: dependency, teamID: body.teamID)
        let vc = TeamEventViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}
