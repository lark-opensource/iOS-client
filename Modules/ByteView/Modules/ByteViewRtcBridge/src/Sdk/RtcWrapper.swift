//
//  RtcWrapper.swift
//  ByteView
//
//  Created by kiri on 2022/8/12.
//

import Foundation
import VolcEngineRTC
import EffectPlatformSDK
import ByteViewCommon

/// 封装ByteRtcMeetingEngineKit，隐藏VolcEngineRTC
final class RtcWrapper: RtcInstance, CustomStringConvertible {
    let instanceId: String
    let logger: Logger
    private let rtcKit: ByteRtcMeetingEngineKit
    private let handler: RtcDelegateWrapperProxy
    private let handlerProxy: RtcObjcProxy
    private(set) var isDestroyed = false
    private var rtcCryptor: RtcSdkCryptor?
    private var shouldFixMute: Bool = true
    private var clientRole: RtcClientRole?

    private(set) var createParams: RtcCreateParams

    private var isVirtualBgCoremlEnabled: Bool { createParams.isVirtualBgCoremlEnabled }
    private var isVirtualBgCvpixelbufferEnabled: Bool { createParams.isVirtualBgCvpixelbufferEnabled }

    let description: String

    /// 当前effect状态
    @RwAtomic var effectStatus: RtcCameraEffectStatus = .none
    /// 当前effect设置值
    var effectValues: [RtcCameraEffectType: Any] = [:]
    var loaclRes: Int = 480
    var performanceLevel: Int = 0

    private static let instanceIdGenerator = UUIDGenerator()
    init(params: RtcCreateParams, listeners: RtcListeners) {
        let instanceId = Self.instanceIdGenerator.generate()
        let sessionId = params.sessionId
        self.instanceId = instanceId
        self.createParams = params
        self.description = "[Rtc(\(instanceId))][\(params.sessionId)]"
        let logger = Logger.byteRtc.withContext("\(params.sessionId)-\(instanceId)").withTag(self.description)
        self.logger = logger
        logger.info("start init RtcWrapper")

        // 设置log路径
        ByteRtcMeetingEngineKit.setLogPath(params.logPath)

        let proxy = params.actionProxy
        proxy.willCreateInstance()
        let audioConfig = params.audioConfig
        logger.debug("setCallMode: \(audioConfig)")
        ByteRtcMeetingEngineKit.setCallMode(audioConfig.isCallKit, category: audioConfig.category, options: audioConfig.options, mode: audioConfig.mode)

        // 设置 rtc fg
        if let featureGating = params.fgConfig {
            logger.info("setRtcFGConfig: \(featureGating)")
            ByteRtcMeetingEngineKit.setRtcFGConfig(featureGating)
        }

        if let enablePrivateMedia = params.adminMediaServerSettings {
            logger.info("setEnableKAMedia: \(enablePrivateMedia)")
            ByteRtcMeetingEngineKit.setEnableKAMedia(enablePrivateMedia)
        } else {
            logger.info("rtc setEnableKAMedia use default value")
        }

        let version = ByteRtcMeetingEngineKit.getSdkVersion()
        let startTime = CACurrentMediaTime()
        let delegate = RtcDelegateWrapper(sessionId: sessionId,
                                          logger: logger.withTag("[RtcDelegate(\(instanceId))][\(params.sessionId)]"),
                                          listeners: listeners)
        let rtcDelegate = RtcObjcProxy(target: delegate, handler: { proxy.performAction(.rtcDelegate, action: $0) })
        self.handler = RtcDelegateWrapperProxy(delegate, proxy: proxy)
        self.handlerProxy = rtcDelegate
        let parameters = params.extra.merging(params.runtimeParameters, uniquingKeysWith: { $1 }).merging(params.domainConfig, uniquingKeysWith: { $1 })
        logger.info("ByteRtcMeetingEngineKit.sharedEngine() start, version = \(version), with parameters = \(parameters)")
        self.rtcKit = ByteRtcMeetingEngineKit.sharedEngine(withAppId: params.rtcAppId, delegate: rtcDelegate, parameters: parameters)
        let duration = CACurrentMediaTime() - startTime
        logger.info("ByteRtcMeetingEngineKit.sharedEngine() finished, duration = \(Util.formatTime(duration))")

        // 特效相关
        logger.info("setEffectResourceFinder")
        rtcKit.setEffectResourceFinder(IESEffectManager().getResourceFinder())
        setEffectABConfig()  // 一定要在effect实例创建之前调用

        logger.info("enableVolumeIndicator, interval: \(params.activeSpeakerReportInterval)")
        let config = ByteRTCAudioPropertiesConfig()
        config.interval = params.activeSpeakerReportInterval
        rtcKit.enableAudioPropertiesReport(config)

        let mpConfig = params.mutePromptConfig
        logger.info("enableLocalVolumeIndicator, interval: \(mpConfig.interval), audioLvl: \(mpConfig.level)")
        rtcKit.enableLocalVolumeIndicator(mpConfig.interval, audioLvl: mpConfig.level)

        logger.info("setExtensionConfig: \(params.extensionGroupId)")
        rtcKit.setExtensionConfig(params.extensionGroupId)

        delegate.rtc = self
        logger.info("init RtcWrapper, parameters = \(parameters)")
    }

    deinit {
        logger.info("deinit RtcWrapper")
        assert(isDestroyed, "must destory RtcWrapper before deinit!")
        if !isDestroyed {
            // 兜底，不应该走到这里
            destroy()
        }
    }

    func destroy() {
        if isDestroyed { return }
        isDestroyed = true
        rtcKit.delegate = nil
        removeCustomEncryptor()
        logger.info("ByteRtcMeetingEngineKit.destroy() start")
        let startTime = CACurrentMediaTime()
        ByteRtcMeetingEngineKit.destroy()
        let duration = CACurrentMediaTime() - startTime
        logger.info("ByteRtcMeetingEngineKit.destroy() finished, duration = \(Util.formatTime(duration))")
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
        self.updateParams(params)
    }

    private func updateParams(_ params: RtcCreateParams) {
        let audioConfig = params.audioConfig
        logger.info("setCallMode: \(audioConfig)")
        ByteRtcMeetingEngineKit.setCallMode(audioConfig.isCallKit, category: audioConfig.category, options: audioConfig.options, mode: audioConfig.mode)

        var runtimeParameters = params.runtimeParameters
        if self.createParams.vendorType != params.vendorType {
            runtimeParameters = params.runtimeParameters.merging(params.domainConfig, uniquingKeysWith: { $1 })
        }
        logger.info("update runtimeParameters:\(runtimeParameters)")
        // runtimeParameters update
        setRuntimeParameters(runtimeParameters)

        self.createParams = params
    }

    // MARK: - Core Methods
    static func enableAUPreStart(_ needPreStart: Bool) {
        Logger.byteRtc.info("enableAUPreStart \(needPreStart)")
        ByteRtcMeetingEngineKit.enableAUPreStart(needPreStart)
    }

    func setClientRole(_ role: RtcClientRole) {
        if role != self.clientRole {
            logger.info("setClientRole \(role)")
            self.clientRole = role
            rtcKit.setClientRole(role.toRtc())
        }
    }

    func enableSimulcastMode(_ isEnabled: Bool) {
        logger.info("enableSimulcastMode \(isEnabled)")
        rtcKit.enableSimulcastMode(isEnabled)
    }

    func setVideoCaptureConfig(videoSize: CGSize, frameRate: Int) {
        logger.info("setVideoCaptureConfig: videoSize = \(videoSize), frameRate = \(frameRate)")
        let config = ByteRTCVideoCaptureConfig()
        config.videoSize = videoSize
        config.preference = .mannal
        config.frameRate = frameRate
        rtcKit.setVideoCaptureConfig(config)
    }

    func setVideoEncoderConfig(channel: [RtcVideoEncoderConfig], main: [RtcVideoEncoderConfig]) {
        logger.info("setVideoEncoderConfig")
        rtcKit.setVideoEncoderConfig(channel.map({ $0.toRtc() }), mainSolutions: main.map({ $0.toRtc() }))
    }

    func setScreenVideoEncoderConfig(_ config: RtcVideoEncoderConfig) {
        logger.info("setScreenVideoEncoderConfig")
        rtcKit.setScreenVideoEncoderConfig(config.toRtcScreen())
    }

    /// 设置simulcast参数，需要指定定每组分辨率的宽、高、帧率、码率
    func forceSetVideoProfiles(_ descriptions: [RtcVideoStreamDescription]) {
        logger.info("forceSetVideoProfiles")
        rtcKit.forceSetVideoProfiles(descriptions.map({ $0.toRtc() }))
    }

    func setBusinessId(_ businessId: String?) {
        logger.info("setBusinessId: \(businessId ?? "")")
        rtcKit.setBusinessId(businessId)
    }

    func joinChannel(byKey channelKey: String?, channelName: String, info: String?, traceId: String) {
        logger.info("joinChannel start")
        let uid = self.createParams.uid
        handler.onJoinChannel(uid: uid)
        rtcKit.setVideoSourceType(.internal, with: .main)
        let startTime = CACurrentMediaTime()
        let ret = rtcKit.joinChannel(byKey: channelKey, channelName: channelName, info: info, uid: uid, traceid: traceId)
        let duration = CACurrentMediaTime() - startTime
        logger.info("joinChannel finished, ret = \(ret), duration = \(Util.formatTime(duration)), info: \(info), uid: \(uid), traceId: \(traceId)")
    }

    func leaveChannel() {
        logger.info("leaveChannel start")
        rtcKit.stopAudioCapture()
        rtcKit.stopVideoCapture()
        rtcKit.disableLocalVideo()
        let startTime = CACurrentMediaTime()
        let ret = rtcKit.leaveChannel()
        let duration = CACurrentMediaTime() - startTime
        logger.info("leaveChannel finished, ret = \(ret), duration = \(Util.formatTime(duration))")
    }

    // MARK: - Core Audio Methods

    /**
     静音/开启本地音频流

     该方法静音本地音频流/取消静音。调用该方法后，房间中的其他用户会收到didAudioMuted的回调。
     */
    func muteLocalAudioStream(_ muted: Bool) {
        logger.info("muteLocalAudioStream \(muted)")
        rtcKit.muteLocalAudioStream(muted)
    }

    func isMuteLocalAudio() -> Bool {
        let ret = rtcKit.isMuteLocalAudio()
        logger.info("isMuteLocalAudio = \(ret)")
        return ret
    }

    func muteAudioPlayback(_ muted: Bool) {
        logger.info("muteAudioPlayback \(muted)")
        rtcKit.muteAudioPlayback(muted ? .on : .off)
    }

    func setInputMuted(_ muted: Bool) {
        logger.info("setInputMuted, mute: \(muted)")
        guard shouldInputMuted(muted) else { return }
        if #available(iOS 17, *) {
            proxy.setInputMuted(muted)
        }
        rtcKit.setAudioUnitProperty(ByteRtcAUPropertyMuteOutput, param: muted)
    }

    private func shouldInputMuted(_ muted: Bool) -> Bool {
        if createParams.audioConfig.isCallKit {
            if #available(iOS 17, *), shouldFixMute {
                shouldFixMute = false
                // 只支持 unmute
                if muted {
                    logger.info("skip setInputMuted, mute: \(muted) when fixing mute")
                    return false
                }
            } else {
                logger.info("skip setInputMuted, mute: \(muted) on callkit")
                return false
            }
        }
        return true
    }

    func startAudioCapture(scene: RtcAudioScene) throws {
        logger.info("startAudioCapture")
        do {
            try proxy.requestAudioCapturePermission(scene: scene)
            rtcKit.startAudioCapture()
        } catch {
            logger.error("startAudioCapture failed, requestAudioCapturePermission error = \(error)")
            throw error
        }
    }

    /**
     停止麦克风音频采集
     - 停止后调用muteLocalAudio/MuteLocalAudioStream无效
     */
    func stopAudioCapture() {
        logger.info("stopAudioCapture")
        rtcKit.stopAudioCapture()
    }

    // MARK: - Core Video Methods
    func setLocalVideoSink(_ index: ByteRTCStreamIndex, withSink videoSink: ByteRTCVideoSinkProtocol?,
                           with requiredFormat: ByteRTCVideoSinkPixelFormat) {
        logger.info("setLocalVideoSink, index: \(index.rawValue)")
        rtcKit.setLocalVideoSink(index, withSink: videoSink, with: requiredFormat)
    }

    func setRemoteVideoSink(_ streamKey: ByteRTCRemoteStreamKey, withSink videoSink: ByteRTCVideoSinkProtocol?,
                            with requiredFormat: ByteRTCVideoSinkPixelFormat) {
        logger.info("setRemoteVideoSink, streamKey: \(streamKey.userId), \(streamKey.streamIndex.rawValue)")
        rtcKit.setRemoteVideoSink(streamKey, withSink: videoSink, with: requiredFormat)
    }

    func startVideoCapture(scene: RtcCameraScene) throws {
        logger.info("startVideoCapture, with enableLocalVideo")
        do {
            try proxy.requestVideoCapturePermission(scene: scene)
            rtcKit.enableLocalVideo()
            rtcKit.startVideoCapture()
            // startVideoCapture检测是否开启了特效,并进行帧率降级
            updateEffectFrameRateIfNeeded()
            logger.info("startVideoCapture success for scene \(scene)")
            handler.didStartVideoCapture()
        } catch {
            logger.error("startVideoCapture failed for scene \(scene), error = \(error)")
            throw error
        }
    }

    func stopVideoCapture() {
        logger.info("stopVideoCapture")
        rtcKit.stopVideoCapture()
        rtcKit.disableLocalVideo()
        handler.didStopVideoCapture()
    }

    func muteLocalVideoStream(_ muted: Bool) {
        logger.info("muteLocalVideoStream \(muted)")
        rtcKit.muteLocalVideoStream(muted)
    }

    func isMuteLocalVideo() -> Bool {
        let ret = rtcKit.isMuteLocalVideo()
        logger.info("isMuteLocalVideo, ret = \(ret)")
        return ret
    }

    /// 切换前置/后置摄像头
    func switchCamera(isFront: Bool) {
        logger.info("switchCamera, isFront: \(isFront)")
        rtcKit.switchCamera(isFront ? .front : .back)
    }

    func enablePIPMode(_ enable: Bool) {
        logger.info("enablePIPMode, enable: \(enable)")
        rtcKit.enablePIPMode(enable)
    }

    // MARK: - Subscribe Controller Methods

    func subscribeStream(_ streamId: String, key: RtcStreamKey, subscribeConfig config: RtcSubscribeConfig) {
        let info = config.toRtc()
        logger.info("subscribeStream, streamId: \(streamId), uid: \(key.uid), hasBaseline: \(config.videoBaseline != nil)")
        if let videoBaseline = config.videoBaseline?.toRtc() {
            rtcKit.subscribeStream(streamId, subscribeConfig: info, videoBaseline: videoBaseline)
        } else {
            rtcKit.subscribeStream(streamId, subscribeConfig: info)
        }
        self.handler.didSubscribeStream(streamId, key: key, config: config)
    }

    func unsubscribeStream(_ streamId: String, key: RtcStreamKey, subscribeConfig config: RtcSubscribeConfig?) {
        logger.info("unsubscribeStream, streamId: \(streamId), uid: \(key.uid)")
        let info = SubscribeConfig()
        info.subscribeVideo = false
        info.subscribeAudio = true
        info.videoIndex = 0
        rtcKit.subscribeStream(streamId, subscribeConfig: info)
        self.handler.didUnsubscribeStream(streamId, key: key, config: config)
    }

    // MARK: - External Video Data

    /// 【屏幕共享外部采集】发布本地共享视频流（仅用于屏幕共享外部采集，内部采集请勿调用）
    func publishScreen() {
        logger.info("publishScreen")
        rtcKit.publishScreen()
    }

    /// 【屏幕共享外部采集】取消发布本地共享视频流（仅用于屏幕共享外部采集，内部采集请勿调用）
    func unpublishScreen() {
        logger.info("unpublishScreen")
        rtcKit.unpublishScreen()
    }

    func sendScreenCaptureExtensionMessage(_ messsage: Data) {
        logger.info("sendScreenCaptureExtensionMessage: \(messsage)")
        rtcKit.sendScreenCaptureExtensionMessage(messsage)
    }

    func updateScreenCapture(_ type: RtcScreenMediaType) {
        logger.info("updateScreenCapture: \(type)")
        rtcKit.updateScreenCapture(type.toRtc())
    }

    func setPublishChannel(_ channelName: String) {
        let ret = Int(rtcKit.setPublishChannel(channelName))
        logger.info("setPublishChannel: \(channelName), ret = \(ret)")
    }

    func setSubChannels(_ channelIds: [String]) {
        let ret = Int(rtcKit.setSubChannels(channelIds.map({
            let info = ByteSubChannelsInfo()
            info.channelName = $0
            info.volumeScale = -1 // 暂不支持外部控制，端上统一设为-1，待支持后换成具体值
            return info
        })))
        logger.info("setSubChannels: \(channelIds), ret = \(ret)")
    }

    func enableRescaleAudioVolume(_ enable: Bool) {
        rtcKit.enableRescaleAudioVolume(enable)
        logger.info("enableRescaleAudioVolume, enable = \(enable)")
    }

    func joinBreakDownRoom(_ groupName: String, subMain: Bool) {
        let ret = Int(rtcKit.joinBreakDownRoom(groupName, subMain: subMain))
        logger.info("joinBreakDownRoom, groupName: \(groupName), subMain: \(subMain), ret = \(ret)")
    }

    func leaveBreakDownRoom() {
        let ret = Int(rtcKit.leaveBreakDownRoom())
        logger.info("leaveBreakDownRoom, ret = \(ret)")
    }

    func setRemoteUserPriority(_ uid: RtcUID, priority: RtcRemoteUserPriority) {
        logger.info("setRemoteUserPriority, uid: \(uid), priority: \(priority)")
        rtcKit.setRemoteUserPriority(uid.id, priority: priority.toRtc())
    }

    func setChannelProfile(_ channelProfile: RtcMeetingChannelProfileType) {
        logger.info("setChannelProfile \(channelProfile)")
        rtcKit.setChannelProfile(channelProfile.toRtc())
    }

    // MARK: - Audio Mix Related

    func startAudioMixing(_ soundId: Int32, filePath: String, loopback: Bool, playCount: Int) -> Int {
        guard let mixManager = rtcKit.getAudioMixingManager() else {
            return -1
        }
        let mixConfig = ByteRTCAudioMixingConfig()
        mixConfig.playCount = playCount
        mixConfig.type = loopback ? .playout : .playoutAndPublish
        mixConfig.position = 0
        mixManager.startAudioMixing(soundId, filePath: filePath, config: mixConfig)
        logger.info("startAudioMixing, soundId: \(soundId), loopback: \(loopback), playCount: \(playCount)")
        return 0
    }

    func stopAudioMixing(_ soundId: Int32) {
        guard let mixManager = rtcKit.getAudioMixingManager() else {
            return
        }
        mixManager.stopAudioMixing(soundId)
        logger.info("stopAudioMixing, soundId: \(soundId)")
    }

    // MARK: - Effect Methods
    private func backgroundResPath(isBlur: Bool) -> String? {
        if isVirtualBgCoremlEnabled {
            let cachedList = EffectPlatform.cachedEffects(ofPanel: CoremlConfig.coremlPanel, category: CoremlConfig.coremlCategory).categoryEffects.effects
            let mode = cachedList.first {
                isBlur ? ($0.resourceID == CoremlConfig.coremlBlurResourceID || $0.resourceID == CoremlConfig.coremlBlurLarkResourceID) : ($0.resourceID == CoremlConfig.coremlBgResourceID || $0.resourceID == CoremlConfig.coremlBgLarkResourceID)
            }
            if let mode = mode, mode.downloaded, !mode.filePath.isEmpty {
                logger.info("background coreml name: \(mode.effectName), path: \(mode.filePath)")
                return mode.filePath
            }
        }
        let effectBuiltinInfo: ByteRtcBuiltInResourceInfo = ByteRtcMeetingEngineKit.getEffectBuiltInResourceInfo()
        logger.info("background inner path path: \(effectBuiltinInfo.bgCpuResPath)")
        return isBlur ? effectBuiltinInfo.blurCpuResPath : effectBuiltinInfo.bgCpuResPath
    }

    func setEffectABConfig() {
        logger.info("setEffectABConfig coremlEnabled \(isVirtualBgCoremlEnabled), CvpixelbufferEnabled \(isVirtualBgCvpixelbufferEnabled)")
        if isVirtualBgCoremlEnabled && isVirtualBgCvpixelbufferEnabled {
            var enableNewAlgorithmSystemNativeBuffer = false  // false为开
            var enableAlgorithmGpuResizeWithBuffer = true
            var enablePerformanceOptInTerminalAndGeneralEffectFeature = true

            withUnsafeMutablePointer(to: &enableNewAlgorithmSystemNativeBuffer) { pointer in
                rtcKit.setEffectABConfig(CoremlConfig.enable_new_algorithm_system_native_buffer, value: pointer, param: 0)
            }

            withUnsafeMutablePointer(to: &enableAlgorithmGpuResizeWithBuffer) { pointer in
                rtcKit.setEffectABConfig(CoremlConfig.enable_algorithm_gpu_resize_with_buffer, value: pointer, param: 0)
            }

            withUnsafeMutablePointer(to: &enablePerformanceOptInTerminalAndGeneralEffectFeature) { pointer in
                rtcKit.setEffectABConfig(CoremlConfig.enable_performance_opt_in_terminal_and_general_effect_feature, value: pointer, param: 0)
            }
        }
    }

    /// 背景虚化开关
    func enableBackgroundBlur(_ isEnabled: Bool) {
        guard let path = backgroundResPath(isBlur: true) else {
            logger.error("enableBackgroundBlur, respath isEmpty")
            return
        }
        logger.info("enableBackgroundBlur \(isEnabled)")
        self.effectValues[.virtualbg] = isEnabled ? "backgroundBlur" : ""
        self.updateEffectStatusForType(.virtualbg)
        let fetchInfo = ByteRtcFetchEffectInfo()
        fetchInfo.resPath = path
        fetchInfo.panel = "fake-matting"
        rtcKit.enableBackgroundBlur(withEffectResInfo: isEnabled, effectResInfo: fetchInfo) //rtcKit.enableBackgroundBlur(isEnabled)
    }

    func setBackgroundImage(_ filePath: String) {
        guard let path = backgroundResPath(isBlur: false) else {
            logger.error("setBackgroundImage, respath isEmpty")
            return
        }
        logger.info("setBackgroundImage, filePath isEmpty = \(filePath.isEmpty)")
        self.effectValues[.virtualbg] = filePath
        self.updateEffectStatusForType(.virtualbg)
        let fetchInfo = ByteRtcFetchEffectInfo()
        fetchInfo.resPath = path
        fetchInfo.panel = "fake-matting"
        rtcKit.setBackgroundImageWithEffectResInfo(filePath, bgImgId: 0, effectResInfo: fetchInfo) //rtcKit.setBackgroundImage(filePath)
    }

    func setDeviceOrientation(_ orientation: Int) {
        logger.info("setDeviceOrientation \(orientation)")
        rtcKit.setDeviceOrientation(orientation)
    }

    func applyEffect(_ effectRes: RtcFetchEffectInfo, with type: RtcEffectType, contextId: String,
                     cameraEffectType: RtcCameraEffectType) {
        logger.info("applyEffect, res = (\(effectRes.resId),\(effectRes.panel),\(effectRes.category)), type = \(type), cameraEffectType = \(cameraEffectType)")
        if cameraEffectType == .filter || cameraEffectType == .animoji {
            self.effectValues[cameraEffectType] = effectRes
        } else if cameraEffectType == .retuschieren {
            var restuschierenStatus = self.effectValues[.retuschieren] as? [String: NSNumber] ?? [:]
            zip(effectRes.tags, effectRes.params).forEach { restuschierenStatus[$0] = $1 }
            self.effectValues[.retuschieren] = restuschierenStatus
        }
        self.updateEffectStatusForType(cameraEffectType)
        rtcKit.applyEffect(effectRes.toRtc(), with: type.toRtc(), withId: contextId)
    }

    func cancelEffect(_ panel: String, cameraEffectType: RtcCameraEffectType) {
        logger.info("cancelEffect, panel: \(panel)")
        if cameraEffectType == .filter || cameraEffectType == .animoji {
            self.effectValues.removeValue(forKey: cameraEffectType)
        }
        self.updateEffectStatusForType(cameraEffectType)
        rtcKit.cancelEffect(panel)
    }

    // MARK: - Rtm

    func login(_ token: String, uid: String) {
        logger.info("login, uid: \(uid)")
        rtcKit.login(token, uid: uid)
    }

    func logout() {
        logger.info("logout")
        rtcKit.logout()
    }

    func setServerParams(_ signature: String, url: String) {
        logger.info("setServerParams")
        rtcKit.setServerParams(signature, url: url)
    }

    @discardableResult
    func sendServerBinaryMessage(_ message: Data) -> Int64 {
        let ret = rtcKit.sendServerBinaryMessage(message)
        logger.info("sendServerBinaryMessage, ret = \(ret), message len = \(message.count)")
        return ret
    }

    // MARK: - EncodedVideo

    func setVideoSourceType(_ type: RtcVideoSourceType, with streamIndex: RtcStreamIndex) {
        logger.info("setVideoSourceType, type: \(type), streamIndex: \(streamIndex)")
        rtcKit.setVideoSourceType(type.toRtc(), with: streamIndex.toRtc())
    }

    // MARK: - Multi transport

    func setCellularEnhancement(_ config: RtcCellularEnhancementConfig) {
        logger.info("setCellularEnhancement, config: \(config)")
        rtcKit.setCellularEnhancement(config.toRtc())
    }

    func enablePerformanceAdaption(_ enable: Bool) {
        logger.info("enablePerformanceAdaption: \(enable)")
        rtcKit.setRuntimeParameters(["rtc.performance_adaption_strategy": ["enable": enable]])
    }

    func updateLocalVideoRes(_ res: Int) {
        guard res != loaclRes else { return }
        logger.info("updateLocalVideoRes: \(res)")
        self.loaclRes = res
        updateEncodeLinkageIndex()
    }

    func setPerformanceLevel(_ level: Int) {
        guard level != performanceLevel else { return }
        logger.info("setPerformanceLevel: \(level)")
        rtcKit.setRuntimeParameters(["rtc.performance_level": ["level": level]])
        self.performanceLevel = level
        updateEncodeLinkageIndex()
    }

    func setRuntimeParameters(_ parameters: [String: Any]) {
        logger.info("setRuntimeParameters, count: \(parameters.count)")
        rtcKit.setRuntimeParameters(parameters)
    }

    func setCustomEncryptor(_ cryptor: RtcCrypting) {
        logger.info("setCustomEncryptor \(cryptor)")
        removeCustomEncryptor()
        self.rtcCryptor = RtcSdkCryptor(cryptor: cryptor)
        self.rtcCryptor?.setToEngine(rtcKit)
    }

    func removeCustomEncryptor() {
        if let rtcCryptor = self.rtcCryptor {
            logger.info("removeCustomEncryptor \(rtcCryptor)")
            rtcCryptor.remove(fromEngine: rtcKit)
            self.rtcCryptor = nil
        }
    }

    private func updateEffectStatusForType(_ type: RtcCameraEffectType) {
        var newStatus = self.effectStatus
        if isEffectOn(type) {
            newStatus.insert(type.effectStatus)
        } else {
            newStatus.remove(type.effectStatus)
        }

        let statusDes = effectStatusDescription(newStatus)
        logger.info("Current effect status: \(statusDes.isEmpty ? "None" : statusDes)")

        if newStatus != self.effectStatus {
            let oldStatus = self.effectStatus
            self.effectStatus = newStatus
            RtcInternalListeners.forEach { $0.onEffectStatusChanged(newStatus, oldValue: oldStatus) }
            updateEffectFrameRate()
        }
    }

    private func updateEffectFrameRateIfNeeded() {
        guard self.effectStatus != .none else { return }
        updateEffectFrameRate()
    }

    private func updateEffectFrameRate() {
        if createParams.encodeLinkageConfig != nil {
            updateEncodeLinkageIndex()
            return
        }

        let effectFrameRateConfig = createParams.effectFrameRateConfig
        var frameRate: Int?
        switch self.effectStatus {
        case .none:
            frameRate = nil
        case .virtualbg:
            frameRate = effectFrameRateConfig.virtualBackgroundFps
        case .animoji:
            frameRate = effectFrameRateConfig.animojiFps
        case .filter:
            frameRate = effectFrameRateConfig.filterFps
        case .retuschieren:
            frameRate = effectFrameRateConfig.beautyFps
        case .filterAndRetuschieren:
            frameRate = effectFrameRateConfig.mixFilterBeautyFps
        default:
            frameRate = effectFrameRateConfig.mixOtherFps
        }
        let config = createParams.videoCaptureConfig
        guard let frameRate = frameRate else {
            logger.info("ByteRTCVideoCaptureConfig reset: \(config.videoSize) \(config.frameRate)")
            setVideoCaptureConfig(videoSize: config.videoSize, frameRate: config.frameRate)
            return
        }
        guard frameRate < config.frameRate else {
            logger.info("ByteRTCVideoCaptureConfig skip")
            return
        }
        logger.info("ByteRTCVideoCaptureConfig update: \(config.videoSize) \(frameRate)")
        setVideoCaptureConfig(videoSize: config.videoSize, frameRate: frameRate)
    }

    private func updateEncodeLinkageIndex() {
        guard let index = createParams.encodeLinkageConfig?.indexFor(res: loaclRes, performanceLevel: performanceLevel, effectStatus: self.effectStatus) else {
            return
        }
        logger.info("updateEncodeLinkageIndex: \(index)")
        rtcKit.setRuntimeParameters(["rtc.performance_level": ["capture_level": index]])
    }

    private func isEffectOn(_ type: RtcCameraEffectType) -> Bool {
        guard let status = self.effectValues[type] else { return false }
        switch type {
        case .virtualbg:
            guard let status = status as? String else { return false}
            return !status.isEmpty
        case .filter:
            guard let info = status as? RtcFetchEffectInfo else { return false }
            for value in info.params {
                if value.intValue != 0 {
                    return true
                }
            }
        case .retuschieren:
            guard let status = status as? [String: NSNumber] else { return false }
            for value in status.values {
                if value.intValue != 0 {
                    return true
                }
            }
        case .animoji:
            return true
        }
        return false
    }

    private func effectStatusDescription(_ status: RtcCameraEffectStatus) -> String {
        var description = ""
        if status.contains(.virtualbg),
           let info = self.effectValues[.virtualbg] as? String {
            description += "Virtual background: \(info) | "
        }
        if status.contains(.animoji),
           let info = self.effectValues[.animoji] as? RtcFetchEffectInfo {
            description += "Animoji: \(info.resId) | "
        }
        if status.contains(.filter),
           let info = self.effectValues[.filter] as? RtcFetchEffectInfo {
            description += "Filter: \(info.resId)"
            if let value = info.params.first {
                description += ", value: \(value.intValue)"
            }
            description += " | "
        }
        if status.contains(.retuschieren),
           let info = self.effectValues[.retuschieren] as? [String: NSNumber] {
            description += "Retuschieren: "
            for (key, value) in info {
                description += "\(key): \(value.intValue), "
            }
        }
        return description
    }

    private enum RtcReuseError: String, Error, CustomStringConvertible {
        case invalidAppId
        case invalidUid
        case invalidSessionId
        case isDestroyed

        var description: String { "RtcReuseError.\(rawValue)" }
    }
}

private extension RtcAUProperty {
    func toRtc() -> ByteRtcAUProperty {
        switch self {
        case .bypassVoiceProcessing:
            return ByteRtcAUPropertyBypassVoiceProcessing
        case .muteOutput:
            return ByteRtcAUPropertyMuteOutput
        case .voiceProcessingEnableAGC:
            return ByteRtcAUPropertyVoiceProcessingEnableAGC
        }
    }
}

private extension RtcScreenMediaType {
    func toRtc() -> ByteRTCScreenMediaType {
        switch self {
        case .videoOnly:
            return .videoOnly
        case .audioOnly:
            return .audioOnly
        case .videoAndAudio:
            return .videoAndAudio
        }
    }
}

private extension RtcRemoteUserPriority {
    func toRtc() -> ByteRtcRemoteUserPriority {
        switch self {
        case .low:
            return ByteRtcRemoteUserPriorityLow
        case .medium:
            return ByteRtcRemoteUserPriorityMedium
        case .high:
            return ByteRtcRemoteUserPriorityHigh
        }
    }
}

private extension RtcMeetingChannelProfileType {
    func toRtc() -> ByteRtcMeetingChannelProfileType {
        switch self {
        case .vc:
            return ByteRtcMeetingChannelProfileTypeVC
        case .share1v1:
            return ByteRtcMeetingChannelProfileTypeShare1V1
        }
    }
}

private extension RtcClientRole {
    func toRtc() -> ByteRtcClientRole {
        switch self {
        case .broadcaster:
            return .clientRole_Broadcaster
        case .audience:
            return .clientRole_Silent_Audience
        }
    }
}

private extension RtcVideoEncoderConfig {
    func toRtc() -> ByteRTCVideoEncoderConfig {
        let config = ByteRTCVideoEncoderConfig()
        config.width = width
        config.height = height
        config.frameRate = frameRate
        config.maxBitrate = maxBitrate
        return config
    }

    func toRtcScreen() -> ByteRTCVideoEncoderConfig {
        let config = self.toRtc()
        config.encoderPreference = .maintainFramerate
        return config
    }
}

private extension RtcVideoStreamDescription {
    func toRtc() -> VideoStreamDescription {
        let des = VideoStreamDescription()
        des.videoSize = videoSize
        des.frameRate = frameRate
        des.maxKbps = maxKbps
        des.encoderPreference = encoderPreference.toRtc()
        return des
    }
}

private extension RtcVideoEncoderPreference {
    func toRtc() -> ByteVideoEncoderPreference {
        switch self {
        case .disabled:
            return .preferDisabled
        case .maintainFramerate:
            return .preferMaintainFramerate
        case .maintainQuality:
            return .preferMaintainQuality
        case .balance:
            return .preferBalance
        }
    }
}

private extension RtcVideoSourceType {
    func toRtc() -> ByteRTCVideoSourceType {
        switch self {
        case .internal:
            return .internal
        }
    }
}

private extension RtcStreamIndex {
    func toRtc() -> ByteRTCStreamIndex {
        switch self {
        case .main:
            return .main
        case .screen:
            return .screen
        }
    }
}

private extension RtcCellularEnhancementConfig {
    func toRtc() -> ByteRTCMediaTypeEnhancementConfig {
        let config = ByteRTCMediaTypeEnhancementConfig()
        config.enhanceAudio = enhanceAudio
        config.enhanceVideo = enhanceVideo
        config.enhanceScreenAudio = enhanceScreenAudio
        config.enhanceScreenVideo = enhanceScreenVideo
        return config
    }
}

private extension RtcSubscribeConfig {
    func toRtc() -> SubscribeConfig {
        let config = SubscribeConfig()
        config.subscribeVideo = true
        config.subscribeAudio = true
        config.framerate = self.framerate
        config.width = self.width
        config.height = self.height
        config.videoIndex = self.videoIndex
        return config
    }
}

extension RtcSubscribeVideoBaseline {
    func toRtc() -> ByteRTCSubscribeVideoBaseline {
        let baseline = ByteRTCSubscribeVideoBaseline()
        baseline.acceptableGoodVideoPixelBaseline = goodVideoPixelBaseline
        baseline.acceptableGoodVideoFpsBaseline = goodVideoFpsBaseline
        baseline.acceptableBadVideoPixelBaseline = badVideoPixelBaseline
        baseline.acceptableBadVideoFpsBaseline = badVideoFpsBaseline
        baseline.acceptableMinVideoResolutionWidth = -1
        baseline.acceptableMinVideoResolutionHeight = -1
        baseline.streamPriority = -1
        return baseline
    }
}

private struct CoremlConfig {
    static let coremlBlurResourceID = "7197243096952738363"
    static let coremlBgResourceID = "7197242826688565820"
    static let coremlBlurLarkResourceID = "7202447676120502786"
    static let coremlBgLarkResourceID = "7202447424923636225"

    static let coremlPanel = "matting"
    static let coremlCategory = "ios_coreml"

    // GPU全链路
    static let enable_matting_optimization = "enable_matting_optimization"
    // Cvpixelbuffer 二期优化
    static let enable_new_algorithm_system_native_buffer = "enable_new_algorithm_system_native_buffer"
    static let enable_algorithm_gpu_resize_with_buffer = "enable_algorithm_gpu_resize_with_buffer"
    // terminalFeature优化
    static let enable_performance_opt_in_terminal_and_general_effect_feature = "enable_performance_opt_in_terminal_and_general_effect_feature"

}

private extension RtcFetchEffectInfo {
    func toRtc() -> ByteRtcFetchEffectInfo {
        var info = ByteRtcFetchEffectInfo()
        info.resID = resId
        info.resPath = resPath
        info.category = category
        info.panel = panel
        info.tags = tags
        info.tagNum = UInt(self.tagNum)
        info.params = params
        return info
    }
}

private extension RtcEffectType {
    func toRtc() -> ByteRtcEffectType {
        switch self {
        case .buildIn:
            return .EffectType_BuildIn
        case .exclusive:
            return .EffectType_Exclusive
        }
    }
}

private extension RtcNsOption {
    func toRtc() -> ByteRtcNsOption {
        switch self {
        case .disabled:
            return .NS_DISABLE
        case .mild:
            return .NS_MILD
        case .medium:
            return .NS_MEDIM
        case .aggressive:
            return .NS_AGGRESSIVE
        case .veryAggressive:
            return .NS_VERY_AGGRESSIVE
        }
    }
}

private extension RtcCreateParams.CameraEncodeLinkageConfig {
    private func isBigView(res: Int) -> Bool {
        // nolint-next-line: magic number
        return res * res * 16 / 9 >= bigViewPixels
    }

    func indexFor(res: Int, performanceLevel: Int, effectStatus: RtcCameraEffectStatus) -> Int {
        var index = smallViewBaseIndex
        switch effectStatus {
        case .none:
            break
        case .filter, .animoji, .retuschieren, .virtualbg:
            index = singleEffectLevel
        default:
            index = groupEffectLevel
        }

        // nolint-next-line: magic number
        if performanceLevel >= 19 {
            index = ecoModeLevel
        }

        if isBigView(res: res) {
            index += bigViewBaseIndex
        }

        return index
    }
}
