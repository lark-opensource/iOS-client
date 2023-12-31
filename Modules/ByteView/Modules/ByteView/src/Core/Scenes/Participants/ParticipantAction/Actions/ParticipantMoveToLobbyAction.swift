//
//  ParticipantMoveToLobbyAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork

class ParticipantMoveToLobbyAction: BaseParticipantAction {

    override var title: String { I18n.View_G_MoveIntoLobby }

    override var show: Bool { showMoveToLobby }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        var request = HostManageRequest(action: .moveParticipantToLobby, meetingId: meeting.meetingId)
        request.participantId = participant.user
        meeting.httpClient.send(request)
        end(nil)
    }
}

extension ParticipantMoveToLobbyAction {

    var showMoveToLobby: Bool {
        let can = meeting.setting.canMoveToLobby
        if !isSelf && !canCancelInvite && meeting.setting.hasCohostAuthority {
            if meeting.myself.meetingRole == .host {
                return can
            } else if meeting.myself.meetingRole == .coHost && (participant.meetingRole == .participant || participant.meetingRole == .webinarAttendee) {
                return can
            }
        }
        return false
    }
}
