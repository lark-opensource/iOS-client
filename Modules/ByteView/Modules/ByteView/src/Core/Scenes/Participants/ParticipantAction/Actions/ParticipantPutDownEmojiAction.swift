//
//  ParticipantPutDownEmojiAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation
import ByteViewNetwork

class ParticipantPutDownEmojiAction: BaseParticipantAction {

    override var title: String { I18n.View_G_HandDown_Button }

    override var show: Bool { showPutDownEmoji }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        if isSelf {
            var request = ParticipantChangeSettingsRequest(meeting: meeting)
            let key = meeting.myself.settings.conditionEmojiInfo?.handsUpEmojiKey ?? ""
            request.participantSettings.conditionEmojiInfo = ParticipantSettings.ConditionEmojiInfo(isHandsUp: false, handsUpEmojiKey: key)
            meeting.httpClient.send(request)
        } else {
            let action: HostManageAction = participant.meetingRole == .webinarAttendee ? .webinarPutDownAttendeeHands : .setConditionEmojiHandsDown
            var request = HostManageRequest(action: action, meetingId: meeting.meetingId)
            request.participantId = participant.user
            meeting.httpClient.send(request)
            let list = meeting.subType == .webinar ? (meeting.isWebinarAttendee ? "attendee_list" : "panelist_list") : "userlist"
            let location = source.isSearch ? "search_result" : (source.fromGrid ? "user_icon" : list)
            provider?.track(.vc_meeting_onthecall_click, params: [.click: "single_hand_down", "location": location])
        }
        end(nil)
    }
}

extension ParticipantPutDownEmojiAction {

    private var showPutDownEmoji: Bool {
        let handsUp = participant.settings.conditionEmojiInfo?.isHandsUp ?? false
        if isSelf {
            return handsUp
        }
        return !canCancelInvite && meeting.setting.hasCohostAuthority && handsUp
    }
}
