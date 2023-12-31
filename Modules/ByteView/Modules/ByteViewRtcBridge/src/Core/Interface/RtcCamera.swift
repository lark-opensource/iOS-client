//
//  RtcCamera.swift
//  ByteView
//
//  Created by kiri on 2022/8/19.
//

import Foundation
import ByteViewCommon

/// 每个使用摄像头的场景均需持有一个RtcCamera实例
/// - note：RtcCamera存在期间Rtc实例不会释放，所以不建议静态持有，并注意RtcCamera本身是否内存泄漏
open class RtcCamera {
    private let engine: MeetingRtcEngine
    private let device: RtcCameraDevice
    public let scene: RtcCameraScene
    public let logger: Logger

    public private(set) lazy var effect: RtcEffect = {
        engine.ensureRtc()
        return RtcEffect(engine: engine)
    }()

    @RwAtomic
    public private(set) var isReleased: Bool = false

    /// - parameter scene: 摄像头使用的场景，多个场景同时使用的时候，不同的RtcCamera间scene不可重复
    public init(engine: MeetingRtcEngine, scene: RtcCameraScene) {
        self.engine = engine
        self.scene = scene
        self.device = engine.cameraDevice
        self.logger = Logger.camera.withContext(engine.sessionId).withTag("[\(type(of: self))(\(engine.sessionId))]")
    }

    public convenience init(engine: InMeetRtcEngine, scene: RtcCameraScene) {
        self.init(engine: engine.rtc, scene: scene)
    }

    deinit {
        release()
    }

    public var isInterrupted: Bool { device.isInterrupted }
    public var lastInterruptionReason: RtcCameraInterruptionReason? { device.lastInterruptionReason }
    public var isMuted: Bool { device.isMuted(for: scene) }

    open func setMuted(_ isMuted: Bool, file: String = #fileID, function: String = #function, line: Int = #line) {
        if isReleased { return }
        device.setMuted(isMuted, for: scene, file: file, function: function, line: line)
    }

    public var isFrontCamera: Bool {
        device.isFrontCamera
    }

    open func switchCamera() {
        device.switchCamera()
    }

    /// 用于提前释放rtc
    public func release() {
        if !isReleased {
            isReleased = true
            device.setMuted(true, for: scene)
        }
    }

    /// 获取rtc真实的mute状态
    /// - parameter completion: isMuteLocalVideo
    public func fetchLocalVideoMuted(completion: @escaping (Bool) -> Void) {
        engine.execute({ rtcKit in
            completion(rtcKit.isMuteLocalVideo())
        })
    }

    public func setClientRole(_ role: RtcClientRole) {
        engine.execute { rtcKit in
            rtcKit.setClientRole(role)
        }
    }

    public func addListener(_ listener: RtcCameraListener) {
        device.listeners.addListener(listener)
    }

    public func removeListener(_ listener: RtcCameraListener) {
        device.listeners.removeListener(listener)
    }
}
