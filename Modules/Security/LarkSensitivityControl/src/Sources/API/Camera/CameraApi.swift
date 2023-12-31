//
//  CameraApi.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/25.
//

import UIKit
import AVFoundation

public extension CameraApi {
    /// 外部注册自定义api使用的key值
    static var tag: String {
        "camera"
    }
}

public protocol CameraApi: SensitiveApi {
    /// AVCaptureDevice requestAccessCamera
    static func requestAccessCamera(forToken token: Token,
                                    completionHandler handler: @escaping (Bool) -> Void) throws

    /// AVCaptureSession startRunning
    static func startRunning(forToken token: Token, session: AVCaptureSession) throws

    #if !os(visionOS)
    /// AVCaptureDevice defaultCameraDevice
    static func defaultCameraDevice(forToken token: Token) throws -> AVCaptureDevice?

    /// AVCaptureStillImageOutput captureStillImageAsynchronously
    @available(iOS, deprecated: 10)
    static func captureStillImageAsynchronously(forToken token: Token,
                                                photoFileOutput: AVCaptureStillImageOutput,
                                                fromConnection connection: AVCaptureConnection,
                                                completionHandler handler:
                                                @escaping (CMSampleBuffer?, Error?) -> Void) throws

    /// AVCaptureMovieFileOutput startRecording
    static func startRecording(forToken token: Token,
                               movieFileOutput: AVCaptureMovieFileOutput,
                               toOutputFile outputFileURL: URL,
                               recordingDelegate delegate: AVCaptureFileOutputRecordingDelegate) throws

    /// AVCaptureDevice defaultCameraDeviceWithDeviceType
    static func defaultCameraDeviceWithDeviceType(forToken token: Token,
                                                  deviceType: AVCaptureDevice.DeviceType,
                                                  position: AVCaptureDevice.Position) throws -> AVCaptureDevice?
    #endif
}
