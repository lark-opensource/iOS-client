//
//  MeetInBusyViewModel.swift
//  ByteView
//
//  Created by wangpeiran on 2022/10/3.
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

class MeetInBusyViewModel: MeetInViewModel {

    private weak var weakPolicyAlert: ByteViewDialog?

    deinit {
        weakPolicyAlert?.dismiss()
    }

    // 接受
    override func accept(isCameraOn: Bool?, isMicOn: Bool?) {
        accept(isVoiceOnly: false, isCameraOn: isCameraOn, isMicOn: isMicOn)
        trackPressAction(click: "accept", target: callInType == .vc ? TrackEventName.vc_meeting_onthecall_view : TrackEventName.vc_office_phone_calling_view)
        OnthecallReciableTracker.startEnterOnthecall() // 原来忙线没有，重构后加上
        meeting.slaTracker.startEnterOnthecall()
    }

    private func accept(isVoiceOnly: Bool, isCameraOn: Bool?, isMicOn: Bool?) {
        guard let info = meeting.videoChatInfo else {
            return
        }
        self.onAccept()
        if info.type == .meet {
            var setting: MicCameraSetting = .none
            if let isCameraOn = isCameraOn, let isMicOn = isMicOn {
                if Privacy.videoAuthorized && isCameraOn {
                    setting.isCameraEnabled = true
                }
                if Privacy.audioAuthorized && isMicOn {
                    setting.isMicrophoneEnabled = true
                }
            } else {
                let videoSetting = info.settings
                if !videoSetting.isMicrophoneMuted {
                    setting.isMicrophoneEnabled = true
                }
                if !videoSetting.isCameraMuted {
                    setting.isCameraEnabled = true
                }
            }
            self.mayAccept(setting: setting)
        }
    }
}
