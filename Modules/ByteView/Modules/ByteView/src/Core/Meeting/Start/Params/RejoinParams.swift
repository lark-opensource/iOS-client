//
//  RejoinParams.swift
//  ByteView
//
//  Created by kiri on 2022/8/5.
//

import Foundation
import ByteViewNetwork

struct RejoinParams {
    let info: VideoChatInfo
    let type: RejoinType
}

enum RejoinType: String {
    case streamingLost
    case registerClientInfo
}


extension RejoinParams: EntryParams {
    var id: String { info.id }

    var source: MeetingEntrySource { .init(rawValue: type.rawValue) }

    var entryType: EntryType { .rejoin }

    var isCall: Bool { info.type == .call }

    var isJoinMeeting: Bool { true }
}
