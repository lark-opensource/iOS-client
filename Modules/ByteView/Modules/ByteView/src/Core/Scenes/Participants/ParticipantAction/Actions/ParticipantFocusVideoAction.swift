//
//  ParticipantFocusVideoAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewUI
import ByteViewNetwork

class ParticipantFocusVideoAction: BaseParticipantAction {

    override var title: String {
        meeting.data.inMeetingInfo?.focusVideoData?.focusUser == participant.user ? I18n.View_G_UnfocusVideoForAll_Long : I18n.View_G_SetAsFocusVideoBttn
    }

    override var show: Bool {
        participant.meetingRole != .webinarAttendee && meeting.myself.role != .interviewee && meeting.type != .call && meeting.myself.meetingRole == .host && !meeting.data.isOpenBreakoutRoom
    }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        let participant = meeting.data.inMeetingInfo?.focusVideoData?.focusUser == participant.user ? nil : participant
        let withdrawFocus = participant == nil
        let cancelText = I18n.View_G_CancelButton
        let confirmText = I18n.View_MV_ConfirmButtonTwo
        let title = withdrawFocus ? I18n.View_G_UnfocusVideoForPop : I18n.View_G_SetTheFocus
        let desp: String?
        if withdrawFocus {
            desp = nil
        } else if meeting.webinarManager?.stageInfo != nil {
            desp = I18n.View_G_FocusNoSyncStagePop
        } else {
            desp = I18n.View_G_FocusSetResultExplain(userInfo.display)
        }
        let location = source.track
        ByteViewDialog.Builder()
            .id(.focusVideo)
            .title(title)
            .message(desp)
            .leftTitle(cancelText)
            .rightTitle(confirmText)
            .rightHandler({ [weak meeting] _ in
                guard let meeting = meeting else { return }
                ParticipantTracks.trackFocusVideo(withdraw: withdrawFocus, location: location)
                var request = HostManageRequest(action: .setSpotLight, meetingId: meeting.meetingId)
                if let participant = participant {
                    request.focusVideoData = HostManageRequest.FocusVideoData(focusUser: participant.user)
                }
                meeting.httpClient.send(request) { result in
                    Logger.participant.info("update focus video: \(!withdrawFocus), user:\(participant?.user) err: \(result.error)")
                }
            })
            .show()
        end(nil)
    }
}
