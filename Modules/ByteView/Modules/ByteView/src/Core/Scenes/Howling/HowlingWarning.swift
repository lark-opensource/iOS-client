//
//  HowlingWarning.swift
//  ByteView
//
//  Created by wulv on 2021/8/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewUI

/// 啸叫提醒
class HowlingWarning {
    typealias CallBack = () -> Void

    private weak var alert: ByteViewDialog?

    private var control: HowlingFrequencyControl

    private let meeting: InMeetMeeting

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.control = HowlingFrequencyControl(howlingConfig: meeting.setting.howlingConfig, db: HowlingDatabase(storage: meeting.storage))
        self.meeting.microphone.addListener(self)
    }

    deinit {
        alert?.dismiss()
    }

    func canWarn() -> Bool {
        guard control.allowWarn() else { return false }
        guard !meeting.microphone.isMuted || !meeting.audioDevice.output.isMuted else { return false }
        return true
    }

    func showAlert(selectMute: @escaping CallBack) {
        HowlingTrack.showAlert()
        Util.runInMainThread {  [weak self] in
            guard let self = self else { return }
            ByteViewDialog.Builder()
                .id(.howling)
                .needAutoDismiss(true)
                .title(I18n.View_MV_CheckedFoundEcho)
                .message(I18n.View_MV_SmoothMeetingMute)
                .leftTitle(I18n.View_G_IgnoreButtonToast)
                .leftHandler({ [weak self] _ in
                    self?.control.handleIgnore()
                    HowlingTrack.ignoreForAlert()
                })
                .rightTitle(I18n.View_G_MuteButtonToast)
                .rightHandler({ [weak self] _ in
                    self?.control.handleMute()
                    HowlingTrack.muteForAlert()
                    selectMute()
                })
                .show { [weak self] alert in
                    if let self = self {
                        self.alert = alert
                    } else {
                        alert.dismiss()
                    }
                }
        }
    }
}

extension HowlingWarning: InMeetMicrophoneListener {
    func didChangeMicrophoneMuted(_ microphone: InMeetMicrophoneManager) {
        if microphone.isMuted {
            alert?.dismiss()
            alert = nil
        }
    }
}
