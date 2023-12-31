//
//  InMeetRtcTracker.swift
//  ByteView
//
//  Created by kiri on 2022/8/10.
//

import Foundation
import ByteViewTracker
import ByteViewMeeting
import ByteViewNetwork
import ByteViewRtcBridge

final class InMeetRtcTracker {
    /// 耗时操作用
    private static let queue = DispatchQueue(label: "byteview.track.rtc")

    let meetingId: String
    let uid: RtcUID
    private let session: MeetingSession
    private let participant: InMeetParticipantManager
    private let targetParticipant: Participant?
    private var isJoinSuccess = false
    private var isFirstRemoteAudioReceived = false
    private var isFirstRemoteVideoReceived = false
    private var isFirstRemoteScreenReceived = false

    private let billingTracker: StreamBillingTracker?

    @RwAtomic
    private var counter = Counter()
    @RwAtomic
    private var metric = Metric()

    @RwAtomic
    var isHostTransferred = false

    private var meetType: MeetingType { session.meetType }
    /// InMeetRtcTracker在进入onthecall时即被创建
    private let onTheCallTime = CACurrentMediaTime()

    /// create before rtc creation
    init(session: MeetingSession, engine: InMeetRtcEngine, participant: InMeetParticipantManager) {
        self.meetingId = session.meetingId
        self.session = session
        self.participant = participant
        self.uid = engine.uid

        switch session.meetType {
        case .meet:
            self.targetParticipant = session.videoChatInfo.flatMap({ $0.participant(byUser: $0.host) })
        case .call:
            let account = session.account
            self.targetParticipant = session.videoChatInfo?.participants.first { $0.user != account }

            // 进入RTC时如果还有其他参会者或者是1v1时则需要rtc连接时长的埋点
            // 暂时仅统计1v1的连接时长
            OnthecallReciableTracker.startConnectRtc(isCall: true)
        default:
            self.targetParticipant = nil
        }

        if let rtcBillingHeartbeatConfig = session.setting?.rtcBillingHeartbeatConfig, rtcBillingHeartbeatConfig.enabled {
            self.billingTracker = StreamBillingTracker(trackInterval: rtcBillingHeartbeatConfig.interval)
        } else {
            self.billingTracker = nil
        }

        engine.addListener(self)
        engine.addVideoRendererListener(self)
        session.push?.inMeetingChange.addObserver(self)
    }

    // NOTE: 由于视频通话存在兼容问题，SDK的uid未必和targetIdentifier相匹配，因此对于视频通话不限制具体id
    private var targetIdInSDK: RtcUID? {
        if meetType == .call { return nil }
        return targetParticipant?.rtcUid
    }

    func trackJoinChannel() {
        // SDK开启/加入房间接口被调用
        VCTracker.post(name: .vc_monitor_sdk, params: [.action_name: "join"])
        session.slaTracker.startJoinChannel()
    }

    func trackLeaveChannel() {
        guard meetType == .call else { return }
        let defaultDuration: Int64?
        if CACurrentMediaTime() - onTheCallTime > 5 {
            defaultDuration = Int64(1000 * 1000)
        } else {
            defaultDuration = nil
        }
        var params: TrackParams = [:]
        params["audio_duration"] = intervalFromOnTheCallToAudioConnected ?? defaultDuration
        params["video_duration"] = intervalFromOnTheCallToVideoConnected ?? defaultDuration
        params["local_video_duration"] = intervalFromOnTheCallToLocalVideoConnected ?? defaultDuration
        if let participant = session.myself {
            params[.extend_value] = ["from_uuid": EncryptoIdKit.encryptoId(participant.user.id),
                                     "from_device_id": participant.deviceId,
                                     "from_interactive_id": participant.interactiveId]
        }
        VCTracker.post(name: .vc_monitor_oncall_to_stream, params: params, platforms: [.tea, .slardar])
    }

    /// 用户已加入房间
    private func trackSdkDidJoin() {
        if metric.sdkDidJoinTime == nil {
            metric.sdkDidJoinTime = CACurrentMediaTime()
        }
        counter.sdkDidJoinCount += 1
        if counter.sdkDidJoinCount == 1 {
            /// 仅限首次SDK加入成功
            VCTracker.post(name: .vc_monitor_sdk, params: [.action_name: "join_success"])
        }
        session.slaTracker.endJoinChannel(success: true)
    }

    private func updateLocalVideoConnectedTime() {
        if metric.sdkLocalVideoConnectedTime == nil {
            metric.sdkLocalVideoConnectedTime = CACurrentMediaTime()
        }
    }

    /// 远端音频已连接
    private func trackSdkAudioConnected(uid: RtcUID, time: Date, catime: CFTimeInterval) {
        if metric.sdkAudioConnectedTimeMap[uid] == nil {
            metric.sdkAudioConnectedTimeMap[uid] = catime
        }
        let count = (counter.sdkAudioConnectedCountMap[uid] ?? 0) + 1
        counter.sdkAudioConnectedCountMap[uid] = count
        let participant = participantByUid(uid)
        let uuid = (participant?.user.id).map { EncryptoIdKit.encryptoId($0) }
        let deviceId = participant?.deviceId
        let interactiveId = participant?.interactiveId
        switch meetType {
        case .call:
            /// 仅限首次收到对方音频
            if sdkAudioConnectedCount == 1 {
                /// 仅限视频通话
                var interval: String = ""
                if let value = intervalFromAcceptToAudioConnected {
                    interval = String(format: "%.2f", round(100.0 * Double(value)) / 100)
                }
                if let role = participant?.meetingRole, role == .host {
                    /// context.sdkType == .byteRTC always true, call_join_type = 1 (else 100)
                    VCTracker.post(name: .vc_call_success, params: ["call_join_type": 1], time: time)
                    VCTracker.post(name: .vc_monitor_caller_meet_callee, params: ["caller_access": interval], time: time)
                } else {
                    VCTracker.post(name: .vc_monitor_callee_meet_caller, params: ["callee_access": interval], time: time)
                }
            }
        case .meet:
            var params: TrackParams = [:]
            var extendValue: [String: Any] = ["is_host": participant?.meetingRole == .host ? 1 : 0]
            extendValue["from_uuid"] = uuid
            extendValue["from_device_id"] = deviceId
            extendValue["from_interactive_id"] = interactiveId
            params[.extend_value] = extendValue
            VCTracker.post(name: .vc_meeting_success, params: params, time: time)
        default:
            break
        }

        /// 仅限1v1通话
        /// 仅限首次收到对方音频
        if let interval = intervalFromDidJoinToAudioConnected, meetType == .call,
           counter.sdkAudioConnectedCountMap.values.first == 1 {
            VCTracker.post(name: .vc_monitor_join_to_stream, params: ["audio_duration": interval], time: time)
        }

        guard meetType == .meet,
              let target = targetParticipant, target.rtcUid == uid, target.meetingRole == .host,
              let interval = intervalFromOnTheCallToAudioConnected(uid: uid),
              counter.sdkAudioConnectedCountMap[uid] == 1,
              counter.sdkVideoUnsubscrbeCountMap[uid, default: 0] == 0,
              !isHostTransferred
        else {
            return
        }

        var params: TrackParams = [:]
        params["audio_duration"] = interval
        var extendValue: [String: Any] = [:]
        extendValue["from_uuid"] = uuid
        extendValue["from_device_id"] = deviceId
        extendValue["from_interactive_id"] = interactiveId
        params[.extend_value] = extendValue
        VCTracker.post(name: .vc_monitor_oncall_to_stream, params: params, time: time, platforms: [.tea, .slardar])
    }

    /// 远端视频已连接
    private func trackSdkVideoConnected(uid: RtcUID, time: Date, catime: CFTimeInterval) {
        if metric.sdkVideoConnectedTimeMap[uid] == nil {
            metric.sdkVideoConnectedTimeMap[uid] = catime
        }
        let count = counter.sdkVideoConnectedCountMap[uid, default: 0] + 1
        counter.sdkVideoConnectedCountMap[uid] = count
        /// 仅限1v1通话
        /// 仅限首次收到对方视频
        if let interval = intervalFromDidJoinToVideoConnected, meetType == .call,
           counter.sdkVideoConnectedCountMap.values.first == 1 {
            VCTracker.post(name: .vc_monitor_join_to_stream, params: ["video_duration": interval], time: time)
        }

        guard meetType == .meet,
              let target = targetParticipant, target.rtcUid == uid, target.meetingRole == .host,
              let interval = intervalFromOnTheCallToVideoConnected(uid: uid),
              counter.sdkVideoConnectedCountMap[uid] == 1,
              counter.sdkVideoUnsubscrbeCountMap[uid, default: 0] == 0,
              !isHostTransferred
        else {
            return
        }

        var params: TrackParams = [:]
        params["video_duration"] = interval
        if let participant = participantByUid(uid) {
            var extendValue: [String: Any] = [:]
            extendValue["from_uuid"] = EncryptoIdKit.encryptoId(participant.user.id)
            extendValue["from_device_id"] = participant.deviceId
            extendValue["from_interactive_id"] = participant.interactiveId
            params[.extend_value] = extendValue
        }
        VCTracker.post(name: .vc_monitor_oncall_to_stream, params: params, time: time, platforms: [.tea, .slardar])
    }

    /// 订阅远端音视频
    func trackSdkSubscribe(uid: RtcUID, isSubscribeVideo: Bool) {
        let time = Date()
        Self.queue.async {
            self.counter.sdkAudioSubscribeCountMap[uid] = self.counter.sdkAudioSubscribeCountMap[uid, default: 0] + 1
            if !isSubscribeVideo {
                self.counter.sdkVideoUnsubscrbeCountMap[uid] = self.counter.sdkVideoUnsubscrbeCountMap[uid, default: 0] + 1
            }

            guard self.meetType == .meet else {
                return
            }

            // 仅限首次订阅音频行为
            if self.counter.sdkVideoUnsubscrbeCountMap[uid] == 1 {
                let participant = self.participantByUid(uid)
                let uuid = (participant?.user.id).map { EncryptoIdKit.encryptoId($0) }
                let deviceId = participant?.deviceId
                let interactiveId = participant?.interactiveId

                var extendValue: [String: Any] = ["is_host": participant?.meetingRole == .host ? 1 : 0]
                extendValue["from_uuid"] = uuid
                extendValue["from_device_id"] = deviceId
                extendValue["from_interactive_id"] = interactiveId
                VCTracker.post(name: .vc_monitor_sdk, params: [.action_name: "first_subscribe", .extend_value: extendValue], time: time)
            }
        }
    }

    private func participantByUid(_ uid: RtcUID) -> Participant? {
        participant.find(rtcUid: uid, in: .global) ?? participant.find(rtcUid: uid, in: .attendeePanels)
    }

    // MARK: - Metrics
    var intervalFromAcceptToAudioConnected: Int64? {
        return intervalFromAcceptToAudioConnected(uid: targetIdInSDK)
    }

    var intervalFromOnTheCallToAudioConnected: Int64? {
        return intervalFromOnTheCallToAudioConnected(uid: targetIdInSDK)
    }

    var intervalFromOnTheCallToVideoConnected: Int64? {
        return intervalFromOnTheCallToVideoConnected(uid: targetIdInSDK)
    }

    var intervalFromDidJoinToAudioConnected: Int64? {
        return intervalFromDidJoinToAudioConnected(uid: targetIdInSDK)
    }

    var intervalFromDidJoinToVideoConnected: Int64? {
        return intervalFromDidJoinToVideoConnected(uid: targetIdInSDK)
    }

    var sdkAudioConnectedCount: Int {
        if let targetId = targetIdInSDK {
            return counter.sdkAudioConnectedCountMap[targetId, default: 0]
        } else {
            return counter.sdkAudioConnectedCountMap.values.first ?? 0
        }
    }

    var sdkVideoConnectedCount: Int {
        if let targetId = targetIdInSDK {
            return counter.sdkVideoConnectedCountMap[targetId, default: 0]
        } else {
            return counter.sdkVideoConnectedCountMap.values.first ?? 0
        }
    }

    func intervalFromAcceptToAudioConnected(uid: RtcUID?) -> Int64? {
        guard let acceptTime = session.meetingAcceptTime else {
            return nil
        }

        let time: CFTimeInterval?
        if let uid = uid {
            time = metric.sdkAudioConnectedTimeMap[uid]
        } else {
            time = metric.sdkAudioConnectedTimeMap.values.first
        }

        guard let sdkAudioConnectedTime = time else {
            return nil
        }

        return Int64((sdkAudioConnectedTime - acceptTime) * 1000)
    }

    func intervalFromOnTheCallToAudioConnected(uid: RtcUID?) -> Int64? {
        let time: CFTimeInterval?
        if let uid = uid {
            time = metric.sdkAudioConnectedTimeMap[uid]
        } else {
            time = metric.sdkAudioConnectedTimeMap.values.first
        }

        guard let sdkAudioConnectedTime = time else {
            return nil
        }

        return Int64((sdkAudioConnectedTime - onTheCallTime) * 1000)
    }

    func intervalFromOnTheCallToVideoConnected(uid: RtcUID?) -> Int64? {
        let time: CFTimeInterval?
        if let uid = uid {
            time = metric.sdkVideoConnectedTimeMap[uid]
        } else {
            time = metric.sdkVideoConnectedTimeMap.values.first
        }

        guard let sdkVideoConnectedTime = time else {
            return nil
        }

        return Int64((sdkVideoConnectedTime - onTheCallTime) * 1000)
    }

    var intervalFromOnTheCallToLocalVideoConnected: Int64? {
        guard let sdkLocalVideoConnectedTime = metric.sdkLocalVideoConnectedTime else {
            return nil
        }
        return Int64((sdkLocalVideoConnectedTime - onTheCallTime) * 1000)
    }

    func intervalFromDidJoinToAudioConnected(uid: RtcUID?) -> Int64? {
        guard let sdkDidJoinTime = metric.sdkDidJoinTime else {
            return nil
        }

        let time: CFTimeInterval?
        if let uid = uid {
            time = metric.sdkAudioConnectedTimeMap[uid]
        } else {
            time = metric.sdkAudioConnectedTimeMap.values.first
        }

        guard let sdkAudioConnectedTime = time else {
            return nil
        }

        return Int64((sdkAudioConnectedTime - sdkDidJoinTime) * 1000)
    }

    func intervalFromDidJoinToVideoConnected(uid: RtcUID?) -> Int64? {
        guard let sdkDidJoinTime = metric.sdkDidJoinTime else {
            return nil
        }

        let time: CFTimeInterval?
        if let uid = uid {
            time = metric.sdkVideoConnectedTimeMap[uid]
        } else {
            time = metric.sdkVideoConnectedTimeMap.values.first
        }

        guard let sdkVideoConnectedTime = time else {
            return nil
        }

        return Int64((sdkVideoConnectedTime - sdkDidJoinTime) * 1000)
    }

    struct Counter {
        var sdkDidJoinCount = 0
        var sdkAudioConnectedCountMap: [RtcUID: Int] = [:]
        var sdkAudioSubscribeCountMap: [RtcUID: Int] = [:]  // 订阅音频行为记数
        var sdkVideoConnectedCountMap: [RtcUID: Int] = [:]
        var sdkVideoUnsubscrbeCountMap: [RtcUID: Int] = [:] // 取消订阅视频流记数
    }

    struct Metric {
        var sdkDidJoinTime: CFTimeInterval?
        var sdkAudioConnectedTimeMap: [RtcUID: CFTimeInterval] = [:]
        var sdkVideoConnectedTimeMap: [RtcUID: CFTimeInterval] = [:]
        var sdkLocalVideoConnectedTime: CFTimeInterval?
        var sdkICEDisConnectedTimeMap: [RtcUID: CFTimeInterval] = [:]
    }
}

extension InMeetRtcTracker: InMeetingChangedInfoPushObserver {
    func didReceiveInMeetingChangedInfo(_ message: InMeetingData) {
        // 多人会议主持人转移
        if message.meetingID == self.meetingId, message.type == .hostTransferred, message.hostTransferData?.host != nil {
            isHostTransferred = true
        }
    }
}

extension InMeetRtcTracker: RtcListener {
    func didSubscribeStream(_ streamId: String, key: RtcStreamKey, config: RtcSubscribeConfig) {
        trackSdkSubscribe(uid: key.uid, isSubscribeVideo: true)
        billingTracker?.subscribe(streamId: streamId, key: key, config: config)

        var resolution: String = ""
        if let videoSize = config.streamDescription?.videoSize, videoSize.width > 0, videoSize.height > 0 {
            resolution = "\(Int(videoSize.width))x\(Int(videoSize.height))"
            trackVideoStreamSubscribeSettings(streamId: streamId, key: key, cfg: config)
        }
        VCTracker.post(name: .vc_cur_sub_strm_resolution_dev, params: [
            "stream_id": streamId,
            "is_share": key.isScreen ? 1 : 0,
            "resolution": resolution
        ])
    }

    func didUnsubscribeStream(_ streamId: String, key: RtcStreamKey, config: RtcSubscribeConfig?) {
        trackSdkSubscribe(uid: key.uid, isSubscribeVideo: false)
        billingTracker?.unsubscribe(key: key)
        if let config = config {
            trackVideoStreamUnubscribeSettings(streamId: streamId, key: key, cfg: config)
        }
    }

    private func trackVideoStreamSubscribeSettings(streamId: String, key: RtcStreamKey, cfg: RtcSubscribeConfig) {
        let extraInfo = cfg.preferredConfig.extraInfo
        var params: TrackParams = [
            "action_name": "subscribe",
            "stream_id": streamId,
            "stream_device_id": key.uid,
            "is_share_screen": key.isScreen ? 1 : 0,
            "layout_type": extraInfo.layoutType,
            "width": cfg.width,
            "height": cfg.height,
            "fps": cfg.preferredConfig.fps,
            "view_cnt": extraInfo.viewCount
        ]
        if let isMini = extraInfo.isMini {
            params["is_mini"] = isMini ? 1 : 0
        }
        VCTracker.post(name: .vc_video_stream_recv_setting_status, params: params)
    }

    private func trackVideoStreamUnubscribeSettings(streamId: String, key: RtcStreamKey, cfg: RtcSubscribeConfig) {
        VCTracker.post(name: .vc_video_stream_recv_setting_status, params: [
            "action_name": "cancel",
            "stream_id": streamId,
            "stream_device_id": key.uid,
            "is_share_screen": key.isScreen ? 1 : 0,
            "width": cfg.width,
            "height": cfg.height,
            "fps": cfg.preferredConfig.fps
        ])
    }

    func onJoinChannelSuccess() {
        isJoinSuccess = true
        trackSdkDidJoin()
    }

    func onRejoinChannelSuccess() {
        isJoinSuccess = true
    }

    func onFirstRemoteAudioFrame(uid: RtcUID) {
        if uid != self.uid {
            let time = Date()
            let catime = CACurrentMediaTime()
            Self.queue.async {
                self.trackSdkAudioConnected(uid: uid, time: time, catime: catime)
            }
            OnthecallReciableTracker.endConnectRtc()
        }
        if !isFirstRemoteAudioReceived {
            isFirstRemoteAudioReceived = true
            DevTracker.post(.criticalPath(.receive_first_audioframe).category(.meeting).subcategory(.rtc)
                .params([.conference_id: meetingId, "is_myself": uid == self.uid]))
        }
    }

    func onFirstLocalVideoFrameCaptured(streamIndex: RtcStreamIndex) {
        updateLocalVideoConnectedTime()
        // 无效的end事件会被忽略
        if isJoinSuccess {
            OnthecallReciableTracker.endOpenCamera()
        } else {
            PreviewReciableTracker.endOpenCamera()
        }
    }

    func onFirstRemoteVideoFrameDecoded(streamKey: RtcRemoteStreamKey) {
        let uid = streamKey.userId
        switch streamKey.streamIndex {
        case .main:
            if let userId = uid, userId != self.uid {
                let time = Date()
                let catime = CACurrentMediaTime()
                Self.queue.async {
                    self.trackSdkVideoConnected(uid: userId, time: time, catime: catime)
                }
                OnthecallReciableTracker.endConnectRtc()
            }
            if !isFirstRemoteVideoReceived {
                isFirstRemoteVideoReceived = true
                DevTracker.post(.criticalPath(.receive_first_videoframe).category(.meeting).subcategory(.rtc)
                    .params([.conference_id: meetingId, "is_myself": uid == self.uid]))
            }
        case .screen:
            if !isFirstRemoteScreenReceived {
                isFirstRemoteScreenReceived = true
                DevTracker.post(.criticalPath(.receive_first_screenframe).category(.meeting).subcategory(.rtc)
                    .params([.conference_id: meetingId, "is_myself": uid == self.uid]))
            }
        }
    }

    /// SDK错误
    func onRtcError(_ error: RtcError) {
        let errorCode = error.rawValue
        VCTracker.post(name: .vcex_bytertc_sdk, params: ["rtc_error": "\(errorCode)"], platforms: [.tea, .slardar])
        CommonReciableTracker.trackRtcError(errorCode: errorCode)
        switch error {
        case .joinRoomFailed:
            session.slaTracker.endJoinChannel(success: false)
        case .overDeadlockNotify:
            // RTC内部卡死,dump调用堆栈上报slardar
            // https://bytedance.feishu.cn/docx/J7p7d6seEofcpjxeqydcWjXFnjc
            VCTracker.shared.trackUserException("rtcsdk_block_ios")
        default:
            break
        }
    }
}

extension InMeetRtcTracker: RtcVideoRendererListener {
    func onSubscribeFirstTimeout(key: RtcStreamKey, streamId: String) {
        // 上报首次订阅流超时
        CommonReciableTracker.trackRtcSubTimeout(streamID: streamId)
        DevTracker.post(.warning(.rtc_subscribe_timeout).category(.video_stream).subcategory(.rtc).params(["stream_id": streamId]))
    }
}

extension InMeetRtcTracker {
    static func trackMuteStatusConflict(mediaType: String, uiMuted: Bool, rtcMuted: Bool, rustMuted: Bool) {
        let params: TrackParams = [
            .from_source: "user_action",
            "media_type": mediaType,
            "local_ui": uiMuted ? 1 : 0,
            "local_rtc": rtcMuted ? 1 : 0,
            "local_rust": rustMuted ? 1 : 0
        ]
        VCTracker.post(name: .vc_mute_status_conflict_dev, params: params)
    }
}
