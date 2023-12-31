//
//  RtcCreateParams+Meeting.swift
//  ByteView
//
//  Created by kiri on 2022/9/27.
//

import Foundation
import ByteViewCommon
import ByteViewMeeting
import ByteViewNetwork
import AVFoundation
import LarkMedia
import ByteViewSetting
import ByteViewRtcBridge
import CoreMotion
import SSZipArchive

extension RtcCreateParams {
    init(session: MeetingSession, setting: MeetingSettingManager) {
        var meetInfo: MeetInfo?
        if let info = session.videoChatInfo, info.type == .meet || info.type == .call, let data = info.info.data(using: .utf8) {
            meetInfo = try? JSONDecoder().decode(MeetInfo.self, from: data)
        }
        session.log("create RtcCreateParams with \(meetInfo)")
        self.init(session: session, setting: setting, meetInfo: meetInfo)
    }

    init?(session: MeetingSession, info: VideoChatInfo) {
        #if DEBUG
        /// 有隐私信息，线上不能打印
        session.log("raw MeetInfo = \(info.info)")
        #endif
        guard let setting = session.setting, info.type == .meet || info.type == .call, let data = info.info.data(using: .utf8),
              let meetInfo = try? JSONDecoder().decode(MeetInfo.self, from: data) else {
            return nil
        }

        session.log("create RtcCreateParams with \(meetInfo)")
        self.init(session: session, setting: setting, meetInfo: meetInfo)
    }

    private init(session: MeetingSession, setting: MeetingSettingManager, meetInfo: MeetInfo?) {
        var uid = session.account.deviceId
        if let rtcUid = meetInfo?.userId, rtcUid != uid {
            let rtcJoinID = session.videoChatInfo?.participants.first(withUser: session.account)?.rtcJoinId
            session.loge("rtc rtcUid(\(rtcUid)) != deviceID(\(uid)), participantRtcJoinID: \(rtcJoinID)")
            uid = rtcUid
        }
        let vendorType = session.videoChatInfo?.vendorType ?? session.precheckVendorType

        let rs = setting.rtcSetting
        // 获取最大发布分辨率的短边
        let maxPublishResolution: Int
        let multiResolutionConfig = rs.multiResolutionConfig
        let defaultMaxPublishResolution: Int = 360
        let defaultMaxFrameRate: Int = 15
        let multiResPublishConfig = Display.phone ? multiResolutionConfig.phone.publish : multiResolutionConfig.pad.publish
        let channel = rs.isHDModeEnabled ? multiResPublishConfig.channelHigh ?? multiResPublishConfig.channel : multiResPublishConfig.channel
        maxPublishResolution = channel.map { $0.res }.max() ?? defaultMaxPublishResolution
        let frameRate = channel.map { $0.fps }.max() ?? defaultMaxFrameRate
        let videoSize = CGSize(width: maxPublishResolution * 16 / 9, height: maxPublishResolution)

        let actionProxy = MeetingRtcActionProxy(sessionId: session.sessionId, setting: rs,
                                                storage: session.service?.storage,
                                                audioDevice: session.audioDevice)

        let renderConfig = RtcRenderConfig(viewSizeDebounce: multiResolutionConfig.viewSizeDebounce,
                                           sharedDisplayLink: rs.renderConfig.sharedDisplayLink?.toRtc(),
                                           unsubscribeDelay: rs.renderConfig.unsubscribeDelay?.toRtc(),
                                           proxy: actionProxy)
        let mpConfig = MutePromptConfig(interval: rs.mutePromptConfig.interval, level: rs.mutePromptConfig.level)
        let hostConfig = RtcHostConfig(frontier: rs.hostConfig.frontier, decision: rs.hostConfig.decision,
                                       defaultIps: rs.hostConfig.defaultIps, kaChannel: rs.hostConfig.kaChannel)
        let effectFps = Display.pad ? multiResolutionConfig.pad.effectFps : multiResolutionConfig.phone.effectFps

        let domainConfig = rs.getDomainConfigWith(vendorType: vendorType)

        self.init(rtcAppId: rs.rtcAppId, sessionId: session.sessionId, extensionGroupId: rs.appGroupId,
                  uid: uid, vendorType: vendorType.toRtc(),
                  isVirtualBgCoremlEnabled: rs.isVirtualBgCoremlEnabled,
                  isVirtualBgCvpixelbufferEnabled: rs.isVirtualBgCvpixelbufferEnabled, hostConfig: hostConfig,
                  audioConfig: AudioConfig(session: session),
                  videoCaptureConfig: VideoCaptureConfig(videoSize: videoSize, frameRate: frameRate),
                  mutePromptConfig: mpConfig, effectFrameRateConfig: effectFps.toRtc(),
                  renderConfig: renderConfig, encodeLinkageConfig: rs.encodeLinkageConfig?.toRtc(),
                  extra: rs.extra, domainConfig: domainConfig,
                  activeSpeakerReportInterval: Int(rs.activeSpeakerConfig.reportInterval),
                  actionProxy: actionProxy, fgConfig: rs.fgConfig,
                  adminMediaServerSettings: rs.adminMediaServerSettings,
                  logPath: rs.logPath)
        if let bandwidthParams = rs.bandwidth?.toDicParams() {
            // RTC带宽限制配置
            self.mergeRuntimeParameters(bandwidthParams)
        }

        if let meetInfo = meetInfo {
            self.mergeRuntimeParameters(meetInfo.rtcParameterDict)
            self.userToken = meetInfo.userToken
            self.channelName = meetInfo.meetNumber
        } else {
            self.mergeRuntimeParameters(session.precheckRtcRuntimeParams)
        }
        self.mergeRuntimeParameters(["rtc.service_type": "vc"])
    }
}

private extension RtcCreateParams.AudioConfig {
    init(session: MeetingSession) {
        let isCallKit = session.isCallKit
        let options = isCallKit ? AudioSessionScenario.byteViewCallKitOptions : AudioSessionScenario.byteViewOptions
        self.init(isCallKit: isCallKit, category: AudioSessionScenario.byteViewCategory, options: options, mode: AudioSessionScenario.byteViewMode)
    }
}

final class MeetingRtcActionProxy: RtcActionProxy {
    let sessionId: String
    let isThreadBizMonitorEnabled: Bool
    let clearRtcCacheVersion: String?
    weak var audioDevice: AudioDeviceManager?

    var storage: UserStorage?
    private let logger: Logger
    init(sessionId: String, setting: RtcSetting, storage: UserStorage?, audioDevice: AudioDeviceManager?) {
        self.sessionId = sessionId
        self.logger = Logger.meeting.withContext(sessionId)
        self.isThreadBizMonitorEnabled = setting.perfSampleConfig.isThreadBizMonitorEnabled
        self.clearRtcCacheVersion = setting.clearRtcCacheVersion
        self.storage = storage
        self.audioDevice = audioDevice
        logger.info("init MeetingRtcActionProxy")
    }

    deinit {
        logger.info("deinit MeetingRtcActionProxy")
    }

    func performAction<T>(_ type: RtcActionType, action: () -> T) -> T {
        guard isThreadBizMonitorEnabled else {
            return action()
        }

        let bizScope: ByteViewThreadBizScope = type == .rtc ? ByteViewThreadBizScope_RTC : ByteViewThreadBizScope_Unknown
        let oldScope = byteview_set_current_biz_scope(bizScope)
        defer {
            byteview_set_current_biz_scope(oldScope)
        }
        return action()

    }

    func requestAudioCapturePermission(scene: RtcAudioScene) throws {
        guard let token = scene.toSncToken() else {
            throw SncError.tokenNotFound
        }
        try MicrophoneSncWrapper.startAudioCapture(for: token)
    }

    func requestVideoCapturePermission(scene: RtcCameraScene) throws {
        guard let token = scene.toSncToken() else {
            throw SncError.tokenNotFound
        }
        try CameraSncWrapper.startVideoCapture(for: token)
    }

    func startDeviceMotionUpdatesForCamera(manager: CMMotionManager, to queue: OperationQueue, withHandler handler: @escaping CMDeviceMotionHandler) {
        do {
            try DeviceSncWrapper.startDeviceMotionUpdates(for: .rtcCameraOrientation, manager: manager, to: queue, withHandler: handler)
        } catch {
            Logger.util.warn("Cannot start device motion updates which is disabled by LarkSensitivityControl")
            queue.addOperation {
                handler(nil, error)
            }
        }
    }

    func clearSafeModeCache(_ action: (Bool) -> Void) {
        guard let version = self.clearRtcCacheVersion else {
            action(false)
            return
        }
        if let lastVersion = storage?.string(forKey: .safeModeRtcCache), lastVersion == version {
            action(false)
            return
        }
        action(true)
        storage?.set(version, forKey: .safeModeRtcCache)
    }

    func willCreateInstance() {
        unzipRtcBundle()
    }

    private func unzipRtcBundle() {
        guard let bundlePath = Bundle.main.path(forResource: "ByteRtcSDK", ofType: "bundle"),
              let storage = storage else { return }
        let cacheDir = storage.getAbsPath(root: .caches, relativePath: "")
        let effectPath = cacheDir.appendingPath("effect")
        if effectPath.directoryExists() { return }
        let zipPath = "\(bundlePath)/effect_ios.zip"
        Logger.byteRtc.info("unzip \(zipPath) to \(effectPath.absoluteString)")
        if SSZipArchive.unzipFile(atPath: zipPath, toDestination: cacheDir.absoluteString) != true { return }
    }

    func setInputMuted(_ muted: Bool) {
        audioDevice?.input.setInputMuted(muted)
    }
}

extension RtcAudioScene {
    static let joinChannel = RtcAudioScene(rawValue: "joinChannel")
    static let changeToSystemAudio = RtcAudioScene(rawValue: "changeToSystemAudio")
    static let noaudioEnterPip = RtcAudioScene(rawValue: "noaudioEnterPip")
    static let disconnectPhonecall = RtcAudioScene(rawValue: "disconnectPhonecall")
    static let breakroomTransiton = RtcAudioScene(rawValue: "breakroomTransiton")

    func toSncToken() -> SncToken? {
        switch self {
        case .joinChannel:
            return .joinChannel
        case .changeToSystemAudio:
            return .changeToSystemAudio
        case .noaudioEnterPip:
            return .noaudioEnterPip
        case .disconnectPhonecall:
            return .disconnectPhonecall
        case .breakroomTransiton:
            return .breakroomTransiton
        default:
            return nil
        }
    }
}

extension RtcCameraScene {
    static let callOut = RtcCameraScene(rawValue: "callOut")
    static let lobby = RtcCameraScene(rawValue: "lobby")
    static let prelobby = RtcCameraScene(rawValue: "preLobby")
    static let previewLab = RtcCameraScene(rawValue: "previewLab")
    static let inMeetLab = RtcCameraScene(rawValue: "inMeetLab")
    static let lobbyLab = RtcCameraScene(rawValue: "lobbyLab")
    static let prelobbyLab = RtcCameraScene(rawValue: "preLobbyLab")

    func toSncToken() -> SncToken? {
        switch self {
        case .inMeet:
            return .inMeet
        case .preview:
            return .preview
        case .previewLab:
            return .previewLab
        case .callOut:
            return .callOut
        case .inMeetLab:
            return .inMeetLab
        case .lobby:
            return .lobby
        case .prelobby:
            return .preLobby
        case .lobbyLab:
            return .lobbyLab
        case .prelobbyLab:
            return .preLobbyLab
        default:
            return nil
        }
    }
}

private extension VideoChatInfo.VendorType {
    func toRtc() -> RtcVendorType {
        switch self {
        case .rtc:
            return .rtc
        case .larkRtc:
            return .larkRtc
        case .larkPreRtc:
            return .larkPreRtc
        case .larkRtcTestPre:
            return .testPre
        case .larkRtcTestGauss:
            return .testGauss
        case .larkRtcTest:
            return .test
        default:
            return .unknown
        }
    }
}

/*数据类似{"InfoType":"larkpreRTC","MeetNumber":"6914219071753469953","Passcode":"","UserID":"2603294626430072","Token":"0015b978bab09b27c0034d252c0UwDiP00FAzT1X8OuBWATADY5MTQyMTkwNzE3NTM0Njk5NTMQADI2MDMyOTQ2MjY0MzAwNzIFAAAAw64FYAEAw64FYAIAw64FYAMAw64FYAQAw64FYCAAWEb51QFOjH4CQUnOl+Au4BFO8TPHV82W2Z+q1w+75RE="}
 */
private struct MeetInfo: Decodable, CustomStringConvertible {
    let meetNumber: String
    let passcode: String?
    let userId: String?
    let userToken: String?
    let zak: String?
    let parameter: String?

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        _ = try values.decodeIfPresent(String.self, forKey: .infoType)
        meetNumber = try values.decode(String.self, forKey: .meetNumber)
        passcode = try values.decodeIfPresent(String.self, forKey: .passcode)
        if let userId = try values.decodeIfPresent(String.self, forKey: .userId), !userId.isEmpty, userId != "0" {
            self.userId = userId
        } else {
            self.userId = nil
        }
        userToken = try values.decodeIfPresent(String.self, forKey: .userToken)
        zak = try values.decodeIfPresent(String.self, forKey: .zak)
        parameter = try values.decodeIfPresent(String.self, forKey: .parameter)
    }

    enum CodingKeys: String, CodingKey {
        case infoType = "InfoType"
        case meetNumber = "MeetNumber"
        case passcode = "Passcode"
        case userId = "UserID"
        case userToken = "Token"
        case zak = "Zak"
        case parameter = "Parameter"
    }

    var description: String {
        "MeetInfo(MeetNumber:\(meetNumber), Passcode:\(passcode), UserId:\(userId), Zak:\(zak))"
    }

    var rtcParameterDict: [String: Any]? {
        guard let data = parameter?.data(using: String.Encoding.utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                  return nil
              }
        return dict
    }
}

private extension GetAdminSettingsResponse.Bandwidth {
    func toDicParams() -> [String: Any]? {
        if bandwidthStatus {
            var bandwidthParams = [String: Any]()
            // admin下发的是kpbs, 需要换算成bps传给rtc
            if upstreamBandwidth > 0 {
                bandwidthParams["uplink"] = upstreamBandwidth * 1024
            }
            if downstreamBandwidth > 0 {
                bandwidthParams["downlink"] = downstreamBandwidth * 1024
            }
            if !bandwidthParams.isEmpty {
                return ["rtc.user_limit_bandwidth": bandwidthParams]
            }
        }
        return nil
    }
}

private extension SharedDisplayLinkConfig {
    func toRtc() -> RtcRenderConfig.SharedDisplayLinkConfig {
        return .init(enabled: enabled, fpsList: fpsList, maxFps: maxFps)
    }
}

private extension UnsubscribeDelayConfig {
    func toRtc() -> RtcRenderConfig.UnsubscribeDelayConfig {
        return .init(maxStreamCount: maxStreamCount, video: video, screen: screen)
    }
}

private extension EffectFrameRateConfig {
    func toRtc() -> RtcCreateParams.EffectFrameRateConfig {
        return .init(virtualBackgroundFps: virtualBackgroundFps, animojiFps: animojiFps, filterFps: filterFps, beautyFps: beautyFps, mixFilterBeautyFps: mixFilterBeautyFps, mixOtherFps: mixOtherFps)
    }
}

private extension CameraEncodeLinkageConfig {
    func toRtc() -> RtcCreateParams.CameraEncodeLinkageConfig {
        return .init(levelsCount: levelsCount, smallViewBaseIndex: smallViewBaseIndex, bigViewPixels: bigViewPixels, bigViewBaseIndex: bigViewBaseIndex, singleEffectLevel: singleEffectLevel, groupEffectLevel: groupEffectLevel, ecoModeLevel: ecoModeLevel)
    }
}
