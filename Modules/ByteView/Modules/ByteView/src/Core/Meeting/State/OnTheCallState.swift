//
//  OnTheCallState.swift
//  ByteView
//
//  Created by kiri on 2021/2/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import ByteViewMeeting
import LarkMedia
import ByteViewRtcBridge

final class OnTheCallState: MeetingComponent {
    let info: VideoChatInfo
    let session: MeetingSession
    let meeting: InMeetMeeting
    var httpClient: HttpClient { meeting.httpClient }

    init?(session: MeetingSession, event: MeetingEvent, fromState: MeetingState) {
        guard let info = session.videoChatInfo, let myself = session.myself, let service = session.service else {
            session.loge("missing data, create InMeetMeeting failed")
            session.leave(.createMeetingFailed)
            return nil
        }

        service.setting.updatePrestartContext(.videoChatInfo(info))
        guard let createParams = RtcCreateParams(session: session, info: info) else {
            session.loge("missing rtc data, entering OnTheCall is skipped")
            session.leave(.rtcError(.missingData))
            return nil
        }
        guard let audioDevice = session.audioDevice else {
            session.loge("missing data, create InMeetMeeting failed")
            session.leave(.createMeetingFailed)
            return nil
        }

        audioDevice.lockState()

        self.info = info
        self.session = session
        self.meeting = InMeetMeeting(session: session, service: service, info: info, myself: myself, audioDevice: audioDevice,
                                     rtcParams: createParams)
        self.entry(from: fromState)
    }

    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState) {
        self.exit(event: event, to: toState)
    }

    private func entry(from: MeetingState?) {
        Toast.blockToastOnVCScene()
        session.push?.heartbeatStop.addObserver(self, handler: { [weak self] in
            self?.didReceiveHeartbeatStop($0)
        })
        TrackContext.shared.updateContext(for: session.sessionId) { $0.didOnTheCall = true }
        updateSlardarContextInfo()

        trackOnTheCall()
        if from == .lobby || from == .calling {
            session.slaTracker.startEnterOnthecall()
        }
        var hasTrackedForOnthecallPure = false
        if from == .ringing, session.isCallKit {
            hasTrackedForOnthecallPure = true
            OnthecallReciableTracker.startEnterOnthecallForPure()
        }
        session.callCoordinator.reportEnteringOnTheCall(meeting: meeting)
        if meeting.type == .meet {
            meeting.setting.lastOnTheCallMeetingId = info.id
        }
        DevTracker.timeout(event: .warning(.meeting_miss_fullparticipants).category(.meeting).params([.env_id: session.sessionId]), interval: .seconds(5), key: session.sessionId)
        httpClient.send(TrigPushFullMeetingInfoRequest())
        httpClient.send(TrigPushFullLobbysRequest())
        httpClient.send(StartHeartbeatRequest(meetingId: info.id, type: .vc))

        // 如果是callkit, 页面打开事件是很快的，此时统计pure时间需要放到reportAnsweringCallConnected前
        if !hasTrackedForOnthecallPure {
            OnthecallReciableTracker.startEnterOnthecallForPure()
        }

        let isPhoneCall = info.type == .call && info.settings.subType == .enterprisePhoneCall && Display.phone
        if isPhoneCall {
            Toast.unblockToastOnVCScene(showBlockedToast: true)
            if from == .ringing {
                session.service?.router.startRoot(InMeetOfPhoneCallBody(session: session, meeting: meeting))
            }
        } else {
            session.service?.router.startRoot(InMeetBody(meeting: meeting))
        }
        session.service?.live.stopLive()
    }

    private func handleExitByMoveToLobby() {
        // 标记会议终止
        MeetingTerminationCache.shared.terminate(info: meeting.info, account: meeting.account)
    }

    private func exit(event: MeetingEvent, to: MeetingState) {
        if meeting.type == .meet, event.shouldClearLastMeetingId() {
            meeting.setting.lastOnTheCallMeetingId = nil
        }
        meeting.release()
        DevTracker.cancelTimeout(.warning(.meeting_miss_fullparticipants), key: session.sessionId)
        httpClient.send(StopHeartbeatRequest(meetingId: info.id, type: .vc))
        Toast.unblockToastOnVCScene(showBlockedToast: false)
        if to == .lobby {
            self.handleExitByMoveToLobby()
        }
        removeSlardarContextInfo()
    }

    private func trackOnTheCall() {
        switch info.type {
        case .call:
            if session.myself?.meetingRole == .host, let acceptTime = info.actionTime?.accept, acceptTime > 0 {
                let duration = Int64(Date().timeIntervalSince1970 * 1000) - acceptTime
                VCTracker.post(name: .vc_call_oncallloading, params: ["client_duration": duration])
            }
        case .meet:
            VCTracker.post(name: .vc_meeting_root_check, params: [.action_name: "camera",
                                                                  .extend_value: ["action_enabled": Privacy.videoDenied ? 0 : 1]])
            VCTracker.post(name: .vc_meeting_root_check, params: [.action_name: "mic",
                                                                  .extend_value: ["action_enabled": Privacy.audioDenied ? 0 : 1]])
            VCTracker.post(name: .vc_meeting_client_join)
        default:
            break
        }

        // 本地投屏 (screenShare) 可以不用有 featureConfig
        if info.settings.subType != .screenShare && info.settings.featureConfig == nil {
            session.loge("missing feature config for meeting_id \(info.id)")
            BizErrorTracker.trackBizError(key: .missingFeatureConfig, "meeting_id \(info.id)")
        }
    }

    private func updateSlardarContextInfo() {
        meeting.service.heimdallr.setCustomContextValue(info.id, forKey: "meeting_id")
    }

    private func removeSlardarContextInfo() {
        meeting.service.heimdallr.removeCustomContextKey("meeting_id")
    }
}

extension OnTheCallState {
    func didReceiveHeartbeatStop(_ message: ByteviewHeartbeatStop) {
        if message.token == session.meetingId {
            session.log("didReceiveHeartbeatStop: \(message)")
            session.leave(.heartbeatStop(message.reason, offlineReason: message.offlineReason))
        }
    }
}

private extension MeetingEvent {
    func shouldClearLastMeetingId() -> Bool {
        switch self.name {
        case .failedToActiveVcScene:
            // 这种case一般来说app都被杀死了，重启后走重新入会逻辑
            return false
        default:
            return true
        }
    }
}
