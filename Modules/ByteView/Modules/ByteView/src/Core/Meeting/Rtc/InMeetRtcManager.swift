//
//  InMeetRtcManager.swift
//  ByteView
//
//  Created by kiri on 2022/8/15.
//

import Foundation
import ByteViewMeeting
import ByteViewTracker
import ByteViewNetwork
import ByteViewRtcBridge

final class InMeetRtcManager {
    let engine: InMeetRtcEngine
    let rtm: RtcMessaging
    let network: InMeetRtcNetwork
    let tracker: InMeetRtcTracker
    private let session: MeetingSession
    private let createParams: RtcCreateParams
    private let rtmInfo: RtmInfo?
    private let logger = Logger.byteRtc

    @RwAtomic
    private var isJoined: Bool = false
    private var rtcCryptor: E2eeRtcCryptor?

    init(session: MeetingSession, service: MeetingBasicService, participant: InMeetParticipantManager, rtcParams: RtcCreateParams) {
        self.session = session
        self.createParams = rtcParams
        self.rtmInfo = session.videoChatInfo?.rtmInfo?.toRtc()
        self.engine = service.rtc.createInMeetEngine(rtcParams)
        self.network = InMeetRtcNetwork(service: service, engine: engine)
        self.rtm = RtcMessaging(engine: service.rtc)
        self.tracker = InMeetRtcTracker(session: session, engine: engine, participant: participant)
        self.rtm.delegate = self
        session.push?.sendMessageToRtc.addObserver(self) { [weak self] in
            self?.didGetServerBinaryMessageNotifier($0)
        }
        self.engine.addListener(PrivacyMonitor.shared)
        if session.isE2EeMeeting, let key = session.inMeetingKey, let keyData = key.e2EeKey.meetingKey {
            let cryptor = E2eeRtcCryptor(algorithm: key.encryptAlgorithm.rustValue, key: keyData)
            self.logger.info("create rtc cryptor with key: \(key)")
            self.rtcCryptor = cryptor
            self.engine.setCustomEncryptor(cryptor)
        }

        if service.setting.isEcoModeEnabled {
            // isEcoModeEnabled,开启手动降级
            self.engine.enablePerformanceAdaption(true)
        }
    }

    deinit {
        leaveChannel()
    }

    func joinChannel() -> Bool {
        if isJoined { return true }
        guard let params = makeRtcJoinParams() else {
            return false
        }
        isJoined = true
        engine.joinChannel(params)
        if let rtmInfo = self.rtmInfo {
            rtm.login(info: rtmInfo)
        }
        tracker.trackJoinChannel()
        return true
    }

    private func leaveChannel() {
        guard isJoined else { return }
        isJoined = false
        rtm.logout()
        if let rtcCryptor = self.rtcCryptor {
            let encryptErrors = rtcCryptor.encryptErrors as? [Int: Int] ?? [:]
            let decryptErrors = rtcCryptor.decryptErrors as? [Int: Int] ?? [:]
            E2EeTracks.trackEncryptErrors(encryptErrors: encryptErrors, decryptErrors: decryptErrors, type: .media)
        }
        engine.leaveChannel()
        MemoryLeakTracker.addJob(engine, event: .warning(.leak_object).params([.env_id: session.sessionId, .from_source: engine.description]))
        tracker.trackLeaveChannel()
        network.didLeaveChannel()
        PrivacyMonitor.shared.didLeaveChannel()
    }

    func release() {
        leaveChannel()
    }

    private func makeRtcJoinParams() -> RtcJoinParams? {
        guard let myself = session.myself, let channelName = createParams.channelName else {
            logger.error("makeRtcJoinParams failed, channelName = \(createParams.channelName)")
            return nil
        }
        var callType: String = ""
        var userType: String = ""
        let tenantId = myself.tenantId
        let encTenantId = EncryptoIdKit.encryptoId(tenantId)
        let meetType = session.meetType
        if meetType == .call {
            callType = "call"
            userType = myself.isHost ? "caller" : "callee"
        } else if meetType == .meet {
            callType = "meeting"
            switch myself.meetingRole {
            case .host:
                userType = "host"
            case .coHost:
                userType = "cohost"
            default:
                userType = "attendee"
            }
        }
        let traceId = myself.interactiveId
        let infoParam = #"{"tenant_id":"\#(tenantId)","call_type":"\#(callType)","user_type":"\#(userType)"}"#
        return RtcJoinParams(channelKey: createParams.userToken, channelName: channelName, traceId: traceId, info: infoParam, businessId: encTenantId)
    }
}

extension InMeetRtcManager: RtcMessagingDelegate {

    func didReceiveRtmMessage(_ message: RtmReceivedMessage) {
        let request = SyncRtcMessageRequest(packet: message.packet, messageType: Int32(message.messageType),
                                            messageContext: Int32(message.messageContext))
        session.httpClient.send(request) { [weak self] result in
            self?.logger.info("syncRTCMessage result:\(result)")
        }
    }

    func didSendRtmMessage(_ requestId: String, error: Int) {
        VCTracker.post(name: .vc_binary_message_req_recv_dev, params: [
            "channel_type": "rtc",
            "message_type": "req",
            "local_time_ms": Date().timeIntervalSince1970,
            "result": String(error),
            "req_id": requestId])
    }

    func didGetServerBinaryMessageNotifier(_ response: PushSendMessageToRtcResponse) {
        self.rtm.sendMessage(response)
    }
}

extension PushSendMessageToRtcResponse: RtmSendMessage {}

private extension MeetingRTMInfo {
    func toRtc() -> RtmInfo {
        RtmInfo(signature: signature, url: url, token: token, uid: uid)
    }
}
