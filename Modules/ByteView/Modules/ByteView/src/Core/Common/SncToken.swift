//
//  SncToken.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/12/9.
//

import Foundation
import LarkSensitivityControl
import CoreMotion
import ReplayKit

enum SncError: String, Error {
    case tokenNotFound
}

class DeviceSncWrapper {
    static func setProximityMonitoringEnabled(for token: SncToken,
                                              device: UIDevice,
                                              isEnabled: Bool) throws {
        try DeviceInfoEntry.setProximityMonitoringEnabled(forToken: Token(token.rawValue),
                                                          device: device,
                                                          isEnabled: isEnabled)
    }

    static func isProximityMonitoringEnabled(for token: SncToken,
                                             device: UIDevice) throws -> Bool {
        try DeviceInfoEntry.isProximityMonitoringEnabled(forToken: Token(token.rawValue),
                                                         device: device)
    }

    static func startDeviceMotionUpdates(for token: SncToken,
                                         manager: CMMotionManager,
                                         to queue: OperationQueue,
                                         withHandler handler: @escaping CMDeviceMotionHandler) throws {
        try DeviceInfoEntry.startDeviceMotionUpdates(forToken: Token(token.rawValue),
                                                     manager: manager,
                                                     to: queue,
                                                     withHandler: handler)
    }

    static func getifaddrs(for token: SncToken,
                           _ ifad: UnsafeMutablePointer<UnsafeMutablePointer<ifaddrs>?>) throws -> Int32 {
        try DeviceInfoEntry.getifaddrs(forToken: Token(token.rawValue), ifad)
    }
}

final class MicrophoneSncWrapper {
    private static let logger = Logger.getLogger("Privacy")

    static var isRequestAccessSuccessed: Bool = true
    static var isCheckSuccess: Bool = true

    static func requestAccessAudio(withHandler handler: @escaping (Bool, Bool) -> Void) {
        let token: SncToken = .requestMicAccess
        do {
            try AudioRecordEntry.requestAccessAudio(forToken: Token(token.rawValue), completionHandler: { bool in
                handler(bool, true)
                Self.isRequestAccessSuccessed = true
            })
        } catch {
            logger.warn("MicrophoneSncWrapper requestAccessAudio check token[\(token)] error: \(error)")
            handler(false, false)
            isRequestAccessSuccessed = false
        }
    }

    static func startAudioCapture(for token: SncToken) throws {
        do {
            try RTCEntry.checkTokenForStartAudioCapture(Token(token.rawValue))
            isCheckSuccess = true
        } catch {
            logger.warn("MicrophoneSncWrapper StartAudioCapture for token[\(token)] error: \(error)")
            isCheckSuccess = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Toast.showOnVCScene(I18n.View_VM_MicNotWorking)
            }
            throw error
        }
    }
}

final class CameraSncWrapper {
    private static let logger = Logger.getLogger("Privacy")

    @RwAtomic
    private static var checkResults: [SncToken: Bool] = [:]
    static var isRequestAccessSuccessed: Bool { getCheckResult(by: .requestCamAccess) }

    static func requestAccessCamera(withHandler handler: @escaping (Bool, Bool) -> Void) {
        let token: SncToken = .requestCamAccess
        do {
            try CameraEntry.requestAccessCamera(forToken: Token(token.rawValue), completionHandler: { bool in
                handler(bool, true)
                checkResults[token] = true
            })
        } catch {
            logger.warn("CameraSncWrapper check token[\(token)] requestAccessCamera error: \(error)")
            handler(false, false)
            checkResults[token] = false
        }
    }

    static func startVideoCapture(for token: SncToken) throws {
        do {
            try RTCEntry.checkTokenForStartVideoCapture(Token(token.rawValue))
            checkResults[token] = true
        } catch {
            logger.warn("CameraSncWrapper StartAudioCapture for token[\(token)] error: \(error)")
            checkResults[token] = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Toast.showOnVCScene(I18n.View_VM_CameraNotWorking)
            }
            throw error
        }
    }

    static func getCheckResult(by token: SncToken) -> Bool {
        checkResults[token] ?? true
    }
}

final class ShareScreenSncWrapper {
    private static let logger = Logger.getLogger("Privacy")

    @RwAtomic
    private static var checkResults: [SncToken: Bool] = [:]

    @available(iOS 12.0, *)
    static func createRPSystemBroadcastPickerView(for token: SncToken) -> RPSystemBroadcastPickerView? {
        do {
            let pickerView =  try DeviceInfoEntry.createRPSystemBroadcastPickerViewWithFrame(forToken: Token(token.rawValue), frame: .zero)
            checkResults[token] = true
            return pickerView
        } catch {
            logger.warn("ShareScreenSncWrapper create PickerView for token[\(token)] error: \(error)")
            checkResults[token] = false
            if token != .shareScreen {
                Toast.showOnVCScene(I18n.View_G_FailShareForNow)
            }
            return nil
        }
    }

    /// 使用前必须保证对应token已经执行了createRPSystemBroadcastPickerView
    static func getCheckResult(by token: SncToken) -> Bool {
        checkResults[token] ?? true
    }

}
