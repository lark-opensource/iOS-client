//
//  ParticipantChangeRoleAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork

class ParticipantChangeRoleAction: BaseParticipantAction {

    override var title: String { participant.meetingRole == .webinarAttendee ? I18n.View_G_PromoteToPanelist : I18n.View_G_ChangeRoleToAttendee}

    override var show: Bool { !isSelf && meeting.setting.hasCohostAuthority && meeting.subType == .webinar && ![.host, .coHost].contains(participant.meetingRole)}

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        if participant.meetingRole == .webinarAttendee {
            Toast.show(I18n.View_G_PanelistInvitationSent)
            InMeetWebinarTracks.setPanelist(userID: participant.user.id, location: source.track)
            var request = HostManageRequest(action: .webinarSetFromAttendeeToParticipant, meetingId: meeting.meetingId)
            request.participantId = participant.user
                meeting.httpClient.send(request) { r in
                guard case let .failure(e) = r else {
                    return
                }
                InMeetWebinarTracks.PopupView.roleChangeFail(action: "attendee_to_panelist",
                                                             errorCode: e.toVCError().code)
            }
        } else {
            InMeetWebinarTracks.setAttendee(userID: participant.user.id, location: source.track)
            var request = HostManageRequest(action: .webinarSetFromParticipantToAttendee, meetingId: meeting.meetingId)
            request.participantId = participant.user
                meeting.httpClient.send(request) { r in
                guard case let .failure(e) = r else {
                    return
                }
                InMeetWebinarTracks.PopupView.roleChangeFail(action: "panelist_to_attendee",
                                                             errorCode: e.toVCError().code)
            }
        }
        end(nil)
    }
}
