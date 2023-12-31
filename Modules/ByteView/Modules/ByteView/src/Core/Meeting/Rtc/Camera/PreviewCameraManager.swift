//
//  PreviewCameraManager.swift
//  ByteView
//
//  Created by kiri on 2022/8/20.
//

import Foundation
import ByteViewTracker
import UIKit
import AVFoundation
import LarkMedia
import ByteViewRtcBridge

protocol PreviewCameraDelegate: AnyObject {
    func cameraNeedShowToast(_ camera: PreviewCameraManager, content: PreviewCameraManager.ToastContent)
    func cameraWasInterrupted(_ camera: PreviewCameraManager)
    func cameraInterruptionEnded(_ camera: PreviewCameraManager)
    func didFailedToStartVideoCapture(error: Error)
}

extension PreviewCameraDelegate {
    func cameraNeedShowToast(_ camera: PreviewCameraManager, content: PreviewCameraManager.ToastContent) {}
    func cameraWasInterrupted(_ camera: PreviewCameraManager) {}
    func cameraInterruptionEnded(_ camera: PreviewCameraManager) {}
    func didFailedToStartVideoCapture(error: Error) {}
}

/// 用于预览的camera对象，除摄像头本身开关外，还处理特效、渲染、摄像头不可用等事件
final class PreviewCameraManager {
    weak var delegate: PreviewCameraDelegate?
    private let logger = Logger.camera
    private let rtc: LabCamera
    var effect: RtcEffect { rtc.effect }

    init(scene: RtcCameraScene, service: MeetingBasicService, effectManger: MeetingEffectManger?, isFromLab: Bool = false) {
        self.rtc = LabCamera(engine: service.rtc, scene: scene, service: service, effectManger: effectManger, isFromLab: isFromLab)
        self.rtc.addListener(self)
        self.logger.info("init PreviewCamera \(self.rtc.scene)")
    }

    var isMuted: Bool { rtc.isInterrupted || rtc.isMuted }
    var isFrontCamera: Bool { rtc.isFrontCamera }

    func setMuted(_ isMuted: Bool, file: String = #fileID, function: String = #function, line: Int = #line) {
        if !isMuted, rtc.isInterrupted {
            logger.error("mute camera false failed, rtc is interrupted, reason = \(rtc.lastInterruptionReason)",
                         file: file, function: function, line: line)
            if rtc.lastInterruptionReason == .notAvailableWithMultipleForegroundApps {
                delegate?.cameraNeedShowToast(self, content: .split)
            }
            return
        }

        let isMutedChanged = isMuted != self.isMuted
        logger.info("mute camera \(isMuted) success, isChanged = \(isMutedChanged)", file: file, function: function, line: line)
        setMutedInternal(isMuted)
        if isMutedChanged, !rtc.isInterrupted {
            delegate?.cameraNeedShowToast(self, content: isMuted ? .off : .on)
        }
    }

    func switchCamera() {
        rtc.switchCamera()
    }

    func releaseCamera() {
        rtc.release()
    }

    private func setMutedInternal(_ isMuted: Bool) {
        rtc.setMuted(isMuted)
        updateCameraMutex(isMuted)
    }

    private func updateCameraMutex(_ isMuted: Bool) {
        LarkMediaManager.shared.update(scene: .vcMeeting, mediaType: .camera, priority: isMuted ? nil : .high)
    }

    enum ToastContent {
        case split
        case on
        case off

        var localizedDescription: String {
            switch self {
            case .split:
                return I18n.View_G_NoCamMultitask
            case .on:
                return I18n.View_VM_CameraOn
            case .off:
                return I18n.View_VM_CameraOff
            }
        }
    }
}

extension PreviewCameraManager: RtcCameraListener {
    func didFailedToStartVideoCapture(scene: RtcCameraScene, error: Error) {
        delegate?.didFailedToStartVideoCapture(error: error)
    }

    /// https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_developer_avfoundation_multitasking-camera-access
    func cameraWasInterrupted(reason: RtcCameraInterruptionReason) {
        if reason == .notAvailableWithMultipleForegroundApps {
            delegate?.cameraNeedShowToast(self, content: .split)
        }
        delegate?.cameraWasInterrupted(self)
    }

    func cameraInterruptionEnded() {
        delegate?.cameraInterruptionEnded(self)
    }
}
