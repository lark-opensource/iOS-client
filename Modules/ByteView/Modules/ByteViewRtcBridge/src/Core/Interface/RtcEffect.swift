//
//  RtcEffect.swift
//  ByteView
//
//  Created by kiri on 2022/8/21.
//

import Foundation

public protocol RtcEffectProtocol {
    var isCameraCapturing: Bool { get }
    func enableBackgroundBlur(_ isEnabled: Bool)
    func setBackgroundImage(_ image: String)
    func applyEffect(_ effectRes: RtcFetchEffectInfo, with type: RtcEffectType, contextId: String, cameraEffectType: RtcCameraEffectType)
    func cancelEffect(_ panel: String, cameraEffectType: RtcCameraEffectType)
}

public final class RtcEffect: RtcEffectProtocol {
    private let device: RtcCameraDevice
    public init(engine: MeetingRtcEngine) {
        self.device = engine.cameraDevice
    }

    public var isCameraCapturing: Bool {
        device.isCapturing
    }

    public func enableBackgroundBlur(_ isEnabled: Bool) {
        device.enableBackgroundBlur(isEnabled)
    }

    public var effectStatus: RtcCameraEffectStatus {
        device.effectStatus
    }

    public func setBackgroundImage(_ image: String) {
        device.setBackgroundImage(image)
    }

    public func applyEffect(_ effectRes: RtcFetchEffectInfo, with type: RtcEffectType, contextId: String, cameraEffectType: RtcCameraEffectType) {
        device.applyEffect(effectRes, with: type, contextId: contextId, cameraEffectType: cameraEffectType)
    }

    public func cancelEffect(_ panel: String, cameraEffectType: RtcCameraEffectType) {
        device.cancelEffect(panel, cameraEffectType: cameraEffectType)
    }
}
