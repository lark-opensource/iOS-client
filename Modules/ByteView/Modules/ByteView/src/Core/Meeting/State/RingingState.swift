//
//  RingingState.swift
//  ByteView
//
//  Created by kiri on 2021/2/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import QuartzCore
import ByteViewMeeting
import ByteViewTracker
import AVFoundation
import LarkMedia
import ByteViewRtcBridge

final class RingingState: MeetingComponent {
    let isCallKit: Bool
    let info: VideoChatInfo
    let service: MeetingBasicService
    var httpClient: HttpClient { service.httpClient }
    private var ringingTimer: Timer?

    init?(session: MeetingSession, event: MeetingEvent, fromState: MeetingState) {
        guard let info = event.videoChatInfo, let service = session.service else { return nil }
        self.info = info
        self.isCallKit = session.isCallKit
        self.service = service
        session.setAttr(CACurrentMediaTime(), for: .meetingRingingTime)
        entry(session: session)
    }

    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState) {
        exit(session: session)
    }

    @RwAtomic
    private var isTimeoutTracked = false
    private func entry(session: MeetingSession) {
        session.setting?.updatePrestartContext(.videoChatInfo(info))
        httpClient.send(StartPollingRequest(meetingId: info.id, type: .ringing))
        httpClient.meeting.updateVideoChat(meetingId: session.meetingId, action: .receivedInvitation, interactiveId: session.myself?.interactiveId, role: session.myself?.meetingRole)
        trackRinging(session: session)
        session.log("startRingingTimer")

        Util.runInMainThread { [weak self, weak session] in
            // nolint-next-line: magic number
            self?.ringingTimer = Timer.scheduledTimer(withTimeInterval: 70, repeats: false, block: { [weak self] (_) in
                guard let self = self, let session = session else { return }
                if !self.isTimeoutTracked {
                    self.isTimeoutTracked = true
                    self.trackRingingTimeout(session: session)
                }
                session.leave(.ringingTimeOut)
            })
        }
        Logger.ring.info("into ringing: \(session.meetingId) \(session.isPending)")

        if !session.isPending {
            currentEntry(session: session)
        }
    }

    private func exit(session: MeetingSession) {
        Logger.ring.info("into ringing exit: \(session.meetingId) \(session.isPending)")
        if !session.isPending { // 非忙线的响铃清除，忙线的还是在BusyRingingManager里面处理
            currentExit(session: session)
        }
        httpClient.send(StopPollingRequest(meetingId: info.id, type: .ringing))
        session.log("stopRingingTimer")
        if !isTimeoutTracked, session.myself?.offlineReason == .ringTimeout {
            self.isTimeoutTracked = true
            self.trackRingingTimeout(session: session)
        }
        ringingTimer?.invalidate()
        ringingTimer = nil
    }

    private func currentEntry(session: MeetingSession) {
        session.audioDevice?.lockState()
        if session.isCallKit {
            session.service?.router.dismissWindow()
        } else {
            if let params = RtcCreateParams(session: session, info: info) {
                session.service?.prestartRtc(params)
            } else {
                session.loge("missingData, prestart rtc ignored")
            }

            // 如果找到相同的meetingid的忙线响铃，先remove它（忙线转非忙线，可能存在先出现非忙线，然后再忙线消失）
            if RingingCardManager.shared.findSession(meetingId: session.meetingId, isBusy: true) != nil {
                Logger.ring.info("has same meetingNO busyringingcard, remove it")
                RingingCardManager.shared.remove(meetingId: session.meetingId)
            }

            switch info.type {
            case .call:
                    self.trackRingingCard(session: session)
                    RingingCardManager.shared.post(meetingId: session.meetingId, type: .callInRing)
            case .meet:
                self.trackRingingCard(session: session)
                RingingCardManager.shared.post(meetingId: session.meetingId, type: .inviteInRing)
            default:
                assertionFailure()
            }
            MeetingLocalNotificationCenter.shared.showLocalNotification(info, service: service)
        }
    }

    private func currentExit(session: MeetingSession) {
        RingingCardManager.shared.remove(meetingId: session.meetingId)
        RingPlayer.shared.stop()
        session.audioDevice?.unlockState()
    }

    func leavePending(session: MeetingSession) {
        if !session.isCallKit, !session.isAcceptRinging {
            /// 忙线状态下，用户点击过accept之后，无需currentEntry（会很快离开ringing状态）
            currentEntry(session: session)
        }
    }

    private func trackRinging(session: MeetingSession) {
        let isOffline = session.isCallKitFromVoIP ? 1 : 0
        VCTracker.post(name: .vc_monitor_callee_ring, params: [.env_id: session.sessionId])
        var params: TrackParams = [.env_id: session.sessionId]
        params[.from_source] = session.isFromPush ? "ws" : "pull"
        params[.action_name] = "ringing"
        if let sid = info.sid {
            params["sid"] = sid
            if sid.isEmpty {
                // add log info for invalid conference_id or sid
                Logger.meeting.info("invalid ringing params: sid is nil")
            }
        }

        switch info.type {
        case .call:
            VCTracker.post(name: .vc_call_page_ringing, params: params, platforms: [.plane])
            if let inviteTime = info.actionTime?.invite, inviteTime > 0 {
                let duration = Int64(Date().timeIntervalSince1970 * 1000) - inviteTime
                var params4Duration = params
                params4Duration.removeValue(forKey: .action_name)
                params4Duration.removeValue(forKey: .from_source)
                params4Duration["client_duration"] = duration
                params4Duration["is_offline"] = isOffline
                VCTracker.post(name: .vc_call_receiveduration, params: params4Duration)
            }
        case .meet:
            VCTracker.post(name: .vc_meeting_page_ringing, params: params, platforms: [.plane])
        default:
            break
        }
    }

    private func trackRingingTimeout(session: MeetingSession) {
        if !session.isPending {
            VCTracker.post(name: .vcex_ringing_client_timeout, params: [.env_id: session.sessionId, "sid": session.videoChatInfo?.sid],
                           platforms: [.tea, .slardar])
        }
        let params: TrackParams = [
            .env_id: session.sessionId,
            "click": "out_of_time",
            "is_in_duration": session.isPending,
            "call_type": session.meetType.description,
            "is_voip": session.isCallKitFromVoIP ? 1 : 0,
            "is_ios_new_feat": 0,
            "is_callkit": isCallKit ? 1 : 0
        ]
        VCTracker.post(name: .vc_meeting_callee_click, params: params)
    }

    private func trackRingingCard(session: MeetingSession) {
        VCTracker.post(name: .vc_meeting_callee_status, params: ["ring_match_id": session.sessionId, "is_callkit": false])
    }
}

extension MeetingSession {
    var meetingRingingTime: CFTimeInterval? { attr(.meetingRingingTime) }
}

private extension MeetingAttributeKey {
    static let meetingRingingTime: MeetingAttributeKey = "vc.meetingRingingTime"
}
