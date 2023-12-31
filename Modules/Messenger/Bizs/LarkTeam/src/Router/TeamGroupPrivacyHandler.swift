//
//  TeamGroupPrivacyHandler.swift
//  LarkTeam
//
//  Created by xiaruzhen on 2023/2/27.
//

import RxSwift
import Swinject
import Foundation
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkNavigator

typealias TeamGroupPrivacyController = TeamBaseViewController

final class TeamGroupPrivacyHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: TeamGroupPrivacyBody, req: EENavigator.Request, res: Response) throws {
        let teamAPI = try userResolver.resolve(assert: TeamAPI.self)
        let chatAPI = try userResolver.resolve(assert: ChatAPI.self)
        let viewModel = TeamGroupPrivacySettingVM(teamId: body.teamId,
                                       chatId: body.chatId,
                                       teamName: body.teamName,
                                       isMessageVisible: body.isMessageVisible,
                                       isCrossTenant: body.isCrossTenant,
                                       ownerAuthority: body.ownerAuthority,
                                       discoverable: body.discoverable,
                                       messageVisibility: body.messageVisibility,
                                       teamAPI: teamAPI,
                                       chatAPI: chatAPI,
                                       navigator: userResolver.navigator)
        let vc = TeamGroupPrivacyController(viewModel: viewModel)
        res.end(resource: vc)
    }
}
