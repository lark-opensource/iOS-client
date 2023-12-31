//
//  InMeetSettingHelper.swift
//  ByteView
//
//  Created by kiri on 2023/3/4.
//

import Foundation
import ByteViewSetting
import ByteViewNetwork

extension InMeetSettingContext {
    init(meeting: InMeetMeeting, context: InMeetViewContext, isFromToast: Bool = false) {
        self.init(sessionId: meeting.sessionId)

        self.supportsHideSelf = Display.phone && context.hideSelfEnabled
        self.isHideSelfOn = context.isSettingHideSelf

        self.supportsHideNonVideo = Display.phone && !context.hideNonVideoParticipantsEnableType.isHidden
        self.isHideNonVideoEnabled = context.hideNonVideoParticipantsEnableType.isEnabled
        self.isHideNonVideoOn = self.isHideNonVideoEnabled && context.isSettingHideNonVideoParticipants

        self.isE2EeMeeting = meeting.isE2EeMeeing
        self.isFromToast = isFromToast
        self.isHiddenReactionBubble = context.isHiddenReactionBubble
        self.isHiddenMessageBubble = context.isHiddenMessageBubble
    }
}

final class InMeetSettingHandlerImpl: InMeetSettingHandler {
    let meeting: InMeetMeeting
    let context: InMeetViewContext
    init(meeting: InMeetMeeting, context: InMeetViewContext) {
        self.meeting = meeting
        self.context = context
    }

    func didChangeInMeetSetting(_ changeType: InMeetSettingChangeType) {
        switch changeType {
        case .hideSelf(let isOn):
            self.context.isSettingHideSelf = isOn
            InMeetSceneTracks.trackClickHideSelf(isHideSelf: isOn, location: "mobile_setting", scene: self.context.meetingScene)
        case .hideNonVideo(let isOn):
            self.context.isSettingHideNonVideoParticipants = isOn
            MeetSettingTracks.trackHideNoVideoUser(isOn: isOn)
        case .hideReactionBubble(let isOn):
            self.context.isHiddenReactionBubble = isOn
        case .hideMessageBubble(let isOn):
            self.context.isHiddenMessageBubble = isOn
        }
    }
}
