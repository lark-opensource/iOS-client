//
//  CurrentDialingState.swift
//  ByteView
//
//  Created by kiri on 2021/2/20.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewMeeting
import LarkMedia
import ByteViewRtcBridge

final class DialingState: MeetingComponent {
    init?(session: MeetingSession, event: MeetingEvent, fromState: MeetingState) {
        guard event.startCallParams != nil || event.enterpriseCallParams != nil else { return nil }
        entry(session: session)
    }

    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState) {
    }

    private func entry(session: MeetingSession) {
        let service = session.service
        service?.setting.updatePrestartContext(.meetingType(.call))
        MeetingRtcEngine.enableAUPrestart(true, for: session.sessionId)

        session.audioDevice?.lockState()

        if session.setting?.muteAudioConfig.enableDialMute == true {
            session.audioDevice?.input.setInputMuted(true)
        }

        let account = session.account
        TrackContext.shared.updateContext(for: session.sessionId) { context in
            context.host = account
            context.meetingType = .call
        }
        service?.router.startRoot(CallOutBody(session: session))
    }
}
