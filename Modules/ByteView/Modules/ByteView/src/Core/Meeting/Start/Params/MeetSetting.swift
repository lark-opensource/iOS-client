//
//  MeetSetting.swift
//  ByteView
//
//  Created by 李凌峰 on 2019/4/15.
//

import Foundation
import AVFoundation
import LarkMedia
import ByteViewSetting
import ByteViewNetwork

extension MicCameraSetting {
    static let `default` = MicCameraSetting(isMicrophoneEnabled: true, isCameraEnabled: true)
    static let onlyAudio = MicCameraSetting(isMicrophoneEnabled: true, isCameraEnabled: false)
    static let none = MicCameraSetting(isMicrophoneEnabled: false, isCameraEnabled: false)
}

extension ParticipantSettings {
    func toMeetSetting() -> MicCameraSetting {
        MicCameraSetting(isMicrophoneEnabled: !isMicrophoneMuted, isCameraEnabled: !isCameraMuted)
    }
}

extension MicCameraSetting {
    func toParticipantSettings() -> ParticipantSettings {
        var participantSettings = ParticipantSettings()
        participantSettings.cameraStatus = Privacy.videoAuthorized ? .normal : .noPermission
        participantSettings.microphoneStatus = Privacy.audioAuthorized ? .normal : .noPermission
        participantSettings.isCameraMuted = !self.isCameraEnabled
        participantSettings.isMicrophoneMuted = !self.isMicrophoneEnabled
        return participantSettings
    }
}

extension MicCameraSetting {
    var trackName: String {
        if isCameraEnabled && isMicrophoneEnabled {
            return "all_open"
        } else if isMicrophoneEnabled {
            return "only_voice"
        } else if isCameraEnabled {
            return "only_video"
        } else {
            return "all_close"
        }
    }
}
