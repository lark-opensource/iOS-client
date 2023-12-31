//
//  ShareToRoomEntryParams.swift
//  ByteView
//
//  Created by lutingting on 2023/8/25.
//

import Foundation

struct ShareToRoomEntryParams {
    let source: MeetingEntrySource
    let fromVC: UIViewController?
}

extension ShareToRoomEntryParams: EntryParams {
    var id: String { "" }

    var entryType: EntryType { .shareToRoom }

    var isCall: Bool { false }

    var isJoinMeeting: Bool { true }
}
