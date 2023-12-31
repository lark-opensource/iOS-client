//
//  ParticipantStopLocalRecordAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork

class ParticipantStopLocalRecordAction: BaseParticipantAction {

    override var title: String { I18n.View_G_StopLocalRecordingTab }

    override var color: UIColor { .ud.functionDangerContentDefault}

    override var show: Bool {
        !isSelf && meeting.account != participant.user && !canCancelInvite && meeting.setting.hasCohostAuthority && meeting.setting.isLocalRecordEnabled && participant.settings.localRecordSettings?.isLocalRecording == true
    }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        let request = RecordMeetingRequest(meetingId: meeting.meetingId, action: .manageStopLocalRecord, requester: meeting.account, targetParticipant: participant.user)
        meeting.httpClient.send(request)
        ParticipantTracks.trackLocalRecordClick(isFromGridView: source.fromGrid, isStop: true)
        end(nil)
    }
}
