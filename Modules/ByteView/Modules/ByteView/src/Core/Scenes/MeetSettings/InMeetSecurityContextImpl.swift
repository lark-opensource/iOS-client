//
//  InMeetSecurityContextImpl.swift
//  ByteView
//
//  Created by kiri on 2023/5/9.
//

import Foundation
import ByteViewCommon
import ByteViewSetting

final class InMeetSecurityContextImpl: InMeetSecurityContext, InMeetParticipantListener {
    private let listeners = Listeners<InMeetSecurityListener>()
    private let meeting: InMeetMeeting
    let participantNum: Int
    let fromSource: InMeetSecurityFromSource

    init(meeting: InMeetMeeting, fromSource: InMeetSecurityFromSource) {
        self.fromSource = fromSource
        self.meeting = meeting
        self.participantNum = meeting.participant.global.count
        meeting.participant.addListener(self, fireImmediately: false)
    }

    var isMySharingScreen: Bool { meeting.shareData.isMySharingScreen }

    func addListener(_ listener: InMeetSecurityListener) {
        listeners.addListener(listener)
    }

    func didChangeGlobalParticipants(_ output: InMeetParticipantOutput) {
        let num = output.sumCount
        listeners.forEach { $0.didChangeParticipantNum(num) }
    }
}
