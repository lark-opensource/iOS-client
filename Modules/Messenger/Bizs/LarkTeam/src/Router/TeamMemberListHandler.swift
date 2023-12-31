//
//  TeamMemberListHandler.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/20.
//

import RxSwift
import Swinject
import LarkCore
import Foundation
import EENavigator
import LKCommonsLogging
import LarkSDKInterface
import LarkMessengerInterface
import RustPB
import LarkNavigator
import LarkContainer
import LarkGuideUI
import LarkGuide

final class TeamMemberListHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: TeamMemberListBody, req: EENavigator.Request, res: Response) throws {
        let pushCenter = try self.userResolver.userPushCenter
        let teamAPI = try self.userResolver.resolve(assert: TeamAPI.self)
        let guideService = try self.userResolver.resolve(assert: NewGuideService.self)
        let viewModel = TeamMemberViewModel(
            teamId: body.teamId,
            currentUserId: userResolver.userID,
            displayMode: body.mode,
            navItemType: body.navItemType,
            teamAPI: teamAPI,
            isTransferTeam: body.isTransferTeam,
            pushTeamMembers: pushCenter.observable(for: PushTeamMembers.self),
            pushTeams: pushCenter.observable(for: PushTeams.self),
            pushItems: pushCenter.observable(for: PushItems.self),
            scene: body.scene,
            guideService: guideService,
            userResolver: self.userResolver,
            selectdMemberCallback: body.selectdMemberCallback)
        let vc = TeamMemberViewController(viewModel: viewModel)
        res.end(resource: vc)
    }
}
