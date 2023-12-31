//
//  FeedTeamDataSourceConfig.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/21.
//

import Foundation

enum DataFrom {
    case unknown
    case getTeams
    case getChats
    case pushTeams
    case pushItemsUpdateTeam
    case pushItemsRemoveTeam
    case pushItemsRemoveFeed
    case pushInboxCard
    case pushTeamItemChats
    case pushExpired
    case pushStyle
    case selected
    case expand
    case reload
    case fetchMissedChatsForPushItem
    case fetchMissedChatsForExpandTeam
}

enum DataState {
    case idle
    case waiting
    case requesting
    case success
    case error
    case localHandle
    case ready
    case render
}

enum RenderType: Equatable {
    case fullReload
    case reloadSection(section: Int)

    static func == (lhs: RenderType, rhs: RenderType) -> Bool {
        switch (lhs, rhs) {
        case (.fullReload, .fullReload): return true
        case (.reloadSection(let l), .reloadSection(let r)): return l == r
        default: return false
        }
    }
}
