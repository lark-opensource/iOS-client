//
//  MeetingSettingManager+Update.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/26.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker

public extension MeetingSettingManager {
    func updateSettings(_ action: (inout UpdateMeetingSettingRequest) -> Void, completion: ((Result<Void, Error>) -> Void)? = nil) {
        var request = UpdateMeetingSettingRequest()
        action(&request)
        let group = DispatchGroup()
        var responseError: Error?
        updateExtraData {
            if let isOn = request.isFrontCameraEnabled {
                $0.isFrontCameraEnabled = isOn
            }
            if let isOn = request.isSystemPhoneCalling {
                $0.isSystemPhoneCalling = isOn
            }
            if let isOn = request.isInMeetCameraMuted {
                $0.isInMeetCameraMuted = isOn
            }
            if let isOn = request.isInMeetMicrophoneMuted {
                $0.isInMeetMicrophoneMuted = isOn
            }
            if let isOn = request.isInMeetCameraEffectOn {
                $0.isInMeetCameraEffectOn = isOn
            }
            if let isOn = request.isExternalMeeting {
                $0.isExternalMeeting = isOn
            }
            if let dataMode = request.dataMode {
                $0.dataMode = dataMode
            }
        }
        if request.isAutoTranslationOn != nil || request.targetTranslateLanguage != nil || request.translateRule != nil {
            service.updateTranslateLanguage(isAutoTranslationOn: request.isAutoTranslationOn, targetLanguage: request.targetTranslateLanguage, rule: request.translateRule)
        }
        if let isOn = request.isMicSpeakerDisabled {
            service.isMicSpeakerDisabled = isOn
        }
        if request.handsUpEmojiKey != nil || request.isVideoMirrored != nil || request.labEffect != nil {
            group.enter()
            service.updateViewUserSetting({
                $0.handsUpEmojiKey = request.handsUpEmojiKey
                $0.isMirror = request.isVideoMirrored
                $0.advancedBeauty = request.labEffect
            }, completion: { result in
                if case .failure(let error) = result { responseError = error }
                group.leave()
            })
        }

        group.notify(queue: .global()) {
            if let error = responseError {
                completion?(.failure(error))
            } else {
                completion?(.success(Void()))
            }
        }
    }

    func refreshSubtitleLanguage() {
        service.refreshSubtitleLanguage(force: true)
    }

    func updateLockMeeting(_ isLocked: Bool, completion: ((Result<Void, Error>) -> Void)? = nil) {
        let to = isLocked ? .onlyHost : self.videoChatSettings.lastSecuritySetting?.securityLevel ?? .public
        self.updateSecurityLevel(to, completion: completion)
    }

    func updateLabSettings(enableBlur: Bool?, virtualKey: String?, advancedBeauty: String?,
                           completion: ((Result<PatchViewUserSettingResponse, Error>) -> Void)? = nil) {
        service.updateViewUserSetting({
            $0.backgroundBlur = enableBlur
            $0.virtualBackground = virtualKey
            $0.advancedBeauty = advancedBeauty
        }, completion: completion)
    }

    func updateParticipantSettings(_ update: (inout ParticipantChangeSettingsRequest) -> Void, completion: ((Result<Void, Error>) -> Void)? = nil) {
        var request = ParticipantChangeSettingsRequest(meetingId: meetingId, breakoutRoomId: breakoutRoomId, role: meetingRole)
        update(&request)
        service.httpClient.send(request, completion: completion)
    }

    func syncRoomManage(roomId: String, mute: Bool, completion: ((Result<Void, Error>) -> Void)? = nil) {
        let request = SyncRoomManageRequest(meetingId: meetingId, bindRoomId: roomId, action: mute ? .micMute : .micUnmute)
        service.httpClient.send(request, completion: completion)
    }

    func updateHostManage(_ action: HostManageAction, update: (inout HostManageRequest) -> Void, completion: ((Result<Void, Error>) -> Void)? = nil) {
        var request = HostManageRequest(action: action, meetingId: meetingId, breakoutRoomId: breakoutRoomId)
        update(&request)
        service.httpClient.send(request, completion: completion)
    }
}
