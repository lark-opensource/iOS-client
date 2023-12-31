//
//  CameraEntry.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/25.
//

import UIKit
import AVFoundation

@objc
final public class CameraEntry: NSObject, CameraApi {

    private static func getService() -> CameraApi.Type {
        if let service = LSC.getService(forTag: tag) as? CameraApi.Type {
            return service
        }
        return CameraWrapper.self
    }

    /// AVCaptureDevice requestAccessCamera
    @objc
    public static func requestAccessCamera(forToken token: Token,
                                           completionHandler handler: @escaping (Bool) -> Void) throws {
        let context = Context([AtomicInfo.Camera.requestAccessCamera.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().requestAccessCamera(forToken: token, completionHandler: handler)
    }

    /// AVCaptureSession startRunning
    @objc
    public static func startRunning(forToken token: Token, session: AVCaptureSession) throws {
        let context = Context([AtomicInfo.Camera.startRunning.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().startRunning(forToken: token, session: session)
    }

    #if !os(visionOS)
    /// AVCaptureDevice defaultCameraDevice
    public static func defaultCameraDevice(forToken token: Token) throws -> AVCaptureDevice? {
        let context = Context([AtomicInfo.Camera.defaultCameraDevice.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().defaultCameraDevice(forToken: token)
    }

    /// AVCaptureStillImageOutput captureStillImageAsynchronously
    @objc
    @available(iOS, deprecated: 10)
    public static func captureStillImageAsynchronously(forToken token: Token,
                                                       photoFileOutput: AVCaptureStillImageOutput,
                                                       fromConnection connection: AVCaptureConnection,
                                                       completionHandler handler:
                                                       @escaping (CMSampleBuffer?, Error?) -> Void) throws {
        let context = Context([AtomicInfo.Camera.captureStillImageAsynchronously.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().captureStillImageAsynchronously(forToken: token, photoFileOutput: photoFileOutput,
                                                         fromConnection: connection, completionHandler: handler)
    }

    /// AVCaptureMovieFileOutput startRecording
    @objc
    public static func startRecording(forToken token: Token,
                                      movieFileOutput: AVCaptureMovieFileOutput,
                                      toOutputFile outputFileURL: URL,
                                      recordingDelegate delegate: AVCaptureFileOutputRecordingDelegate) throws {
        let context = Context([AtomicInfo.Camera.startRecording.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().startRecording(forToken: token, movieFileOutput: movieFileOutput,
                                        toOutputFile: outputFileURL, recordingDelegate: delegate)
    }

    /// AVCaptureDevice defaultCameraDeviceWithDeviceType
    public static func defaultCameraDeviceWithDeviceType(forToken token: Token,
                                                         deviceType: AVCaptureDevice.DeviceType,
                                                         position: AVCaptureDevice.Position) throws -> AVCaptureDevice? {
        let context = Context([AtomicInfo.Camera.defaultCameraDeviceWithDeviceType.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().defaultCameraDeviceWithDeviceType(forToken: token, deviceType: deviceType, position: position)
    }
    #endif
}
