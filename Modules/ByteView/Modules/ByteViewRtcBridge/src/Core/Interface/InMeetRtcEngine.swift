//
//  InMeetRtcEngine.swift
//  ByteView
//
//  Created by kiri on 2022/8/9.
//

import Foundation
import AVFAudio
import ByteViewCommon

public final class InMeetRtcEngine: CustomStringConvertible {
    public let uid: RtcUID
    public let description: String
    let logger: Logger
    let rtc: MeetingRtcEngine
    init(_ engine: MeetingRtcEngine) {
        self.uid = RtcUID(engine.createParams.uid)
        self.description = "InMeetRtcEngine(\(engine.sessionId))"
        self.logger = Logger.byteRtc.withContext(engine.sessionId).withTag("[\(self.description)]")
        self.rtc = engine
        engine.ensureRtc(isInMeet: true)
        logger.info("init \(description)")
    }

    deinit {
        logger.info("deinit \(description)")
    }

    public func joinChannel(_ params: RtcJoinParams) {
        rtc.joinChannel(params)
    }

    public func leaveChannel() {
        rtc.leaveChannel()
    }

    public func setClientRole(_ clientRole: RtcClientRole) {
        rtc.execute {
            $0.setClientRole(clientRole)
        }
    }

    public func setChannelProfile(_ profile: RtcMeetingChannelProfileType) {
        rtc.execute { rtcKit in
            rtcKit.setChannelProfile(profile)
        }
    }

    public func setScreenVideoEncoderConfig(_ config: RtcVideoEncoderConfig) {
        rtc.execute { rtcKit in
            rtcKit.setScreenVideoEncoderConfig(config)
        }
    }

    public func enableSimulcastMode(_ isEnabled: Bool) {
        rtc.execute { rtcKit in
            rtcKit.enableSimulcastMode(isEnabled)
        }
    }

    public func setVideoEncoderConfig(channel: [RtcVideoEncoderConfig], main: [RtcVideoEncoderConfig]) {
        rtc.execute { rtcKit in
            rtcKit.setVideoEncoderConfig(channel: channel, main: main)
        }
    }

    public func setCellularEnhancement(_ config: RtcCellularEnhancementConfig) {
        rtc.execute { rtcKit in
            rtcKit.setCellularEnhancement(config)
        }
    }

    /// 设置simulcast参数，需要指定定每组分辨率的宽、高、帧率、码率
    public func forceSetVideoProfiles(_ descriptions: [RtcVideoStreamDescription]) {
        rtc.execute { rtcKit in
            rtcKit.forceSetVideoProfiles(descriptions)
        }
    }

    public func joinBreakoutRoom(_ channelId: String) {
        rtc.execute { rtcKit in
            rtcKit.joinBreakDownRoom(channelId, subMain: false)
        }
    }

    public func leaveBreakoutRoom() {
        rtc.execute { rtcKit in
            rtcKit.leaveBreakDownRoom()
        }
    }

    public func setPublishChannel(channelId: String) {
        rtc.execute { rtcKit in
            rtcKit.setPublishChannel(channelId)
        }
    }

    public func setSubChannels(_ channelIds: [String]) {
        if channelIds.isEmpty {
            logger.info("setSubChannels error: channelId is empty")
            return
        }
        rtc.execute { rtcKit in
            rtcKit.setSubChannels(channelIds)
        }
    }

    // 原声抑制
    // - https://bytedance.feishu.cn/docx/U9mTd2Uxbo72lMxvkJhcwNbin4b
    public func toggleRescaleAudioVolume(enable: Bool) {
        rtc.execute { rtcKit in
            rtcKit.enableRescaleAudioVolume(enable)
        }
    }

    public func publishScreen() {
        rtc.execute { rtcKit in
            rtcKit.publishScreen()
        }
    }

    public func unpublishScreen() {
        rtc.execute { rtcKit in
            rtcKit.unpublishScreen()
        }
    }

    public func sendScreenCaptureExtensionMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        rtc.execute { rtcKit in
            rtcKit.sendScreenCaptureExtensionMessage(data)
        }
    }

    /// 更新屏幕共享采集数据类型
    public func updateScreenCapture(_ type: RtcScreenMediaType) {
        rtc.execute { rtcKit in
            rtcKit.updateScreenCapture(type)
        }
    }

    public func setRuntimeParameters(_ parameters: [String: Any]) {
        rtc.execute {
            $0.setRuntimeParameters(parameters)
        }
    }

    public func enablePIPMode(_ enable: Bool) {
        rtc.execute { rtcKit in
            rtcKit.enablePIPMode(enable)
        }
    }

    public func fetchVideoStreamInfo(completion: @escaping (RtcVideoStreamInfo) -> Void) {
        #if RTCBRIDGE_HAS_SDK
        VideoStreamManager.shared.fetchStreamInfo(sessionId: rtc.sessionId, completion: completion)
        #endif
    }

    public func setCustomEncryptor(_ cryptor: RtcCrypting) {
        rtc.execute { rtcKit in
            rtcKit.setCustomEncryptor(cryptor)
        }
    }

    /// RTC新降级
    /// 开启手动降级
    /// 调用时机：引擎创建后，进会前
    public func enablePerformanceAdaption(_ enable: Bool) {
        rtc.execute { rtcKit in
            rtcKit.enablePerformanceAdaption(enable)
        }
    }

    /// 设置降价等级
    /// 取值范围【0， 19】
    public func setPerformanceLevel(_ level: Int) {
        rtc.execute { rtcKit in
            rtcKit.setPerformanceLevel(level)
        }
    }
}

public extension InMeetRtcEngine {
    func addListener(_ listener: RtcListener) {
        rtc.listeners.listeners.addListener(listener)
    }

    func removeListener(_ listener: RtcListener) {
        rtc.listeners.listeners.removeListener(listener)
    }

    func addAsListener(_ listener: RtcActiveSpeakerListener) {
        rtc.listeners.asListeners.addListener(listener)
    }

    func removeAsListener(_ listener: RtcActiveSpeakerListener) {
        rtc.listeners.asListeners.removeListener(listener)
    }

    func addMetadataListener(_ listener: RtcMetadataListener) {
        rtc.listeners.metadataListeners.addListener(listener)
    }

    func addBinaryFrameListener(_ listener: RtcRoomMessageListener) {
        rtc.listeners.roomMessageListeners.addListener(listener)
    }

    func addVideoRendererListener(_ listener: RtcVideoRendererListener) {
        #if RTCBRIDGE_HAS_SDK
        VideoStreamManager.shared.listeners.rendererListenerers.addListener(listener)
        #endif
    }
}

public struct RtcJoinParams {
    public let channelKey: String?
    public let channelName: String
    public let traceId: String
    public let info: String
    public let businessId: String

    public init(channelKey: String?, channelName: String, traceId: String, info: String, businessId: String) {
        self.channelKey = channelKey
        self.channelName = channelName
        self.traceId = traceId
        self.info = info
        self.businessId = businessId
    }
}
