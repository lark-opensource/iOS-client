//
//  MeetInViewModel.swift
//  ByteView
//
//  Created by wangpeiran on 2022/10/2.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewCommon
import ByteViewNetwork
import ByteViewMeeting
import ByteViewTracker
import AVFoundation
import ByteViewUI
import ByteViewSetting

class MeetInViewModel: CallInViewModel {
    var meetingTagType: MeetingTagType {
        guard let info = meeting.videoChatInfo else { return .none }
        guard meeting.service?.accountInfo.tenantTag == .standard else { // 小B用户不显示外部标签
            return .none
        }
        if let tagText = info.relationTagWhenRing?.meetingTagText {
            return .partner(tagText)
        }

        return info.isExternalMeetingWhenRing ? .external : .none
    }

    private weak var weakPolicyAlert: ByteViewDialog?

    deinit {
        weakPolicyAlert?.dismiss()
    }

    func accept(isCameraOn: Bool?, isMicOn: Bool?) {
        OnthecallReciableTracker.startEnterOnthecall()
        meeting.slaTracker.startEnterOnthecall()
        JoinTracks.trackMeetingEntry(sessionId: meeting.sessionId, source: "calling_page")
        trackPressAction(click: "accept", target: TrackEventName.vc_meeting_onthecall_view)
        let context = MeetingPrecheckContext(service: service)
        precheckBuilder = PrecheckBuilder()
        precheckBuilder?.checkMediaResourceOccupancy(isJoinMeeting: true)
            .checkMediaResourcePermission(isNeedAlert: false, isNeedCamera: true)
        precheckBuilder?.execute(context) { [weak self] result in
            guard case .success = result else { return }
            Util.runInMainThread {
                guard let self = self else { return }
                self.onAccept()
                var setting: MicCameraSetting = .none
                if Privacy.videoAuthorized, let isCameraOn = isCameraOn, isCameraOn {
                    setting.isCameraEnabled = true
                }
                if Privacy.audioAuthorized, let isMicOn = isMicOn, isMicOn {
                    setting.isMicrophoneEnabled = true
                }
                self.mayAccept(setting: setting)
            }
        }
    }

    func mayAccept(setting: MicCameraSetting) {
        guard let info = meeting.videoChatInfo, let service = meeting.service else { return }
        if !service.setting.isLiveLegalEnabled {
            notifyUserAccepted(setting)
            return
        }

        let placeholderId = meeting.sessionId
        let policy = service.setting.policyURL
        service.httpClient.meeting.livePreCheck(meetingId: info.id) { [weak self] showsPolicy in
            guard let self = self else { return }
            if !showsPolicy {
                self.notifyUserAccepted(setting)
                return
            }
            Policy.showJoinLivestreamedMeetingAlert(placeholderId: placeholderId, policyUrl: policy, handler: { [weak self] granted in
                guard let self = self else { return }
                if granted {
                    self.notifyUserAccepted(setting)
                } else {
                    self.notifyUserDeclined()
                }
            }, completion: { [weak self] alert in
                self?.weakPolicyAlert = alert
            })
        }
    }
}
