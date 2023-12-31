//
//  ParticipantPhoneCallAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation

class ParticipantPhoneCallAction: BaseParticipantAction {

    override var title: String { (isSelf && meeting.setting.isCallMeEnabled) ? I18n.View_MV_SelectPhoneAudio : I18n.View_G_InviteUsersJoinByPhone }

    override var show: Bool { showPhoneCall }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        if isSelf, meeting.setting.isCallMeEnabled {
            meeting.audioModeManager.beginPstnCalling()
        } else {
            meeting.participant.invitePSTN(userId: participant.user.id, name: userInfo.original)
        }
        ParticipantTracks.trackInvitePSTN(isFromGridView: source.fromGrid, suggestionCount: meeting.participant.suggested?.suggestedParticipants.count)
        end(nil)
    }
}

extension ParticipantPhoneCallAction {

    private var showPhoneCall: Bool {
        participant.settings.audioMode != .pstn && participant.callMeInfo.status != .ringing && !meeting.isWebinarAttendee && !meeting.isE2EeMeeing &&  ConveniencePSTN.enableInviteParticipant(participant, local: meeting.myself, featureManager: meeting.setting, meetingTenantId: meeting.info.tenantId, meetingSubType: meeting.subType)
    }
}
