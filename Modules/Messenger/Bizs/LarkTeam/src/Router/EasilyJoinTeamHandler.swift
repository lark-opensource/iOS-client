//
//  EasilyJoinTeamHandler.swift
//  LarkTeam
//
//  Created by chaishenghua on 2023/1/12.
//

import Foundation
import LarkMessengerInterface
import EENavigator
import LarkSDKInterface
import UniverseDesignDialog
import UniverseDesignToast
import RxSwift
import Swinject
import LarkUIKit
import LarkNavigator

final class EasilyJoinTeamHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { TeamUserScope.userScopeCompatibleMode }

    func handle(_ body: EasilyJoinTeamBody, req: EENavigator.Request, res: Response) throws {
        guard let vc = req.from.fromViewController else { return }
        let userResolver = self.userResolver
        let feedAPI = try userResolver.resolve(assert: FeedAPI.self)
        let teamAPI = try userResolver.resolve(assert: TeamAPI.self)
        let service = try userResolver.resolve(assert: TeamActionService.self)
        let feedPreview = body.feedpreview
        feedAPI.getTeams()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { teams in
                var hasTeam = false
                // 判断是否有还未关联的团队
                for team in teams.teamEntities.values {
                    if feedPreview.chatFeedPreview?.teamEntity.joinedTeams[team.id] == nil {
                        hasTeam = true
                        break
                    }
                }
                if hasTeam {
                    let body = BindItemInToTeamBody(feedPreview: feedPreview)
                    userResolver.navigator.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: vc,
                        prepare: { $0.modalPresentationStyle = .formSheet })
                    res.end(resource: nil)
                } else {
                    let body = CreateTeamBody { team in
                        service.joinTeamDialog(team: team, feedPreview: feedPreview, on: vc, isNewTeam: true, successCallBack: nil)
                    }
                    userResolver.navigator.present(
                        body: body,
                        wrap: LkNavigationController.self,
                        from: vc,
                        prepare: { $0.modalPresentationStyle = .formSheet })
                    res.end(resource: nil)
                }
            })
        res.wait()
    }
}
