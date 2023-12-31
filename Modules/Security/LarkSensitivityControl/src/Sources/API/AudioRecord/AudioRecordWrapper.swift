//
//  AudioRecordWrapper.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/22.
//

import UIKit
import AVFoundation

/// 对api的内部封装，业务侧需要可以继承并重写相关方法
final class AudioRecordWrapper: NSObject, AudioRecordApi {

    /// AVAudioSession requestRecordPermission
    static func requestRecordPermission(forToken token: Token,
                                        session: AVAudioSession,
                                        response: @escaping (Bool) -> Void) throws {
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: response)
        } else {
            session.requestRecordPermission(response)
        }
    }

    /// AVCaptureDevice requestAccessAudio
    static func requestAccessAudio(forToken token: Token,
                                   completionHandler handler: @escaping (Bool) -> Void) throws {
        AVCaptureDevice.requestAccess(for: .audio, completionHandler: handler)
    }

    /// AudioOutputUnitStart
    static func audioOutputUnitStart(forToken token: Token, ci: AudioUnit) throws -> OSStatus {
        return AudioToolbox.AudioOutputUnitStart(ci)
    }

    /// AUGraphStart
    static func AUGraphStart(forToken token: Token, inGraph: AUGraph) throws -> OSStatus {
        return AudioToolbox.AUGraphStart(inGraph)
    }

    #if !os(visionOS)
    /// AVCaptureDevice defaultAudioDevice
    static func defaultAudioDevice(forToken token: Token) throws -> AVCaptureDevice? {
        return AVCaptureDevice.default(for: .audio)
    }

    /// AVCaptureDevice defaultAudioDeviceWithDeviceType
    static func defaultAudioDeviceWithDeviceType(
        forToken token: Token,
        deviceType: AVCaptureDevice.DeviceType,
        position: AVCaptureDevice.Position) throws -> AVCaptureDevice? {
        return AVCaptureDevice.default(deviceType, for: .audio, position: position)
    }
    #endif

    /// AudioQueueStart
    static func AudioQueueStart(forToken token: Token,
                                _ inAQ: AudioQueueRef,
                                _ inStartTime: UnsafePointer<AudioTimeStamp>?) throws -> OSStatus {
        return AudioToolbox.AudioQueueStart(inAQ, inStartTime)
    }
}
