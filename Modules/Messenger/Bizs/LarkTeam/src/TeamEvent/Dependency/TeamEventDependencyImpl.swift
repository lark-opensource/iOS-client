//
//  TeamEventDependencyImpl.swift
//  LarkTeam
//
//  Created by chaishenghua on 2022/8/30.
//

import Foundation
import LarkContainer
import LarkSDKInterface
import ServerPB
import RxSwift
import Swinject

final class TeamEventDependencyImpl: TeamEventDependency {
    let teamAPI: TeamAPI
    let chatAPI: ChatAPI
    let userResolver: LarkContainer.UserResolver
    init(teamAPI: TeamAPI,
         chatAPI: ChatAPI,
         userResolver: UserResolver) {
        self.teamAPI = teamAPI
        self.chatAPI = chatAPI
        self.userResolver = userResolver
    }

    func pullTeamEvent(teamID: Int64, limit: Int32, offset: Int64) -> Observable<ServerPB_Team_PullTeamEventsResponse> {
        return teamAPI.pullTeamEvent(teamID: teamID, limit: limit, offset: offset)
    }
}
