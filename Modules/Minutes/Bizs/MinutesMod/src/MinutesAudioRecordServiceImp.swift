//
//  MinutesAudioRecordServiceImp.swift
//  Minutes
//
//  Created by Todd Cheng on 2021/3/24.
//

import Foundation
import MinutesInterface
import Minutes

public final class MinutesAudioRecordServiceImp: MinutesAudioRecordService {
    /// 初始化方法
    public init() { }

    /// 当前是否正在录音
    public func isRecording() -> Bool {
        return MinutesAudioRecorder.shared.status != .idle
    }

    /// 停止录音
    public func stopRecording() {
        NotificationCenter.default.post(name: Notification.minutesAudioRecordingVCDismiss,
                                        object: nil,
                                        userInfo: [Notification.Key.minutesAudioRecordIsStop: true])
        MinutesAudioRecorder.shared.stop()
    }
}
