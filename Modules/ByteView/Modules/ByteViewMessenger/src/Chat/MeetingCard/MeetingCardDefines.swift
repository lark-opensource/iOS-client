//
//  MeetingCardDefines.swift
//  LarkByteView
//
//  Created by 李凌峰 on 2020/3/6.
//

import Foundation
import ByteViewCommon

enum MeetingCardConstant {
    static let countOfParticipantsInCell = 6
    static let countOfParticipantsInDetail = 15
}

typealias Logger = ByteViewCommon.Logger
extension Logger {
    static let meetingCard = getLogger("MeetingCard")
    static let feedOngoing = getLogger("FeedOngoing")
}
