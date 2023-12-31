//
//  RecordServiceProtocol.swift
//  LarkAudioKit
//
//  Created by 李晨 on 2022/4/24.
//

import Foundation
import LarkSensitivityControl

public protocol RecordServiceDelegate: AnyObject {
    func recordServiceStart()
    func recordServiceStop()
    func onMicrophoneData(_ data: Data)
    func onPowerData(power: Float32)
}

public protocol RecordServiceProtocol {
    var uuid: UUID { get }
    var isRecording: Bool { get }
    var currentTime: TimeInterval { get }
    var delegate: RecordServiceDelegate? { get }

    /// Token: 需要申请 audioOutputUnitStart 和 AudioQueueStart
    func startRecord(token: Token, encoder: RecordServiceDelegate) -> Bool
    /// Token: 需要申请 audioOutputUnitStart 和 AudioQueueStart
    func startRecord(token: Token, encoder: RecordServiceDelegate, result: inout OSStatus) -> Bool
    func stopRecord()
}
