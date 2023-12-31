//
//  TeamEventDependency.swift
//  LarkTeam
//
//  Created by chaishenghua on 2022/8/30.
//

import Foundation
import LarkContainer
import ServerPB
import RxSwift
import LarkSDKInterface

protocol TeamEventDependency {
    var chatAPI: ChatAPI { get }
    var userResolver: LarkContainer.UserResolver { get }
    func pullTeamEvent(teamID: Int64, limit: Int32, offset: Int64) -> Observable<ServerPB.ServerPB_Team_PullTeamEventsResponse>
}
