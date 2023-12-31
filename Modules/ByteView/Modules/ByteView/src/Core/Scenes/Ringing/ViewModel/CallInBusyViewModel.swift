//
//  CallInBusyViewModel.swift
//  ByteView
//
//  Created by wangpeiran on 2022/9/27.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewCommon
import ByteViewNetwork
import ByteViewMeeting
import ByteViewTracker
import AVFoundation

class CallInBusyViewModel: CallInViewModel {

    // 接受
    override func accept() {
        accept(isVoiceOnly: false)
        trackPressAction(click: "accept", target: callInType == .vc ? TrackEventName.vc_meeting_onthecall_view : TrackEventName.vc_office_phone_calling_view)
    }

    // 用语音接听
    override func acceptVoiceOnly() {
        accept(isVoiceOnly: true)
        trackPressAction(click: "audio_only", target: TrackEventName.vc_meeting_onthecall_view)
    }

    private func accept(isVoiceOnly: Bool) {
        let isVoice = isVoiceOnly || isVoiceCall
        OnthecallReciableTracker.startEnterOnthecall() // 原来忙线没有，重构后加上
        meeting.slaTracker.startEnterOnthecall()
        guard let info = meeting.videoChatInfo else { return }
        self.onAccept()
        if info.type != .meet {  // 正常逻辑不会为meet，这里是callin的vm
            meeting.acceptRinging(setting: isVoice ? .onlyAudio : .default)
        }
    }
}
