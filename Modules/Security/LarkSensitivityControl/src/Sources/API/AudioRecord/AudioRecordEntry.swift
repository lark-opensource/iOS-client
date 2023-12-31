//
//  AudioRecordEntry.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/22.
//

import UIKit
import AVFoundation

/// 业务方直接使用
@objc
final public class AudioRecordEntry: NSObject, AudioRecordApi {

    private static func getService() -> AudioRecordApi.Type {
        if let service = LSC.getService(forTag: tag) as? AudioRecordApi.Type {
            return service
        }
        return AudioRecordWrapper.self
    }

    /// AVAudioSession requestRecordPermission
    @objc
    public static func requestRecordPermission(forToken token: Token,
                                               session: AVAudioSession,
                                               response: @escaping (Bool) -> Void) throws {
        let context = Context([AtomicInfo.AudioRecord.requestRecordPermission.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestRecordPermission(forToken: token, session: session, response: response)
    }

    /// AVCaptureDevice requestAccessAudio
    @objc
    public static func requestAccessAudio(forToken token: Token,
                                          completionHandler handler: @escaping (Bool) -> Void) throws {
        let context = Context([AtomicInfo.AudioRecord.requestAccessAudio.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestAccessAudio(forToken: token, completionHandler: handler)
    }

    /// AudioOutputUnitStart
    public static func audioOutputUnitStart(forToken token: Token, ci: AudioUnit) throws -> OSStatus {
        let context = Context([AtomicInfo.AudioRecord.audioOutputUnitStart.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().audioOutputUnitStart(forToken: token, ci: ci)
    }

    /// AUGraphStart
    public static func AUGraphStart(forToken token: Token, inGraph: AUGraph) throws -> OSStatus {
        let context = Context([AtomicInfo.AudioRecord.AUGraphStart.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().AUGraphStart(forToken: token, inGraph: inGraph)
    }

    #if !os(visionOS)
    /// AVCaptureDevice defaultAudioDevice
    public static func defaultAudioDevice(forToken token: Token) throws -> AVCaptureDevice? {
        let context = Context([AtomicInfo.AudioRecord.defaultAudioDevice.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().defaultAudioDevice(forToken: token)
    }

    /// AVCaptureDevice defaultAudioDeviceWithDeviceType
    public static func defaultAudioDeviceWithDeviceType(forToken token: Token,
                                                        deviceType: AVCaptureDevice.DeviceType,
                                                        position: AVCaptureDevice.Position) throws -> AVCaptureDevice? {
        let context = Context([AtomicInfo.AudioRecord.defaultAudioDeviceWithDeviceType.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().defaultAudioDeviceWithDeviceType(forToken: token, deviceType: deviceType, position: position)
    }
    #endif

    /// AudioQueueStart
    public static func AudioQueueStart(forToken token: Token,
                                       _ inAQ: AudioQueueRef,
                                       _ inStartTime: UnsafePointer<AudioTimeStamp>?) throws -> OSStatus {
        let context = Context([AtomicInfo.AudioRecord.AudioQueueStart.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().AudioQueueStart(forToken: token, inAQ, inStartTime)
    }
}

/// for OC
extension AudioRecordEntry {
    /// AudioOutputUnitStart for OC
    @objc
    public static func audioOutputUnitStart(forToken token: Token, ci: AudioUnit,
                                            err: UnsafeMutablePointer<NSError?>?) -> Int32 {
        do {
            return try audioOutputUnitStart(forToken: token, ci: ci)
        } catch {
            err?.pointee = error as NSError
        }
        return -1
    }

    /// AUGraphStart for OC
    @objc
    public static func AUGraphStart(forToken token: Token, inGraph: AUGraph, err: UnsafeMutablePointer<NSError?>?) -> Int32 {
        do {
            return try AUGraphStart(forToken: token, inGraph: inGraph)
        } catch {
            err?.pointee = error as NSError
        }
        return -1
    }

}
