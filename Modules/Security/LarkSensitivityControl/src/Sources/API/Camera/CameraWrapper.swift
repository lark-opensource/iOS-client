//
//  CameraWrapper.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/25.
//

import UIKit
import AVFoundation

final class CameraWrapper: NSObject, CameraApi {
    /// AVCaptureDevice requestAccessCamera
    static func requestAccessCamera(forToken token: Token,
                                    completionHandler handler: @escaping (Bool) -> Void) throws {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: handler)
    }

    /// AVCaptureSession startRunning
    static func startRunning(forToken token: Token, session: AVCaptureSession) throws {
        session.startRunning()
    }

    #if !os(visionOS)
    /// AVCaptureDevice defaultCameraDevice
    static func defaultCameraDevice(forToken token: Token) throws -> AVCaptureDevice? {
        return AVCaptureDevice.default(for: .video)
    }

    /// AVCaptureStillImageOutput captureStillImageAsynchronously
    @available(iOS, deprecated: 10)
    static func captureStillImageAsynchronously(forToken token: Token,
                                                photoFileOutput: AVCaptureStillImageOutput,
                                                fromConnection connection: AVCaptureConnection,
                                                completionHandler handler:
                                                @escaping (CMSampleBuffer?, Error?) -> Void) throws {
        photoFileOutput.captureStillImageAsynchronously(from: connection, completionHandler: handler)
    }

    /// AVCaptureMovieFileOutput startRecording
    static func startRecording(forToken token: Token,
                               movieFileOutput: AVCaptureMovieFileOutput,
                               toOutputFile outputFileURL: URL,
                               recordingDelegate delegate: AVCaptureFileOutputRecordingDelegate) throws {
        movieFileOutput.startRecording(to: outputFileURL, recordingDelegate: delegate)
    }

    /// AVCaptureDevice defaultCameraDeviceWithDeviceType
    static func defaultCameraDeviceWithDeviceType(forToken token: Token,
                                                  deviceType: AVCaptureDevice.DeviceType,
                                                  position: AVCaptureDevice.Position) throws -> AVCaptureDevice? {
        return AVCaptureDevice.default(deviceType, for: .video, position: position)
    }
    #endif
}
