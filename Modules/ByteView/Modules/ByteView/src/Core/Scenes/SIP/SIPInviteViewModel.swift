//
//  SIPInviteViewModel.swift
//  ByteView
//
//  Created by chenyizhuo on 2021/10/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork

class SIPInviteViewModel {
    let meeting: InMeetMeeting

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
    }

    func inviteUser(type: ParticipantType, address: String) {
        let pstnInfo = PSTNInfo(participantType: type, mainAddress: address)
        meeting.participant.inviteUsers(pstnInfos: [pstnInfo])
        switch type {
        case .h323User:
            Logger.ui.info("Call out via H323")
        case.sipUser:
            Logger.ui.info("Call out via SIP")
        default:
            break
        }
    }
}
