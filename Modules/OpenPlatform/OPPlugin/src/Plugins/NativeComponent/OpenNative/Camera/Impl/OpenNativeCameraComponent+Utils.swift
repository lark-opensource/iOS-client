//
//  OpenNativeCameraComponent+Utils.swift
//  OPPlugin
//
//  Created by baojianjun on 2022/8/22.
//

import AVFoundation
import Foundation
import TTVideoEditor
import OPFoundation

// MARK: - Utils 转换
extension OpenNativeCameraComponent {
    class func customConfig() -> IESMMCameraConfig {
        let config = IESMMCameraConfig()
        config.previewType = .GL
        config.sessionMode = .normal
        config.previewModeType = .preserveAspectRatioAndFill
        config.captureRatio = .ratioAuto
        config.pixelFormatType = ._32BGRA
        config.focusMode = .continuousAutoFocus
        config.useSDKGesture = true
        config.enableTapFocus = true
        config.preferredFrontExposureMode = .continuousAutoExposure
        config.isNeedCaptureRecordFirstFrame = true
        
        return config
    }
    
    class func getOutputSize(resolution: CameraResolution, previewSize: CGSize) -> CGSize {
        let resolutionSize = getResolutionSize(with: resolution)
        return resolutionSize.getMaxSize(from: previewSize)
    }
    
    class func getCameraPosition(with devicePosition: CameraDevicePosition) -> AVCaptureDevice.Position {
        switch devicePosition {
        case .front:
            return AVCaptureDevice.Position.front
        case .back:
            return AVCaptureDevice.Position.back
        }
    }
    
    class func getEnumCameraPosition(with devicePosition: AVCaptureDevice.Position) -> CameraDevicePosition {
        switch devicePosition {
        case .front:
            return .front
        default:
            return .back
        }
    }
    
    class func getResolution(with resolution: CameraResolution) -> AVCaptureSession.Preset {
        switch resolution {
        case .low:
            return AVCaptureSession.Preset.vga640x480
        case .high:
            return AVCaptureSession.Preset.hd1920x1080
        case .medium:
            return AVCaptureSession.Preset.hd1280x720
        }
    }
    
    class func getResolutionSize(with resolution: CameraResolution) -> CGSize {
        switch resolution {
        case .low:
            return .init(width: 640, height: 480)
        case .high:
            return .init(width: 1920, height: 1080)
        case .medium:
            return .init(width: 1280, height: 720)
        }
    }
    
    class func getFlash(with flash: CameraFlash) -> IESCameraFlashMode {
        switch flash {
        case .on, .torch:
            return .on
        case .off:
            return .off
        case .auto:
            return .auto
        }
    }
    
    class func getCompressionQuality(with resolution: CameraResolution) -> CGFloat {
        switch resolution {
        case .low:
            return 0.5
        case .high:
            return 1.0
        case .medium:
            return 0.8
        }
    }
}

extension CGSize {
    func getMaxSize(from frameSize: CGSize) -> CGSize {
        let thisWidth = width
        let thisHeight = height
        var sizeWidth = frameSize.width
        var sizeHeight = frameSize.height
        guard  thisWidth > Double.ulpOfOne,
               thisHeight > Double.ulpOfOne,
               sizeWidth > Double.ulpOfOne,
               sizeHeight > Double.ulpOfOne else {
            return frameSize
        }
        
        var needRotate = false
        if sizeWidth < sizeHeight {
            needRotate = true
            exchange(&sizeWidth, &sizeHeight)
        }
        
        let thisWidthHeightRatio = thisWidth / thisHeight
        let rectWidthHeightRatio = sizeWidth / sizeHeight
        var width, height: Double
        
        if thisWidthHeightRatio < rectWidthHeightRatio {
            width = thisWidth
            height = width / rectWidthHeightRatio
        } else {
            height = thisHeight
            width = height * rectWidthHeightRatio
        }
        if needRotate {
            exchange(&width, &height)
        }
        return CGSize(width: width, height: height)
    }
}

func exchange<T>( _ a: inout T, _ b: inout T) {
    let tmp = a
    a = b
    b = tmp
}

extension Double {
    // zoom 范围控制
    func adapter(with maxZoom: Double?) -> Double {
        if self < 1 {
            return 1
        } else if let maxZoom = maxZoom, self > maxZoom {
            return maxZoom
        }
        return self
    }
}

extension UIInterfaceOrientation {
    func videoOrientation() -> AVCaptureVideoOrientation {
        switch self {
        case .portrait, .unknown:
            return .portrait
        case .landscapeLeft:
            return .landscapeLeft
        case .landscapeRight:
            return .landscapeRight
        case .portraitUpsideDown:
            return .portraitUpsideDown
        @unknown default:
            return .portrait
        }
    }
    
    func rotationMode() -> HTSGLRotationMode {
        switch self {
        case .portrait, .unknown:
            return .noRotation
        case .landscapeLeft:
            return .rotateLeft
        case .landscapeRight:
            return .rotateRight
        case .portraitUpsideDown:
            return .rotate180
        @unknown default:
            return .noRotation
        }
    }
    
    func outputVideoOrientation() -> UIImage.Orientation {
        switch self {
        case .portrait, .unknown:
            return .up
        case .landscapeLeft:
            return .right
        case .landscapeRight:
            return .left
        case .portraitUpsideDown:
            return .down
        @unknown default:
            return .up
        }
    }
}

func getInterfaceOrientation() -> UIInterfaceOrientation {
    var interfaceOrientation: UIInterfaceOrientation
    if #available(iOS 13.0, *) {
        interfaceOrientation = OPWindowHelper.fincMainSceneWindow()?.windowScene?.interfaceOrientation ?? UIApplication.shared.statusBarOrientation
    } else {
        interfaceOrientation = UIApplication.shared.statusBarOrientation
    }
    return interfaceOrientation
}
