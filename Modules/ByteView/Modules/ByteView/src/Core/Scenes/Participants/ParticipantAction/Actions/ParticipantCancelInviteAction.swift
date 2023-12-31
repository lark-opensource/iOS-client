//
//  ParticipantCancelInviteAction.swift
//  ByteView
//
//  Created by Tobb Huang on 2023/6/20.
//

import Foundation
import ByteViewNetwork

class ParticipantCancelInviteAction: BaseParticipantAction {

    override var title: String { I18n.View_G_CancelCall }

    override var color: UIColor { .ud.functionDangerContentDefault }

    override var show: Bool { true }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        ParticipantTracks.trackCancelCalling(participant: participant, isSearch: true)
        self.cancelInviteUser(participant: participant)
        ParticipantTracks.trackCoreManipulation(isSelf: false,
                                                description: I18n.View_G_CancelCall,
                                                participant: participant)
        end(nil)
    }
}

extension ParticipantCancelInviteAction {
    private func cancelInviteUser(participant: Participant) {
        meeting.httpClient.meeting.cancelInviteUser(participant.user,
                                                    meetingId: meeting.meetingId,
                                                    role: meeting.myself.meetingRole)
    }
}
