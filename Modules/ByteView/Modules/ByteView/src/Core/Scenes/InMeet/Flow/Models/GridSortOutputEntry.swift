//
//  GridSortOutputEntry.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/3/14.
//

import Foundation
import ByteViewNetwork

enum GridSortEntryType: Equatable, CustomStringConvertible {
    case share
    case participant(Participant)
    case activeSpeaker

    var description: String {
        switch self {
        case .share: return "share"
        case .activeSpeaker: return "activeSpeaker"
        case .participant(let value): return "participant(\(value.user))"
        }
    }

    static func == (lhs: GridSortEntryType, rhs: GridSortEntryType) -> Bool {
        switch (lhs, rhs) {
        case (.share, .share): return true
        case (.activeSpeaker, .activeSpeaker): return true
        case (.participant(let left), .participant(let right)): return left.user == right.user
        default: return false
        }
    }
}
enum GridSortEntryStrategy: Equatable, CustomStringConvertible {
    case normal
    // 临时显示，显示截止到给定时间，传入参数为绝对时间
    case temporary(TimeInterval)

    var description: String {
        switch self {
        case .normal: return "normal"
        case .temporary(let dueTime): return "temporary until \(dueTime)"
        }
    }
}

struct GridSortOutputEntry: Equatable, CustomStringConvertible {
    static let activeSpeaker = GridSortOutputEntry(type: .activeSpeaker, strategy: .normal)
    static let share = GridSortOutputEntry(type: .share, strategy: .normal)

    let type: GridSortEntryType
    let strategy: GridSortEntryStrategy

    init(type: GridSortEntryType, strategy: GridSortEntryStrategy) {
        self.type = type
        self.strategy = strategy
    }

    var description: String {
        "type = \(type), strategy: \(strategy)"
    }
}
