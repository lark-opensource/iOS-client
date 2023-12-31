//
//  RtcWrapper.swift
//  ByteView
//
//  Created by kiri on 2022/8/12.
//

import Foundation
import ByteViewCommon

final class MockRtcInstance: RtcInstance, CustomStringConvertible {
    let instanceId: String
    let logger: Logger
    @RwAtomic var isDestroyed: Bool = false
    @RwAtomic var createParams: RtcCreateParams
    let description: String
    private let listeners: RtcListeners

    private static let instanceIdGenerator = UUIDGenerator()
    init(params: RtcCreateParams, listeners: RtcListeners) {
        self.instanceId = Self.instanceIdGenerator.generate()
        self.createParams = params
        self.listeners = listeners
        self.description = "[Rtc(\(instanceId))][\(params.sessionId)]"
        self.logger = Logger.byteRtc.withContext("\(params.sessionId)-\(instanceId)").withTag(self.description)
        logger.info("init MockRtc")
    }

    deinit {
        logger.info("deinit MockRtc")
        assert(isDestroyed, "must destory Rtc before deinit!")
    }

    func destroy() {
        if self.isDestroyed { return }
        self.isDestroyed = true

    }

    func reuse(_ params: RtcCreateParams, checkSession: Bool) throws {
        if isDestroyed {
            throw RtcReuseError.isDestroyed
        }
        if params.uuid == createParams.uuid {
            return
        }
        if params.rtcAppId != createParams.rtcAppId {
            throw RtcReuseError.invalidAppId
        }
        if params.uid != createParams.uid {
            throw RtcReuseError.invalidUid
        }
        if checkSession, params.sessionId != createParams.sessionId {
            throw RtcReuseError.invalidSessionId
        }
        self.createParams = createParams
    }

    static func enableAUPreStart(_ needPreStart: Bool) {}

    func setRuntimeParameters(_ parameters: [String: Any]) {
    }

    func joinChannel(byKey channelKey: String?, channelName: String, info: String?, traceId: String) {
        listeners.listeners.forEach {
            $0.onJoinChannelSuccess()
        }
    }

    func leaveChannel() {
    }

    func setClientRole(_ role: RtcClientRole) {
    }

    func enableSimulcastMode(_ isEnabled: Bool) {
    }

    func setVideoCaptureConfig(videoSize: CGSize, frameRate: Int) {
    }

    func setVideoEncoderConfig(channel: [RtcVideoEncoderConfig], main: [RtcVideoEncoderConfig]) {
    }

    func forceSetVideoProfiles(_ descriptions: [RtcVideoStreamDescription]) {
    }

    private var isLocalAudioMuted = true
    func muteLocalAudioStream(_ muted: Bool) {
        self.isLocalAudioMuted = muted
    }

    func isMuteLocalAudio() -> Bool {
        return self.isLocalAudioMuted
    }

    func setNsOption(_ option: RtcNsOption) {
    }

    func enableRNNoise(_ isEnabled: Bool) {
    }

    func muteAudioPlayback(_ muted: Bool) {
    }

    func setAudioUnitProperty(_ property: RtcAUProperty, isOn: Bool) {
    }

    func startAudioCapture(scene: RtcAudioScene) throws {
    }

    func stopAudioCapture() {
    }

    func enableVideo() {
    }

    func startVideoCapture(scene: RtcCameraScene) throws {
    }

    func stopVideoCapture() {
    }

    private var isLocalVideoMuted = true
    func muteLocalVideoStream(_ muted: Bool) {
        self.isLocalVideoMuted = muted
    }

    func isMuteLocalVideo() -> Bool {
        return self.isLocalVideoMuted
    }

    func switchCamera(isFront: Bool) {
    }

    func enablePIPMode(_ enable: Bool) {
    }

    func enableBackgroundBlur(_ isEnabled: Bool) {
    }

    func setBackgroundImage(_ filePath: String) {
    }

    func setDeviceOrientation(_ orientation: Int) {
    }

    func applyEffect(_ effectRes: RtcFetchEffectInfo, with type: RtcEffectType, contextId: String, cameraEffectType: RtcCameraEffectType) {
    }

    func cancelEffect(_ panel: String, cameraEffectType: RtcCameraEffectType) {
    }

    func login(_ token: String, uid: String) {
    }

    func logout() {
    }

    func setServerParams(_ signature: String, url: String) {
    }

    func sendServerBinaryMessage(_ message: Data) -> Int64 {
        return 0
    }

    func setVideoSourceType(_ type: RtcVideoSourceType, with streamIndex: RtcStreamIndex) {
    }

    func setCellularEnhancement(_ config: RtcCellularEnhancementConfig) {
    }

    func publishScreen() {
    }

    func unpublishScreen() {
    }

    func sendScreenCaptureExtensionMessage(_ messsage: Data) {
    }

    func updateScreenCapture(_ type: RtcScreenMediaType) {
    }

    func setPublishChannel(_ channelName: String) {
    }

    func setSubChannels(_ channelIds: [String]) {
    }

    func enableRescaleAudioVolume(_ enable: Bool) {
    }

    func joinBreakDownRoom(_ groupName: String, subMain: Bool) {
    }

    func leaveBreakDownRoom() {
    }

    func setRemoteUserPriority(_ uid: RtcUID, priority: RtcRemoteUserPriority) {
    }

    func setChannelProfile(_ channelProfile: RtcMeetingChannelProfileType) {
    }

    func startAudioMixing(_ soundId: Int32, filePath: String, loopback: Bool, playCount: Int) -> Int {
        return 0
    }

    func stopAudioMixing(_ soundId: Int32) {
    }

    func startManualPerfAdjust() -> Bool {
        return true
    }

    func setNextPerfAdjustUnit(_ unit: RtcPerfAdjustUnitType, direction: RtcPerfAdjustDirection, config: RtcManualPerfAdjustConfig) -> Bool {
        return true
    }

    private enum RtcReuseError: String, Error, CustomStringConvertible {
        case invalidAppId
        case invalidUid
        case invalidSessionId
        case isDestroyed

        var description: String { "RtcReuseError.\(rawValue)" }
    }
}
