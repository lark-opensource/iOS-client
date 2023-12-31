//
//  ParticipantAllowLocalRecordAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork

class ParticipantAllowLocalRecordAction: BaseParticipantAction {

    override var title: String { I18n.View_G_AllowLocalRecordingTab }

    override var show: Bool { showManageLocalRecord }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        let request = RecordMeetingRequest(meetingId: meeting.meetingId, action: .manageApproveLocalRecord, requester: meeting.account, targetParticipant: participant.user)
        meeting.httpClient.send(request)
        ParticipantTracks.trackLocalRecordClick(isFromGridView: source.fromGrid, isAgree: true)
        end(nil)
    }
}
