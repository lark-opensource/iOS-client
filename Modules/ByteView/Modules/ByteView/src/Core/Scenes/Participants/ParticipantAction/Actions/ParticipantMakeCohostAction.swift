//
//  ParticipantMakeCohostAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork

class ParticipantMakeCohostAction: BaseParticipantAction {

    override var title: String { participant.meetingRole == .coHost ? I18n.View_M_WithdrawCoHostPermission : I18n.View_M_MakeCoHost }

    override var show: Bool {
        !isSelf && !canCancelInvite && meeting.setting.hasCohostAuthority && meeting.myself.meetingRole == .host
        && participant.canBecomeHost(hostEnabled: meeting.setting.isHostEnabled, isInterview: meeting.isInterviewMeeting)
        && participant.capabilities.canBeCoHost
    }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        ParticipantTracks.trackParticipantAction(participant.meetingRole == .coHost ? .cancelCoHost : .setCoHost,
                                                 isFromGridView: source.fromGrid,
                                                 isSharing: meeting.shareData.isSharingContent,
                                                 isRooms: participant.type == .room)

        CohostTracks.trackAssignCohost(user: participant.user, isSearch: source.isSearch)
        var request = HostManageRequest(action: .setCoHost, meetingId: meeting.meetingId)
        request.participantId = participant.user
        request.coHostAction = participant.meetingRole == .coHost ? .unset : .set
        meeting.httpClient.send(request)
        end(nil)
    }
}
