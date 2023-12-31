//
//  MicCameraSetting.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/6/19.
//

import Foundation

public struct MicCameraSetting: Equatable, CustomStringConvertible {
    /// 麦克风及听筒
    public var isMicrophoneEnabled = false
    /// 摄像头
    public var isCameraEnabled = false

    public init(isMicrophoneEnabled: Bool, isCameraEnabled: Bool) {
        self.isMicrophoneEnabled = isMicrophoneEnabled
        self.isCameraEnabled = isCameraEnabled
    }

    public var description: String {
        "MicCameraSetting(mic=\(isMicrophoneEnabled ? 1 : 0), cam=\(isCameraEnabled ? 1 : 0))"
    }
}
