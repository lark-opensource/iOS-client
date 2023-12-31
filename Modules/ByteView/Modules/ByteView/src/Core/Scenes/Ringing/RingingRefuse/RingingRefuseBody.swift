//
//  RingingRefuseBody.swift
//  ByteView
//
//  Created by kiri on 2023/6/20.
//

import Foundation

// 响铃拒绝
struct RingRefuseBody {
    let meetingId: String
    let isSingleMeeting: Bool
    let inviterUserId: String
    let inviterName: String

    init(meetingId: String, isSingleMeeting: Bool, inviterUserId: String, inviterName: String) {
        self.meetingId = meetingId
        self.isSingleMeeting = isSingleMeeting
        self.inviterUserId = inviterUserId
        self.inviterName = inviterName
    }
}

extension RingRefuseBody: CustomStringConvertible {
    var description: String {
        "RingRefuseBody(meetingId: \(meetingId), isSingleMeeting: \(isSingleMeeting), inviterUserId: \(inviterUserId))"
    }
}
