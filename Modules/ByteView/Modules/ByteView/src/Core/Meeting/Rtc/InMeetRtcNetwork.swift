//
//  InMeetRtcNetwork.swift
//  ByteView
//
//  Created by kiri on 2022/10/12.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork
import ByteViewSetting
import ByteViewMeeting
import ByteViewRtcBridge

/// 用户业务层处理断线重连/离会
enum InMeetRtcReachableState: String, Hashable, CustomStringConvertible {
    /// 空闲状态（入会前/离会后）
    case idle
    /// rtc回调JoinChannelSuccess/RejoinChannelSuccess
    case connected
    /// rtc回调disconnected
    case disconnected
    /// disconnect后30秒interrupt
    case interrupted
    /// interrupt后30秒timeout
    case timeout
    /// rtc回调connection failed
    case lost

    var description: String { rawValue }
}

struct MeetingWeakNetworkDetect: Decodable {
    let upgradeDetectCount: Int
    let downgradeDetectCount: Int

    static let `default` = MeetingWeakNetworkDetect(upgradeDetectCount: 3, downgradeDetectCount: 2)
}

protocol InMeetRtcNetworkListener: AnyObject {
    /// 触发meeting.isRtcConnecting变化的回调，用于展示连接中...
    func onUserConnected()
    /// 返回当前连接状态，用于断线重连/离会
    func didChangeRtcReachableState(_ state: InMeetRtcReachableState)

    func didChangeLocalNetworkStatus(_ status: RtcNetworkStatus, oldValue: RtcNetworkStatus, reason: InMeetRtcNetwork.NetworkStatusChangeReason)
    func didChangeRemoteNetworkStatus(_ status: [RtcUID: RtcNetworkStatus],
                                      upsertValues: [RtcUID: RtcNetworkStatus],
                                      removedValues: [RtcUID: RtcNetworkStatus],
                                      reason: InMeetRtcNetwork.NetworkStatusChangeReason)
}

final class InMeetRtcNetwork {
    private let logger = Logger.networkStatus

    let isWeakNetworkEnabled: Bool
    private let isNetTrafficControlEnabled: Bool
    private let isRemoteNetworkUnknown: Bool
    private let networkTipConfig: NetworkTipsConfig
    private let minSpeakerVolume: Int

    /// 参会人rtc连接状态
    @RwAtomic
    private(set) var remoteNetworkStatuses: [RtcUID: RtcNetworkStatus] = [:]
    @RwAtomic
    private(set) var localNetworkStatus: RtcNetworkStatus
    private let detectCount = MeetingWeakNetworkDetect(upgradeDetectCount: 1, downgradeDetectCount: 1)
    private var networkTypeChangeTime = CACurrentMediaTime()

    private let listeners = Listeners<InMeetRtcNetworkListener>()
    @RwAtomic
    private(set) var reachableState: InMeetRtcReachableState = .idle
    @RwAtomic
    private var connectionTimeoutJob: DispatchWorkItem?
    @RwAtomic
    private var connectionInterruptJob: DispatchWorkItem?
    @RwAtomic
    private var networkChangeTypeJob: DispatchWorkItem?

    @RwAtomic
    private var hasUserJoinedRTC = false
    @RwAtomic
    private var isFirstRemoteAudioReceived = false
    private let httpClient: HttpClient

    init(service: MeetingBasicService, engine: InMeetRtcEngine) {
        let setting = service.setting
        self.httpClient = service.httpClient
        self.minSpeakerVolume = setting.activeSpeakerConfig.minSpeakerVolume
        self.networkTipConfig = setting.networkTipConfig
        self.isWeakNetworkEnabled = setting.isWeakNetworkEnabled
        self.isRemoteNetworkUnknown = setting.isRemoteNetworkUnknown
        self.isNetTrafficControlEnabled = setting.isNetTrafficControlEnabled
        self.localNetworkStatus = RtcNetworkStatus(isRemote: false, networkType: .begin, isWeakNetworkEnabled: self.isWeakNetworkEnabled)
        Push.remoteRtcNetStatus.inUser(service.userId).addObserver(self) { [weak self] in
            self?.didReceiveRTCNetStatusNotify($0)
        }
        engine.addListener(self)
        engine.addAsListener(self)
        engine.addVideoRendererListener(self)
        logger.info("NetworkTipConfig: \(networkTipConfig)")
    }

    func addListener(_ listener: InMeetRtcNetworkListener) {
        listeners.addListener(listener)
    }

    func removeListener(_ listener: InMeetRtcNetworkListener) {
        listeners.removeListener(listener)
    }

    /// 判断对端是否成功连接。
    ///
    /// 判断对端成功连接的条件：
    /// 1. 收到对端音频首帧
    /// 2. 在 1v1 通话中，对端没有音频权限，则只要加入 rtc 成功即可
    /// 3. 在 1v1 通话中，对端pad开启了禁用麦克风扬声器
    func isCallConnected(isCalleeNoMicAccess: Bool, isCalleePadMicDisabled: Bool) -> Bool {
        return isFirstRemoteAudioReceived || (isCalleeNoMicAccess && hasUserJoinedRTC) || isCalleePadMicDisabled
    }

    func didLeaveChannel() {
        self.handleReachableState(.idle)
        /// 停止带宽管控
        if isNetTrafficControlEnabled {
            stopBandwidthControl()
        }
        trackLocalNetworkStatus(lastStatus: self.localNetworkStatus)
    }

    private func handleReachableState(_ state: InMeetRtcReachableState, function: String = #function) {
        if self.reachableState == state { return }
        logger.info("didChangeRtcReachableState: \(state), oldValue = \(self.reachableState), from = \(function)")
        self.reachableState = state
        listeners.forEach { $0.didChangeRtcReachableState(state) }
        switch state {
        case .disconnected:
            cancelConnectionTimeoutJob()
            startConnectionInterruptJob()
        case .interrupted:
            cancelConnectionInterruptJob()
            startConnectionTimeoutJob()
        default:
            cancelConnectionTimeoutJob()
            cancelConnectionInterruptJob()
            if state == .timeout || state == .lost {
                trackNetworkTypeChanged(.disconnect_leave, oldValue: self.localNetworkStatus.networkType)
            }
        }
    }

    private func createNetworkStatus() -> RtcNetworkStatus {
        RtcNetworkStatus(isWeakNetworkEnabled: self.isWeakNetworkEnabled)
    }

    private func startConnectionTimeoutJob() {
        if connectionTimeoutJob != nil {
            logger.warn("unexpected branch, connectionFailedJob is not nil")
            return
        }
        logger.warn("user start 30s failed join")
        let job = DispatchWorkItem { [weak self] in
            self?.connectionTimeoutJob = nil
            self?.handleReachableState(.timeout)
        }
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(30), execute: job)
        connectionTimeoutJob = job
    }

    private func cancelConnectionTimeoutJob() {
        if connectionTimeoutJob != nil {
            logger.info("user cancel 30s failed join")
            connectionTimeoutJob?.cancel()
            connectionTimeoutJob = nil
        }
    }

    private func startConnectionInterruptJob() {
        if connectionInterruptJob != nil {
            logger.warn("unexpected branch, connectionInterruptJob is not nil")
            return
        }
        logger.warn("user start 30s Interrupt join")
        let job = DispatchWorkItem { [weak self] in
            self?.connectionInterruptJob = nil
            self?.handleReachableState(.interrupted)
        }
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(30), execute: job)
        connectionInterruptJob = job
    }

    private func cancelConnectionInterruptJob() {
        if connectionInterruptJob != nil {
            logger.info("user cancel 30s Interrupt join")
            connectionInterruptJob?.cancel()
            connectionInterruptJob = nil
        }
    }

    private func handleLocalNetworkQualityChanged(_ localQuality: RtcNetworkQualityInfo) {
        let oldValue = self.localNetworkStatus
        if self.localNetworkStatus.updateWith(qualityInfo: localQuality, detectCountConfig: detectCount) {
            logger.info("network status changed quality: \(self.localNetworkStatus.description)")
            listeners.forEach { $0.didChangeLocalNetworkStatus(self.localNetworkStatus, oldValue: oldValue, reason: .networkQualityChanged) }
            self.trackLocalNetworkStatus(lastStatus: oldValue)
        }
    }

    private func handleRemoteNetworkQualityChanged(_ remoteQualities: [RtcNetworkQualityInfo]) {
        _ = self.remoteNetworkStatuses
        var upsertValues: [RtcUID: RtcNetworkStatus] = [:]
        remoteQualities.forEach { qualityInfo in
            var status = self.remoteNetworkStatuses[qualityInfo.uid] ?? createNetworkStatus()
            if status.updateWith(qualityInfo: qualityInfo, detectCountConfig: self.detectCount) {
                // 远端ICE状态优化
                // https://bytedance.feishu.cn/docx/NFFJderoVoungFxwnB2cXNELnnc
                if isRemoteNetworkUnknown {
                    status.isIceDisconnected = status.networkQuality == .unknown
                }
                Logger.networkStatus.debug("remote network status changed quality: \(status.debugDescription)")
                upsertValues[qualityInfo.uid] = status
                self.remoteNetworkStatuses[qualityInfo.uid] = status
            }
        }
        if !upsertValues.isEmpty {
            listeners.forEach {
                $0.didChangeRemoteNetworkStatus(self.remoteNetworkStatuses, upsertValues: upsertValues, removedValues: [:],
                                                reason: .networkQualityChanged)
            }
        }
    }

    private func trackLocalNetworkStatus(lastStatus: RtcNetworkStatus) {
        guard let quality = localNetworkStatus.networkQualityInfo else { return }
        var params: TrackParams = ["network_status": localNetworkStatus.networkQuality.description, "is_show_tips": isWeakNetworkEnabled]
        params["last_network_status"] = lastStatus.networkQuality.description
        params["last_network_status_duration"] = Int(Date().timeIntervalSince1970 - lastStatus.lastChangeTime)
        if let uplinkLossQuality = quality.uplinkLossQuality,
           let uplinkRttQuality = quality.uplinkRttQuality,
           let uplinkAbsBwQuality = quality.uplinkAbsBwQuality,
           let uplinkRelBwQuality = quality.uplinkRelBwQuality,
           let downlinkRttQuality = quality.downlinkRttQuality,
           let downlinkLossQuality = quality.downlinkLossQuality,
           let downlinkAbsBwQuality = quality.downlinkAbsBwQuality,
           let downlinkRelBwQuality = quality.downlinkRelBwQuality {
            params["rtt_quality_tx"] = uplinkRttQuality.rawValue
            params["loss_quality_tx"] = uplinkLossQuality.rawValue
            params["bw_abs_quality_tx"] = uplinkAbsBwQuality.rawValue
            params["bw_rel_quality_tx"] = uplinkRelBwQuality.rawValue
            params["rtt_quality_rx"] = downlinkRttQuality.rawValue
            params["loss_quality_rx"] = downlinkLossQuality.rawValue
            params["bw_abs_quality_rx"] = downlinkAbsBwQuality.rawValue
            params["bw_rel_quality_rx"] = downlinkRelBwQuality.rawValue
        }
        VCTracker.post(name: .vc_network_quality_status, params: params)
    }

    private func startBandwidthControl(_ estimation: RtcNetworkBandwidthEstimation) {
        if let upStatus = estimation.bandwidthStatus(isUpstream: true) {
            httpClient.send(upStatus)
            logger.info("SetVCBandwidthStatusRequest: \(upStatus)")
        }
        if let downStatus = estimation.bandwidthStatus(isUpstream: false) {
            httpClient.send(downStatus)
            logger.info("SetVCBandwidthStatusRequest: \(downStatus)")
        }
    }

    private func stopBandwidthControl() {
        logger.info("SetVCBandwidthStatusRequest: Close Bandwidth Control")
        let request = SetVCBandwidthStatusRequest(vcStatus: .close, bandwidthLevel: .normal, limitStreamDirection: .upstream, detectedUpstreamBandwidth: 0, detectedDownstreamBandwidth: 0)
        httpClient.send(request)
    }

    private func trackNetworkTypeChanged(_ networkType: RtcNetworkType, oldValue: RtcNetworkType) {
        let duration = Int(CACurrentMediaTime() - networkTypeChangeTime)
        self.networkTypeChangeTime = CACurrentMediaTime()
        VCTracker.post(name: .vc_net_disconnection_dev,
                       params: [.action_name: "network_type_changed",
                                "from_state": oldValue.description,
                                "cur_state": networkType.description,
                                "duration": duration])
    }

    private func trackICEDisconnected() {
        httpClient.getResponse(GetHeartbeatStateRequest()) { r in
            if let isHeartbeatNormal = r.value?.isHeartbeatNormal {
                VCTracker.post(name: .vc_net_disconnection_dev,
                               params: [.action_name: "connection_state_changed",
                                        "is_offer_toast": 1,
                                        "is_rust_disconnected": isHeartbeatNormal ? 0 : 1])
            }
        }
    }

    func reportNetworkUnstable(_ unstable: Bool) {
        if unstable {
            trackICEDisconnected()
        }
        httpClient.send(SetIceStateRequest(isIceNormal: !unstable))

        guard unstable != self.localNetworkStatus.isIceDisconnected else { return }
        let oldValue = self.localNetworkStatus
        self.localNetworkStatus.isIceDisconnected = unstable
        Logger.networkStatus.debug("network status changed ice: \(self.localNetworkStatus.debugDescription)")
        listeners.forEach { $0.didChangeLocalNetworkStatus(self.localNetworkStatus, oldValue: oldValue, reason: .iceDisconnected) }
    }

    enum NetworkStatusChangeReason {
        case networkQualityChanged
        case iceDisconnected
        case networkTypeChanged
    }
}

extension InMeetRtcNetwork: RtcListener {
    func onJoinChannelSuccess() {
        handleReachableState(.connected)
    }

    func onRejoinChannelSuccess() {
        handleReachableState(.connected)
    }

    func onUserJoined(uid: RtcUID) {
        hasUserJoinedRTC = true
        listeners.forEach { $0.onUserConnected() }
    }

    func onConnectionStateChanged(state: RtcConnectionState) {
        switch state {
        case .disconnected:
            handleReachableState(.disconnected)
            reportNetworkUnstable(true)
        case .connected, .reconnected:
            reportNetworkUnstable(false)
        case .failed:
            handleReachableState(.lost)
        default:
            break
        }
    }

    func onFirstRemoteAudioFrame(uid: RtcUID) {
        if !isFirstRemoteAudioReceived {
            isFirstRemoteAudioReceived = true
            listeners.forEach { $0.onUserConnected() }
        }
        handleReachableState(.connected)
    }

    func onNetworkTypeChanged(type: RtcNetworkType) {
        /// VC断网提示 https://bytedance.feishu.cn/docs/doccnV3TOiiGd1D463hkB5LgNjb
        let oldValue = self.localNetworkStatus
        if type == oldValue.networkType { return }
        self.localNetworkStatus.networkType = type
        logger.info("NetworkTypeChangedTo type: \(type) oldType: \(oldValue)")
        trackNetworkTypeChanged(type, oldValue: oldValue.networkType)
        logger.info("network status changed type: \(self.localNetworkStatus.debugDescription)")
        let job = DispatchWorkItem(block: { [weak self] in
            guard let self = self else { return }
            self.networkChangeTypeJob = nil
            self.listeners.forEach { $0.didChangeLocalNetworkStatus(self.localNetworkStatus, oldValue: oldValue, reason: .networkTypeChanged) }
            if self.localNetworkStatus.networkType == .disconnected {
                VCTracker.post(name: .vc_net_disconnection_dev, params: [.action_name: "net_disconnect_toast"])
            }
        })
        self.networkChangeTypeJob?.cancel()
        self.networkChangeTypeJob = job
        let delayTimeMillis = Int(self.networkTipConfig.localNetworkDisconnectTipsDelayTime)
        DispatchQueue.main.asyncAfter(deadline: .now() + .microseconds(delayTimeMillis), execute: job)
    }

    func onNetworkQuality(localQuality: RtcNetworkQualityInfo, remoteQualities: [RtcNetworkQualityInfo]) {
        self.handleLocalNetworkQualityChanged(localQuality)
        self.handleRemoteNetworkQualityChanged(remoteQualities)
    }

    func onNetworkBandwidthEstimation(_ estimation: RtcNetworkBandwidthEstimation) {
        if isNetTrafficControlEnabled {
            startBandwidthControl(estimation)
        }
    }
}

extension InMeetRtcNetwork {
    func didReceiveRTCNetStatusNotify(_ notify: RTCNetStatusNotify) {
        logger.info("didReceiveRTCNetStatusNotify: \(notify)")
        self.updateRTCNetStatus(notify.userRTCNetStatuses, for: notify.pushType)
    }

    private func updateRTCNetStatus(_ status: [UserRTCNetStatus], for type: RTCNetStatusPushType) {
        /// 回调的数据可能包含机器人，需要结合Participants数据过滤掉机器人
        let oldNetworkStatus = self.remoteNetworkStatuses
        var upsertValues: [RtcUID: RtcNetworkStatus] = [:]
        var removedValues: [RtcUID: RtcNetworkStatus] = [:]
        switch type {
        case .modify, .full:
            // modify & full 都是更新list，不做删除操作
            status.forEach {
                if var status = oldNetworkStatus[$0.rtcUID] {
                    if status.isIceDisconnected != $0.isIceDisconnected {
                        status.isIceDisconnected = $0.isIceDisconnected
                        upsertValues[$0.rtcUID] = status
                        self.remoteNetworkStatuses[$0.rtcUID] = status
                    }
                } else {
                    var status = createNetworkStatus()
                    status.isIceDisconnected = $0.isIceDisconnected
                    upsertValues[$0.rtcUID] = status
                    self.remoteNetworkStatuses[$0.rtcUID] = status
                }
            }
        case .remove:
            status.forEach {
                if let value = self.remoteNetworkStatuses.removeValue(forKey: $0.rtcUID) {
                    removedValues[$0.rtcUID] = value
                }
            }
        case .unknown:
            return
        }
        if !upsertValues.isEmpty || !removedValues.isEmpty {
            listeners.forEach {
                $0.didChangeRemoteNetworkStatus(self.remoteNetworkStatuses, upsertValues: upsertValues, removedValues: removedValues,
                                                reason: .iceDisconnected)
            }
        }
    }
}

extension InMeetRtcNetwork: RtcActiveSpeakerListener {
    func didReceiveRtcVolumeInfos(_ infos: [RtcAudioVolumeInfo]) {
        var asStatus = [UserRTCNetStatus]()
        infos.forEach {
            if $0.nonlinearVolume > minSpeakerVolume,
               let isDisconnected = self.remoteNetworkStatuses[$0.uid]?.isIceDisconnected, isDisconnected {
                asStatus.append(UserRTCNetStatus(rtcJoinId: $0.uid.id, isIceDisconnected: false))
                logger.info("didIceConnected uid: \($0.uid), reason: active speaker")
            }
        }
        if !asStatus.isEmpty {
            self.updateRTCNetStatus(asStatus, for: .modify)
        }
    }
}

extension InMeetRtcNetwork: RtcVideoRendererListener {
    func didRenderVideoFrame(key: RtcStreamKey) {
        if key.isLocal { return }
        let rtcUid = key.uid
        if let status = self.remoteNetworkStatuses[rtcUid], !status.isIceDisconnected { return }

        logger.info("didIceConnected uid: \(rtcUid), reason: video render")
        self.updateRTCNetStatus([UserRTCNetStatus(rtcJoinId: rtcUid.id, isIceDisconnected: false)], for: .modify)
    }
}

private extension RtcNetworkBandwidthEstimation {
    func bandwidthStatus(isUpstream: Bool) -> SetVCBandwidthStatusRequest? {
        let status = isUpstream ? txBandwidthStatus.rawValue : rxBandwidthStatus.rawValue
        guard let level = SetVCBandwidthStatusRequest.BandwidthLevel(rawValue: status), level != .unknown else {
            return nil
        }
        return SetVCBandwidthStatusRequest(vcStatus: .open, bandwidthLevel: level,
                                           limitStreamDirection: isUpstream ? .upstream : .downstream,
                                           detectedUpstreamBandwidth: Int64(txEstimateBandwidth),
                                           detectedDownstreamBandwidth: Int64(rxEstimateBandwidth))
    }
}

extension InMeetRtcNetworkListener {
    func onUserConnected() {}
    func didChangeRtcReachableState(_ state: InMeetRtcReachableState) {}
    func didChangeLocalNetworkStatus(_ newStatus: RtcNetworkStatus, oldValue: RtcNetworkStatus, reason: InMeetRtcNetwork.NetworkStatusChangeReason) {}
    func didChangeRemoteNetworkStatus(_ status: [RtcUID: RtcNetworkStatus],
                                      upsertValues: [RtcUID: RtcNetworkStatus],
                                      removedValues: [RtcUID: RtcNetworkStatus],
                                      reason: InMeetRtcNetwork.NetworkStatusChangeReason) {}
}
