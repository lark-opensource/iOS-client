//
//  ParticipantRemoveAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewUI
import ByteViewNetwork

class ParticipantRemoveAction: BaseParticipantAction {

    override var title: String { I18n.View_M_RemoveFromMeeting }

    override var color: UIColor { .ud.functionDangerContentDefault}

    override var show: Bool { removeEnabled }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        ParticipantTracks.trackParticipantAction(.removeParticipant, isFromGridView: source.isSearch, isSharing: meeting.shareData.isSharingContent)

        func kick(_ userName: String) {
            ParticipantTracks.trackKickOutParticipant(participant, isSearch: source.isSearch)
            let action: HostManageAction = participant.meetingRole == .webinarAttendee ? .webinarKickOutAttendee : .kickOutParticipant
            var request = HostManageRequest(action: action, meetingId: meeting.meetingId)
            request.participantId = participant.user
            meeting.httpClient.send(request) { [weak self] result in
                if result.isSuccess {
                    self?.provider?.toast(String(format: I18n.View_M_YouRemovedPercentAt, userName))
                }
            }
        }
        var userName = userInfo.display
        if participant.isLarkGuest {
            if meeting.info.meetingSource == .vcFromInterview {
                userName += I18n.View_G_CandidateBracket
            } else {
                userName += I18n.View_M_GuestParentheses
            }
        }
        let title = I18n.View_M_RemoveParticipant(userName)
        ByteViewDialog.Builder()
            .title(title)
            .message(nil)
            .leftTitle(I18n.View_G_CancelButton)
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ _ in
                kick(userName)
            })
            .needAutoDismiss(true)
            .show()
        end(nil)
    }
}

extension ParticipantRemoveAction {

    private var removeEnabled: Bool {
        if !isSelf && meeting.account != participant.user && !canCancelInvite && meeting.setting.hasCohostAuthority {
            if meeting.myself.meetingRole == .host {
                return true
            } else if meeting.myself.meetingRole == .coHost, (participant.meetingRole == .participant || participant.meetingRole == .webinarAttendee) {
                return true
            }
        }
        return false
    }
}
