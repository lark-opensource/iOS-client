//
//  DeviceOrientation.swift
//  Camera
//
//  Created by Kongkaikai on 2018/11/11.
//  Copyright © 2018 Kongkaikai. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion
import AVFoundation
import LarkSensitivityControl

final class CameraOrientation {

    var shouldUseDeviceOrientation: Bool = false

    private var deviceOrientation: UIDeviceOrientation?
    private let coreMotionManager = CMMotionManager()
    private var view: UIView?

    init() {
        coreMotionManager.accelerometerUpdateInterval = 0.1
    }

    func start(with view: UIView) throws {
        self.deviceOrientation = UIDevice.current.orientation
        self.view = view
        try DeviceInfoEntry.startAccelerometerUpdates(
            forToken: Token(withIdentifier: "LARK-PSDA-camera_motion_monitor"),
            manager: self.coreMotionManager,
            to: .main, withHandler: { [weak self] (data, _) in
                guard let data = data else {
                    return
                }
                self?.handleAccelerometerUpdate(data: data)
            })
    }

    func stop() {
        self.coreMotionManager.stopAccelerometerUpdates()
        self.deviceOrientation = nil
        self.view = nil
    }

    func getImageOrientation(for camera: CameraController.CameraSession) -> UIImage.Orientation {
        guard shouldUseDeviceOrientation, let deviceOrientation = self.deviceOrientation else {
            return camera == .back ? .right : .leftMirrored
        }

        switch deviceOrientation {
        case .landscapeLeft:
            return camera == .back ? .up : .downMirrored
        case .landscapeRight:
            return camera == .back ? .down : .upMirrored
        case .portraitUpsideDown:
            return camera == .back ? .left : .rightMirrored
        default:
            return camera == .back ? .right : .leftMirrored
        }
    }

    func getPreviewLayerOrientation() -> AVCaptureVideoOrientation {
        // Depends on layout orientation, not device orientation
        let map: [UIInterfaceOrientation: AVCaptureVideoOrientation] = [
            .portrait: .portrait,
            .unknown: .portrait,
            .landscapeLeft: .landscapeLeft,
            .landscapeRight: .landscapeRight,
            .portraitUpsideDown: .portraitUpsideDown
        ]

        return map[interfaceOrientation] ?? .portrait
    }

    func getVideoOrientation() -> AVCaptureVideoOrientation? {
        guard shouldUseDeviceOrientation, let deviceOrientation = self.deviceOrientation else { return nil }

        let map: [UIDeviceOrientation: AVCaptureVideoOrientation] = [
            .landscapeLeft: .landscapeRight,
            .landscapeRight: .landscapeLeft,
            .portraitUpsideDown: .portraitUpsideDown
        ]
        return map[deviceOrientation] ?? .portrait
    }

    func getVideoTransform(for camera: CameraController.CameraSession) -> CGAffineTransform {
        guard shouldUseDeviceOrientation, let deviceOrientation else { return CGAffineTransform(rotationAngle: .pi/2) }
        let shouldMirror = camera == .front
        var transform: CGAffineTransform
        switch deviceOrientation {
        case .landscapeLeft:
            transform = shouldMirror ? CGAffineTransform(rotationAngle: .pi) : .identity
        case .landscapeRight:
            transform = shouldMirror ? .identity : CGAffineTransform(rotationAngle: .pi)
        case .portraitUpsideDown:
            transform = CGAffineTransform(rotationAngle: -.pi/2)
        default: // .portrait
            transform = CGAffineTransform(rotationAngle: .pi/2)
        }
        if shouldMirror {
            transform = CGAffineTransformConcat(transform, CGAffineTransform(scaleX: -1, y: 1))
        }
        return transform
    }

    private func handleAccelerometerUpdate(data: CMAccelerometerData) {
        let orientation = UIDevice.current.orientation
        if orientation == .faceDown || orientation == .faceUp {
            // 设备平躺情况，跟着屏幕方向走
            let map: [UIInterfaceOrientation: UIDeviceOrientation] = [
                .landscapeLeft: .landscapeRight,
                .landscapeRight: .landscapeLeft,
                .portraitUpsideDown: .portraitUpsideDown,
                .portrait: .portrait
            ]
            deviceOrientation = map[interfaceOrientation] ?? .portrait
        } else {
            // 非平躺跟重力陀螺仪判断设备方向
            switch (abs(data.acceleration.y) < abs(data.acceleration.x), data.acceleration.x > 0, data.acceleration.y > 0) {
            case (true, true, _):
                deviceOrientation = .landscapeRight
            case (true, false, _):
                deviceOrientation = .landscapeLeft
            case (false, _, true):
                deviceOrientation = .portraitUpsideDown
            case (false, _, false):
                deviceOrientation = .portrait
            }
        }
    }

    private var interfaceOrientation: UIInterfaceOrientation {
        if #available(iOS 13, *), let windowScene = view?.window?.windowScene {
            return windowScene.interfaceOrientation
        } else {
            return UIApplication.shared.statusBarOrientation
        }
    }
}
