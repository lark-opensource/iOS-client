//
//  HowlingDetection.swift
//  ByteView
//
//  Created by wulv on 2021/8/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewRtcBridge

/// 啸叫检测
/// https://bytedance.feishu.cn/docs/doccn3eB0aMH8NxdEMlC20g1qAg#P9bTlg
final class HowlingDetection {
    private let warning: HowlingWarning
    private let meeting: InMeetMeeting

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        self.warning = HowlingWarning(meeting: meeting)
        meeting.rtc.engine.addListener(self)
    }
}

extension HowlingDetection: RtcListener {
    func onMediaDeviceWarning(warnCode: RtcMediaDeviceWarnCode) {
        if warnCode == .howling, self.warning.canWarn() {
            self.warning.showAlert(selectMute: { [weak self] in
                guard let self = self else { return }
                self.meeting.audioDevice.output.setMuted(true)
                self.meeting.audioDevice.output.dismissPicker()
                self.meeting.microphone.muteMyself(true, source: .howling_detection, completion: nil)
            })
        }
    }
}
