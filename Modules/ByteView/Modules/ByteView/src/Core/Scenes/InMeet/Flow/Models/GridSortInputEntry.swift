//
//  GridSortInputEntry.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/3/14.
//

import Foundation
import ByteViewNetwork

struct GridSortParticipant {
    let participant: Participant
    let strategy: GridSortEntryStrategy
}

enum CandidateAction {
    case unmuteCamera
    case muteCamera
    case enter
    case none

    var isEnterFirstPageCandidate: Bool {
        [.enter, .unmuteCamera].contains(self)
    }

    var isExitFirstPageCandidate: Bool {
        [.muteCamera].contains(self)
    }
}

enum GridTileType {
    case person // 1:1正方形
    case room // 16:9矩形
}

extension Participant {
    var gridType: GridTileType {
        switch self.type {
        case .room, .sipUser, .h323User:
            return .room
        default:
            return .person
        }
    }
}

class GridSortInputEntry: Equatable {
    let participant: Participant
    let role: Role
    let rank: Int
    let action: CandidateAction

    init(participant: Participant, role: Role, rank: Int, action: CandidateAction) {
        self.participant = participant
        self.role = role
        self.rank = rank
        self.action = action
    }

    convenience init(participant: Participant,
                     myself: ByteviewUser,
                     asID: ByteviewUser?,
                     focusedID: ByteviewUser?,
                     rank: Int,
                     action: CandidateAction) {
        var role: Role = []
        if asID == participant.user {
            role.insert(.activeSpeaker)
        }
        if focusedID == participant.user {
            role.insert(.focus)
        }
        if myself == participant.user {
            role.insert(.me)
        }
        self.init(participant: participant, role: role, rank: rank, action: action)
    }

    var pid: ByteviewUser { participant.user }
    var shouldStayInFirstPage: Bool { !role.isDisjoint(with: [.me, .activeSpeaker, .focus]) }

    static func < (lhs: GridSortInputEntry, rhs: GridSortInputEntry) -> Bool {
        lhs.rank < rhs.rank
    }

    static func == (lhs: GridSortInputEntry, rhs: GridSortInputEntry) -> Bool {
        lhs.participant.user == rhs.participant.user
    }

    struct Role: OptionSet {
        let rawValue: Int

        static let me = Role(rawValue: 1 << 0)
        static let activeSpeaker = Role(rawValue: 1 << 1)
        static let focus = Role(rawValue: 1 << 2)
    }
}
