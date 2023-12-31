//
//  CallingState.swift
//  ByteView
//
//  Created by kiri on 2021/2/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting
import QuartzCore
import ByteViewTracker
import LarkMedia
import ByteViewRtcBridge

final class CallingState: MeetingComponent {
    private let session: MeetingSession
    private let info: VideoChatInfo
    private var isRtcInitializedAudioSession = false
    init?(session: MeetingSession, event: MeetingEvent, fromState: MeetingState) {
        guard let info = event.videoChatInfo else { return nil }
        self.session = session
        self.info = info
        entry()
    }

    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState) {
        exit()
    }

    private func entry() {
        session.setting?.updatePrestartContext(.videoChatInfo(info))
        let sessionId = session.sessionId
        trackCalling(sessionId: sessionId)
        if let params = RtcCreateParams(session: session, info: info) {
            session.service?.prestartRtc(params)
        } else {
            session.loge("missingData, prestart rtc ignored")
        }
        session.httpClient.send(StartPollingRequest(meetingId: info.id, type: .calling))

        // 为实现与E2EE双呼场景,calling时需要生成监听meetingKeyExchange
        session.push?.meetingKeyExchange.addObserver(self) { [weak self] in
            self?.didReceiveMeetingKeyExchange($0)
        }
    }

    func didReceiveMeetingKeyExchange(_ exchangePush: PushE2EEKeyExchange) {
        var inMeetingKey: InMeetingKey
        if let key = session.inMeetingKey {
            inMeetingKey = key
        } else {
            inMeetingKey = InMeetingKey.createMeetingKeyBy(account: session.account)
            session.inMeetingKey = inMeetingKey
        }
        let request = SendE2EEKeyExchangeRequest(exchangePush: exchangePush, key: inMeetingKey.e2EeKey)
        session.httpClient.send(request)
    }

    private func exit() {
        session.httpClient.send(StopPollingRequest(meetingId: info.id, type: .calling))
    }

    private func trackCalling(sessionId: String) {
        VCTracker.post(name: .vc_monitor_caller_receive_meeting_id, params: [.env_id: sessionId])
        VCTracker.post(name: .vc_call_client_create, params: [.env_id: sessionId])
    }
}
