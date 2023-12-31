//
//  ParticipantHideNoVideoAction.swift
//  ByteView
//
//  Created by wulv on 2023/6/12.
//

import Foundation

class ParticipantHideNoVideoAction: BaseParticipantAction {

    override var title: String {
        inMeetContext.isSettingHideNonVideoParticipants ? I18n.View_G_ShowMuteNonVideo_Button : I18n.View_G_HideMuteNonVideo_Button
    }

    override var show: Bool {
        !meeting.isWebinarAttendee && source.fromGrid && meeting.participant.currentRoom.nonRingingCount > 1 && (inMeetContext.isSettingHideNonVideoParticipants || participant.settings.isCameraMutedOrUnavailable)
    }

    override func action(_ end: @escaping (Dictionary<String, Any>?) -> Void) {
        switch inMeetContext.hideNonVideoParticipantsEnableType {
        case .enable:
            inMeetContext.isSettingHideNonVideoParticipants = !inMeetContext.isSettingHideNonVideoParticipants
            if let mode = inMeetContext.sceneManager?.sceneMode {
                InMeetSceneTracks.trackClickHideNoVideoUser(isHide: inMeetContext.isSettingHideNonVideoParticipants, scene: mode)
            }
        case .disable(let reason):
            // 展示开关但是不可点击，点击弹Toast提示
            if let reason = reason {
                provider?.toast(reason)
            }
        case .none: break
        }
        end(nil)
    }
}
