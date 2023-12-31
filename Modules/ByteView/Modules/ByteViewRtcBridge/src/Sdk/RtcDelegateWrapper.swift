//
//  RtcDelegateWrapper.swift
//  ByteView
//
//  Created by kiri on 2022/8/8.
//

import Foundation
import VolcEngineRTC
import ByteViewCommon

extension RtcObjcProxy: ByteRtcMeetingEngineDelegate {
}

/// 封装ByteRtcMeetingEngineDelegate，隐藏VolcEngineRTC
final class RtcDelegateWrapper: NSObject {
    private let sessionId: String
    private let logger: Logger
    private let listenerContainer: RtcListeners
    fileprivate var uid: RtcUID = RtcUID("")
    weak var rtc: RtcWrapper?

    init(sessionId: String, logger: Logger, listeners: RtcListeners) {
        self.sessionId = sessionId
        self.logger = logger
        self.listenerContainer = listeners
        super.init()
    }
}

private extension RtcDelegateWrapper {
    var listeners: Listeners<RtcListener> { listenerContainer.listeners }
    var asListeners: Listeners<RtcActiveSpeakerListener> { listenerContainer.asListeners }
    var streamStatsListeners: Listeners<RtcStreamStatsListener> { RtcInternalListeners.streamStatsListeners }
    var metadata: Listeners<RtcMetadataListener> { listenerContainer.metadataListeners }
    var rtm: Listeners<RtmListener> { listenerContainer.rtmListeners }
    var roomMessage: Listeners<RtcRoomMessageListener> { listenerContainer.roomMessageListeners }
    var internalListeners: Listeners<RtcInternalListener> { RtcInternalListeners.listeners }

    func invokeInternalListener(_ action: (RtcInternalListener, RtcWrapper) -> Void) {
        if let rtc = self.rtc {
            internalListeners.forEach {
                action($0, rtc)
            }
        }
    }
}

struct RtcDelegateWrapperProxy {
    private let wrappedAction: ((RtcDelegateWrapper) -> Void) -> Void
    init(_ handler: RtcDelegateWrapper, proxy: RtcActionProxy) {
        self.wrappedAction = { action in
            proxy.performAction(.rtcDelegate) {
                action(handler)
            }
        }
    }

    private func run(_ action: (RtcDelegateWrapper) -> Void) {
        self.wrappedAction(action)
    }

    func onJoinChannel(uid: String) {
        run {
            $0.uid = RtcUID(uid)
        }
    }

    func didStartVideoCapture() {
        run {
            $0.invokeInternalListener {
                $0.didStartVideoCapture($1)
            }
        }
    }

    func didStopVideoCapture() {
        run {
            $0.invokeInternalListener {
                $0.didStopVideoCapture($1)
            }
        }
    }

    func didSubscribeStream(_ streamId: String, key: RtcStreamKey, config: RtcSubscribeConfig) {
        run {
            $0.listeners.forEach { $0.didSubscribeStream(streamId, key: key, config: config) }
        }
    }

    func didUnsubscribeStream(_ streamId: String, key: RtcStreamKey, config: RtcSubscribeConfig?) {
        run {
            $0.listeners.forEach { $0.didUnsubscribeStream(streamId, key: key, config: config) }
        }
    }
}

extension RtcDelegateWrapper: ByteRtcMeetingEngineDelegate {
    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onStreamAdd streamId: String, stream: ByteStream) {
        if streamId.contains(self.uid.id) { return }
        let streamKey = stream.streamKey(sessionId: sessionId)
        let streamInfo = RtcStreamInfo(hasVideo: stream.hasVideo, videoStreamDescriptions: stream.videoStreamDescriptions.map(\.vcType))
        logger.info("onStreamAdd, streamId: \(streamId), key: \(streamKey)")
        invokeInternalListener {
            $0.onStreamAdd($1, streamId: streamId, key: streamKey, stream: streamInfo)
        }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onStreamRemove streamId: String, stream: ByteStream) {
        if streamId.contains(self.uid.id) { return }
        let streamKey = stream.streamKey(sessionId: sessionId)
        logger.info("onStreamRemove, streamId: \(streamId), key: \(streamKey)")
        invokeInternalListener {
            $0.onStreamRemove($1, streamId: streamId, key: streamKey)
        }
        listeners.forEach { $0.didUnsubscribeStream(streamId, key: streamKey, config: nil) }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onWarning warnCode: ByteRtcWarningCode) {
        logger.warn("didOccurWarning, code: \(warnCode.rawValue)")
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onVideoDeviceStateChanged device_id: String, device_type: ByteRTCVideoDeviceType, device_state: ByteRTCMediaDeviceState, device_error: ByteRTCMediaDeviceError) {
        logger.info("onVideoDeviceStateChanged, deviceType: \(device_type.rawValue), deviceId: \(device_id), deviceState: \(device_state.rawValue), deviceError: \(device_error.rawValue)")
        if let rtc = rtc, let type = device_type.vcType, let state = device_state.vcType {
            internalListeners.forEach { $0.onMediaDeviceStateChanged(rtc, deviceType: type, deviceId: device_id, deviceState: state,
                                                                     deviceError: device_error.vcType) }
        }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onAudioDeviceStateChanged device_id: String, device_type: ByteRTCAudioDeviceType, device_state: ByteRTCMediaDeviceState, device_error: ByteRTCMediaDeviceError) {
        logger.info("onAudioDeviceStateChanged, deviceType: \(device_type.rawValue), deviceId: \(device_id), deviceState: \(device_state.rawValue), deviceError: \(device_error.rawValue)")
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onVideoDeviceWarning deviceId: String, deviceType: ByteRTCVideoDeviceType, deviceWarning: ByteRTCMediaDeviceWarning) {
        logger.warn("onVideoDeviceWarning, warnCode: \(deviceWarning.rawValue)")
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onAudioDeviceWarning deviceId: String, deviceType: ByteRTCAudioDeviceType, deviceWarning: ByteRTCMediaDeviceWarning) {
        logger.warn("onAudioDeviceWarning, warnCode: \(deviceWarning.rawValue)")
        if let warnCode = deviceWarning.vcType {
            listeners.forEach { $0.onMediaDeviceWarning(warnCode: warnCode) }
        }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onLocalAudioStateChanged state: ByteRtcLocalAudioStreamState, error: ByteRtcLocalAudioStreamError) {
        logger.info("onLocalAudioStateChanged, state:\(state.rawValue), error: \(error.rawValue)")
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onLocalVideoStateChanged state: ByteRtcLocalVideoStreamState, error: ByteRtcLocalVideoStreamError) {
        logger.info("onLocalVideoStateChanged, state:\(state.rawValue), error: \(error.rawValue)")
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onError errorCode: ByteRtcErrorCode) {
        let error = errorCode.vcType
        logger.error("onRtcError, error = \(error)")
        listeners.forEach { $0.onRtcError(error) }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onJoinChannelSuccess channel: String, withUid uid: String, elapsed: Int) {
        logger.info("onJoinChannelSuccess, uid: \(uid), channel \(channel), elapsed: \(elapsed)")
        listeners.forEach { $0.onJoinChannelSuccess() }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onRejoinChannelSuccess channel: String, withUid uid: String, elapsed: Int) {
        logger.info("onRejoinChannelSuccess, uid: \(uid), channel: \(channel), elapsed: \(elapsed)")
        listeners.forEach { $0.onRejoinChannelSuccess() }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onUserJoined uid: String, elapsed: Int) {
        logger.info("onUserJoined, uid: \(uid), elapsed: \(elapsed)")
        let uid = RtcUID(uid)
        listeners.forEach { $0.onUserJoined(uid: uid) }
    }

    // 用户离开回调
    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onUserOffline uid: String, reason: ByteRtcUserOfflineReason) {
        logger.info("user uid: \(uid) did leave, reason: \(reason)")
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onFirstLocalVideoFrameCaptured streamIndex: ByteRTCStreamIndex, with frameInfo: ByteRTCVideoFrameInfo) {
        if let streamIndex = streamIndex.vcType {
            logger.info("onFirstLocalVideoFrameCaptured, streamIndex: \(streamIndex), width: \(frameInfo.width), height: \(frameInfo.height)")
            listeners.forEach { $0.onFirstLocalVideoFrameCaptured(streamIndex: streamIndex) }
        }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onFirstRemoteVideoFrameDecoded streamKey: ByteRTCRemoteStreamKey, with frameInfo: ByteRTCVideoFrameInfo) {
        if let streamKey = streamKey.vcType {
            logger.info("onFirstRemoteVideoFrameDecoded, streamKey: \(streamKey), width: \(frameInfo.width), height: \(frameInfo.height)")
            listeners.forEach { $0.onFirstRemoteVideoFrameDecoded(streamKey: streamKey) }
        }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onFirstRemoteAudioFrame uid: String, elapsed: Int) {
        logger.info("onFirstRemoteAudioFrame, uid: \(uid), elapsed: \(elapsed)")
        let uid = RtcUID(uid)
        listeners.forEach { $0.onFirstRemoteAudioFrame(uid: uid) }
    }

    // 该方法端上没有打印日志是因为RTC会每两秒回调一次，千人下日志量太大，而且RTC有针对这个打印日志，可以检索onAudioVolumeIndication
    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onAudioVolumeIndication speakers: [ByteRtcAudioVolumeInfo], nonlinearTotalVolume: Int, linearTotalVolume: Int) {
        let infos = speakers.map { RtcAudioVolumeInfo(uid: RtcUID($0.uid), nonlinearVolume: $0.nonlinearVolume, linearVolume: $0.linearVolume) }
        asListeners.forEach { $0.didReceiveRtcVolumeInfos(infos) }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onUserMuteVideo muted: Bool, byUid uid: String) {
        logger.info("user: \(uid) video muted: \(muted)")
        if let rtc = rtc {
            let uid = RtcUID(uid)
            internalListeners.forEach { $0.onUserMuteVideo(rtc, muted: muted, key: .stream(uid: uid, sessionId: sessionId)) }
        }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onUserMuteAudio muted: Bool, byUid uid: String) {
        logger.info("user: \(uid) audio muted: \(muted)")
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onUserEnableLocalVideo enabled: Bool, byUid uid: String) {
        logger.info("user: \(uid) local video enabled: \(enabled)")
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onUserEnableLocalAudio enabled: Bool, byUid uid: String) {
        logger.info("user: \(uid) local audio enabled: \(enabled)")
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, on stats: ByteRTCSysStats) {
        let stats = stats.vcType
        listeners.forEach { $0.reportSysStats(stats) }
    }

    /// VC断网提示 https://bytedance.feishu.cn/docs/doccnV3TOiiGd1D463hkB5LgNjb
    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onNetworkTypeChanged type: ByteRTCNetworkType) {
        let type = type.vcType
        listeners.forEach { $0.onNetworkTypeChanged(type: type) }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onConnectionStateChanged state: ByteRTCConnectionState) {
        if let vcType = state.vcType {
            logger.info("onConnectionStateChanged: state =  \(state.rawValue), vcType = \(vcType)")
            listeners.forEach { $0.onConnectionStateChanged(state: vcType) }
        } else {
            logger.warn("onConnectionStateChanged ignored,  state = \(state.rawValue)")
        }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, localNetworkQuality localQuality: ByteRTCLocalNetworkQuality, remoteNetworkQualities remoteQualities: [ByteRTCRemoteNetworkQuality]) {
        let localQuality = localQuality.vcType
        let remoteQualities = remoteQualities.map({ $0.vcType })
        listeners.forEach { $0.onNetworkQuality(localQuality: localQuality, remoteQualities: remoteQualities) }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onUserBinaryMessageReceived uid: String, message: Data) {
        logger.info("onUserBinaryMessageReceived uid:\(uid) uid:\(uid) message count:\(message.count)")
        let uid = RtcUID(uid)
        rtm.forEach { $0.rtmDidReceiveMessage(message, from: uid) }
    }

    /// 带宽管控 https://bytedance.feishu.cn/docs/doccnJecyeGbjVt8eSq0wFsx3yf
    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onNetworkBandwidthEstimation result: NetworkBandwidthEsimationResult) {
        let result = result.vcType
        listeners.forEach { $0.onNetworkBandwidthEstimation(result) }
    }

    /// rtm登录回调
    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onLoginResult uid: String, errorCode: ByteRTCLoginErrorCode, elapsed: Int) {
        logger.info("rtm: onLoginResult, result: \(errorCode.rawValue)")
        if errorCode == ByteRTCLoginErrorCode.success {
            rtm.forEach { $0.rtmDidLogin() }
        }
    }

    /// rtm登录成功后setServerParams回调
    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onServerParamsSetResult errorCode: Int) {
        logger.info("rtm: onServerParamsSetResult, errorCode: \(errorCode)")
        if errorCode == 200 {
            rtm.forEach { $0.rtmDidSetServerParams() }
        }
    }

    /// rtm logout回调
    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onLogout reason: ByteRTCLogoutReason) {
        logger.info("rtm: onLogout reason: \(reason)")
        rtm.forEach { $0.rtmDidLogout() }
    }

    /// rtm发送数据回调
    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onServerMessageSendResult msgid: Int64, error: ByteRTCUserMessageSendResult, message: Data) {
        let errorCode = error.rawValue
        logger.info("rtm: onServerMessageSendResult, error: \(errorCode), msgid: \(msgid)")
        rtm.forEach { $0.rtmDidSendServerMessage(msgid, error: errorCode) }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, on stats: ByteRTCRoomStats) {
        let stats = RtcRoomStats(txCellularKbitrate: stats.txCellularKBitrate, rxCellularKbitrate: stats.rxCellularKBitrate)
        listeners.forEach { $0.onRoomStats(stats) }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, on stats: ByteRTCRemoteStreamStats) {
        let stats = stats.vcType
        streamStatsListeners.forEach { $0.onRemoteStreamStats(stats) }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, on stats: ByteRTCLocalStreamStats) {
        let stats = stats.vcType
        streamStatsListeners.forEach { $0.onLocalStreamStats(stats) }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onRoomBinaryMessageReceived message: Data) {
        roomMessage.forEach { $0.didReceiveRoomBinaryMessage(message) }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onSEIMessageReceived remoteStreamKey: ByteRTCRemoteStreamKey, andMessage message: Data) {
        if remoteStreamKey.streamIndex == .screen, let uid = remoteStreamKey.userId {
            let uid = RtcUID(uid)
            metadata.forEach { $0.didReceiveScreenMetadata(message, uid: uid) }
        }
    }

    func rtcEngine(_ engine: ByteRtcMeetingEngineKit, onConnectionTypeUpdated isP2P: Bool) {
        logger.info("onConnectionTypeUpdated isP2P: \(isP2P)")
        listeners.forEach { $0.onConnectionTypeUpdated(isP2P: isP2P) }
    }
}

private extension NetworkBandwidthEsimationResult {
    var vcType: RtcNetworkBandwidthEstimation {
        .init(txEstimateBandwidth: txEstimateBandwidth, txBandwidthStatus: txBandwidthStatus.vcType,
              rxEstimateBandwidth: rxEstimateBandwidth, rxBandwidthStatus: rxBandwidthStatus.vcType)
    }
}

private extension NetworkBandwidthStatus {
    var vcType: RtcNetworkBandwidthEstimation.Status {
        switch self {
        case .normal:
            return .normal
        case .low:
            return .low
        case .extremeLow:
            return .extremeLow
        default:
            return .unknown
        }
    }
}

private extension ByteRTCNetworkType {
    var vcType: RtcNetworkType {
        RtcNetworkType(rawValue: self.rawValue) ?? .unknown
    }
}

private extension ByteNetworkQuality {
    var vcType: RtcNetworkQuality {
        switch self {
        case .rtcNetworkQualityExcellent, .rtcNetworkQualityGood:
            return .good
        case .rtcNetworkQualityPoor:
            return .weak
        case .rtcNetworkQualityBad, .rtcNetworkQualityVBad:
            return .bad
        default:
            return .unknown
        }
    }
}

private extension ByteRTCLocalNetworkQuality {
    var vcType: RtcNetworkQualityInfo {
        return RtcNetworkQualityInfo(uid: uid,
                                     uplinkQuality: uplinkQuality.vcType,
                                     downlinkQuality: downlinkQuality.vcType,
                                     uplinkLossQuality: uplinkLossQuality.vcType,
                                     downlinkLossQuality: downlinkLossQuality.vcType,
                                     uplinkRttQuality: uplinkRttQuality.vcType,
                                     downlinkRttQuality: downlinkRttQuality.vcType,
                                     uplinkAbsBwQuality: uplinkAbsBwQuality.vcType,
                                     downlinkAbsBwQuality: downlinkAbsBwQuality.vcType,
                                     uplinkRelBwQuality: uplinkRelBwQuality.vcType,
                                     downlinkRelBwQuality: downlinkRelBwQuality.vcType)
    }
}

private extension ByteRTCRemoteNetworkQuality {
    var vcType: RtcNetworkQualityInfo {
        return RtcNetworkQualityInfo(uid: uid, uplinkQuality: uplinkQuality.vcType, downlinkQuality: downlinkQuality.vcType)
    }
}

private extension ByteRTCConnectionState {
    var vcType: RtcConnectionState? {
        switch self {
        case .connecting:
            return .connecting
        case .reconnecting:
            return .reconnecting
        case .connected:
            return .connected
        case .reconnected:
            return .reconnected
        case .disconnected:
            return .disconnected
        case .lost:
            return .lost
        case .failed:
            return .failed
        default:
            return nil
        }
    }
}

private extension ByteRTCRemoteStreamStats {
    var vcType: RtcRemoteStreamStats {
        .init(uid: RtcUID(uid), audioStats: RtcRemoteAudioStats(),
              videoStats: RtcRemoteVideoStats(width: videoStats.width, height: videoStats.height,
                                              isScreen: videoStats.isScreen, codecType: videoStats.codecType.vcType),
              isScreen: isScreen)
    }
}

private extension ByteRTCLocalStreamStats {
    var vcType: RtcLocalStreamStats {
        .init(audioStats: RtcLocalAudioStats(),
              videoStats: RtcLocalVideoStats(isScreen: videoStats.isScreen, codecType: videoStats.codecType.vcType),
              isScreen: isScreen)
    }
}

private extension ByteRTCVideoCodecType {
    var vcType: RtcVideoCodecType {
        switch self {
        case .H264:
            return .h264
        case .byteVC1:
            return .byteVC1
        default:
            return .unknown
        }
    }
}

private extension ByteRTCStreamIndex {
    var vcType: RtcStreamIndex? {
        switch self {
        case .main:
            return .main
        case .screen:
            return .screen
        default:
            return nil
        }
    }
}

private extension ByteRTCRemoteStreamKey {
    var vcType: RtcRemoteStreamKey? {
        if let streamIndex = streamIndex.vcType {
            let rtcJoinID: RtcUID?
            if let userId = userId {
                rtcJoinID = RtcUID(userId)
            } else {
                rtcJoinID = nil
            }
            return .init(userId: rtcJoinID, roomId: roomId, streamIndex: streamIndex)
        } else {
            return nil
        }
    }
}

private extension ByteRTCSysStats {
    var vcType: RtcSysStats {
        .init(cpuAppUsage: cpuAppUsage, cpuTotalUsage: cpuTotalUsage, cpuCoreCount: Int32(cpuCores))
    }
}

private extension ByteRtcSystemUsageInfo {
    var vcType: RtcSystemUsageInfo {
        .init(cpuTotalUsage: cpuTotalUsage, cpuAppUsage: cpuAppUsage, memoryTotalUsage: memoryTotalUsage, memoryAppUsage: memoryAppUsage)
    }
}

private extension ByteRTCMediaDeviceWarning {
    var vcType: RtcMediaDeviceWarnCode? {
        switch self {
        case .captureDetectHowling:
            return .howling
        default:
            return nil
        }
    }
}

private extension ByteRTCVideoDeviceType {
    var vcType: RtcMediaDeviceType? {
        switch self {
        case .captureDevice:
            return .videoCaptureDevice
        default:
            return nil
        }
    }
}

private extension ByteRTCMediaDeviceState {
    var vcType: RtcMediaDeviceState? {
        switch self {
        case .stateInterruptionBegan:
            return .interruptionBegan
        case .stateInterruptionEnded:
            return .interruptionEnded
        case .stateStarted:
            return .started
        case .stateStopped:
            return .stopped
        case .stateRuntimeError:
            return .runtimeError
        default:
            return nil
        }
    }
}

private extension ByteRTCMediaDeviceError {
    var vcType: RtcMediaDeviceError {
        switch self {
        case .OK:
            return .ok
        case .notAvailableInBackground:
            return .notAvailableInBackground
        case .videoInUseByAnotherClient:
            return .videoInUseByAnotherClient
        case .notAvailableWithMultipleForegroundApps:
            return .notAvailableWithMultipleForegroundApps
        case .notAvailableDueToSystemPressure:
            return .notAvailableDueToSystemPressure
        default:
            return .unknown(rawValue)
        }
    }
}

private extension ByteRtcErrorCode {
    var vcType: RtcError {
        switch self {
        case .BRERR_JOIN_ROOM_ERROR:
            return .joinRoomFailed
        case .BRERR_OVER_DEADLOCK_NOTIFY:
            return .overDeadlockNotify
        default:
            return .unknown(self.rawValue)
        }
    }
}

private extension ByteVideoEncoderPreference {
    var vcType: RtcVideoEncoderPreference {
        switch self {
        case .preferMaintainFramerate:
            return .maintainFramerate
        case .preferMaintainQuality:
            return .maintainQuality
        case .preferBalance:
            return .balance
        default:
            return .disabled
        }
    }
}

extension VideoStreamDescription {
    var vcType: RtcVideoStreamDescription {
        RtcVideoStreamDescription(videoSize: videoSize, frameRate: frameRate, maxKbps: maxKbps, encoderPreference: encoderPreference.vcType)
    }
}

private extension ByteStream {
    func streamKey(sessionId: String) -> RtcStreamKey {
        isScreen ? .screen(uid: RtcUID(userId), sessionId: sessionId) : .stream(uid: RtcUID(userId), sessionId: sessionId)
    }
}
