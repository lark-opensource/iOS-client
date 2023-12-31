//
//  ParticipantDeclineUnMuteAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork

class ParticipantDeclineUnMuteAction: BaseParticipantAction {

    override var title: String { declineUnMuteTitle }

    override var show: Bool {
        !isSelf && !canCancelInvite && meeting.setting.hasCohostAuthority && (participant.isMicHandsUp || participant.isCameraHandsUp)
    }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        if participant.isMicHandsUp {
            HandsUpTracks.trackHandsDownByHost(user: participant.user, isSearch: source.isSearch)
            let request = VCManageApprovalRequest(meetingId: meeting.meetingId,
                                                  breakoutRoomId: meeting.setting.breakoutRoomId,
                                                  approvalType: .putUpHands,
                                                  approvalAction: .reject, users: [participant.user])
            meeting.httpClient.send(request)
        }
        if participant.isCameraHandsUp {
            let request = VCManageApprovalRequest(meetingId: meeting.meetingId,
                                                  breakoutRoomId: meeting.setting.breakoutRoomId,
                                                  approvalType: .putUpHandsInCam,
                                                  approvalAction: .reject, users: [participant.user])
            meeting.httpClient.send(request)
        }
        end(nil)
    }
}

extension ParticipantDeclineUnMuteAction {

    private var declineUnMuteTitle: String {
        if participant.isMicHandsUp, participant.isCameraHandsUp {
            return I18n.View_G_DeclineSpeakCamTab
        } else if participant.isCameraHandsUp {
            return I18n.View_G_DeclineCamTab
        } else {
            return I18n.View_G_DeclineSpeakTab
        }
    }
}
