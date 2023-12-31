//
//  AudioRecordApi.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/22.
//

import UIKit
import AVFoundation

public extension AudioRecordApi {
    /// 外部注册自定义api使用的key值
    static var tag: String {
        "audio"
    }
}

/// audioRecord相关方法
public protocol AudioRecordApi: SensitiveApi {

    /// AVAudioSession requestRecordPermission
    static func requestRecordPermission(forToken token: Token,
                                        session: AVAudioSession,
                                        response: @escaping (Bool) -> Void) throws

    /// AVCaptureDevice requestAccessAudio
    static func requestAccessAudio(forToken token: Token, completionHandler handler: @escaping (Bool) -> Void) throws

    /// AudioOutputUnitStart
    static func audioOutputUnitStart(forToken token: Token, ci: AudioUnit) throws -> OSStatus

    /// AUGraphStart
    static func AUGraphStart(forToken token: Token, inGraph: AUGraph) throws -> OSStatus

    #if !os(visionOS)
    /// AVCaptureDevice defaultAudioDevice
    static func defaultAudioDevice(forToken token: Token) throws -> AVCaptureDevice?

    /// AVCaptureDevice defaultAudioDeviceWithDeviceType
    static func defaultAudioDeviceWithDeviceType(
        forToken token: Token,
        deviceType: AVCaptureDevice.DeviceType,
        position: AVCaptureDevice.Position) throws -> AVCaptureDevice?
    #endif

    /// AudioQueueStart
    static func AudioQueueStart(forToken token: Token,
                                _ inAQ: AudioQueueRef,
                                _ inStartTime: UnsafePointer<AudioTimeStamp>?) throws -> OSStatus
}
