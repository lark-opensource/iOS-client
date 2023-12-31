//
//  VECodeScanTool.swift
//  QRCode
//
//  Created by ByteDance on 2022/12/11.
//

import UIKit
import Foundation
import TTVideoEditor
import RxSwift
import LKCommonsLogging
import LarkSetting
import LarkSensitivityControl

public enum ScanQRCodeFeatureKey: String {
    case distinctEnableClose = "core.scan.distinct.optimize.close"

    public var key: FeatureGatingManager.Key {
        FeatureGatingManager.Key(stringLiteral: rawValue)
    }
}

final class CodeScanTool: NSObject {
    static let logger = Logger.log(CodeScanTool.self, category: "Module.LarkQRCode.CodeScanTool")

    /// 支持的摄像头设备类型列表
    class func supportedCameraTypes() -> [(deviceType: AVCaptureDevice.DeviceType, minZoomFactor: CGFloat)] {
        var cameraList: [(deviceType: AVCaptureDevice.DeviceType, minZoomFactor: CGFloat)] = []
        if #available(iOS 13, *) {
            // triple和dualWide有超广角镜头
            // we're expected to set the minimize zoom to 1
            // so we should set the factor to 2 on those two lens
            /**
             builtInTripleCamera 代表支持三摄摄像头的设备类型
             builtInDualWideCamera 代表支持双广角摄像头的设备类型
             builtInDualCamera 代表支持双摄摄像头的设备类型
             builtInWideAngleCamera 代表支持广角摄像头的设备类型
             */
            cameraList += [(.builtInTripleCamera, 2),
                           (.builtInDualWideCamera, 2)]
       }
        cameraList += [(.builtInDualCamera, 1),
                       (.builtInWideAngleCamera, 1)]
        return cameraList
    }

    class func minZoomFactor(for deviceType: AVCaptureDevice.DeviceType) -> CGFloat {
        if let tuple = Self.supportedCameraTypes().first(where: { $0.deviceType == deviceType }) {
            return tuple.minZoomFactor
        }
        assertionFailure("deviceType not supported")
        Self.logger.info("deviceType not supported: \(deviceType), return default value 1")
        return 1
    }

    static func execInMainThread(block: @escaping () -> Void) {
        if Thread.current.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

public enum QRCodeSensitivityEntryToken: Int {
    case OPVEScanCodeCamera_openCamera
}

extension QRCodeSensitivityEntryToken {
    public var psdaToken: LarkSensitivityControl.Token {
        return Token(stringValue)
    }
    public var stringValue: String {
        switch self {
        case .OPVEScanCodeCamera_openCamera:
            return "LARK-PSDA-qrcode_ve_scan_openCamera"
        }
    }
}
