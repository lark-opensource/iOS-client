//
//  MinutesAudioRecordService.swift
//  MinutesInterface
//
//  Created by Todd Cheng on 2021/3/24.
//

import Foundation

public protocol MinutesAudioRecordService: AnyObject {

    /// 当前是否正在录音
    func isRecording() -> Bool

    /// 停止录音
    func stopRecording()
}
