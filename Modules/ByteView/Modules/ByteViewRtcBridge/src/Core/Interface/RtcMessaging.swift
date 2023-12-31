//
//  RtcMessaging.swift
//  ByteView
//
//  Created by kiri on 2022/8/10.
//

import Foundation
import ByteViewCommon

public protocol RtcMessagingDelegate: AnyObject {
    func didReceiveRtmMessage(_ message: RtmReceivedMessage)
    func didSendRtmMessage(_ requestId: String, error: Int)
}

/// RTC实时消息能力，需要在Rtc实例创建之后调用
/// - https://bytedance.feishu.cn/docs/doccnvNvkr0vMYTvSSUzgqc78pg#
public final class RtcMessaging {
    private static let syncMessageQueue = DispatchQueue(label: "lark.byteview.syncRTCMessageQueue")

    @RwAtomic
    private var status: RtmStatus = .none
    @RwAtomic
    private var rtmInfo: RtmInfo?

    private let rtc: MeetingRtcEngine
    private let logger: Logger
    public weak var delegate: RtcMessagingDelegate?

    public init(engine: MeetingRtcEngine) {
        self.rtc = engine
        self.logger = engine.logger.withTag("[RtcMessaging(\(engine.sessionId))]")
        rtc.listeners.rtmListeners.addListener(self)
    }

    deinit {
        logout()
    }

    public func login(info: RtmInfo) {
        self.rtmInfo = info
        self.status = .rtmInfo
        self.logger.info("rtm login: uid = \(info.uid)")
        self.rtc.execute {
            $0.login(info.token, uid: info.uid)
        }
    }

    public func logout() {
        // 如果已经login，则logout
        switch self.status {
        case .none, .rtmInfo:
            break
        case .login, .parmSet:
            self.status = .none
            logger.info("rtm will logout")
            self.rtc.execute {
                $0.logout()
            }
        }
    }

    @RwAtomic
    private var lastSentMessageReqId: String?
    public func sendMessage(_ message: RtmSendMessage) {
        guard self.status == .parmSet else { return }

        self.lastSentMessageReqId = message.requestId
        logger.info("rtm will sendServerBinaryMessage, context:\(message.messageContext), type: \(message.messageType)")
        var messageContext = message.messageContext
        var messageType = message.messageType
        var contextData: Data = Data(bytes: &messageContext, count: 1)
        let typeData: Data = Data(bytes: &messageType, count: 1)
        contextData.append(typeData)
        contextData.append(message.packet)
        self.rtc.execute {
            $0.sendServerBinaryMessage(contextData)
        }
    }
}

extension RtcMessaging: RtmListener {
    func rtmDidLogin() {
        self.status = .login
        if let rtmInfo = self.rtmInfo {
            logger.info("rtm setServerParams signature \(rtmInfo.signature), url \(rtmInfo.url)")
            self.rtc.execute {
                $0.setServerParams(rtmInfo.signature, url: rtmInfo.url)
            }
        }
    }

    func rtmDidSetServerParams() {
        self.status = .parmSet
    }

    func rtmDidLogout() {
        self.status = .none
    }

    func rtmDidSendServerMessage(_ msgId: Int64, error: Int) {
        if let requestId = self.lastSentMessageReqId {
            delegate?.didSendRtmMessage(requestId, error: error)
        }
    }

    func rtmDidReceiveMessage(_ message: Data, from uid: RtcUID) {
        Self.syncMessageQueue.async { [weak self] in
            guard let delegate = self?.delegate else { return }
            let data = [UInt8](message)
            // 消息格式见文档 https://bytedance.feishu.cn/docs/doccnvNvkr0vMYTvSSUzgqc78pg
            guard data.count > 1 else { return }
            let messageContext = data[0]
            // 端上需要过滤Context不是2的所有消息
            guard messageContext == 2 else { return }
            let messageType = data[1]
            var packet = Data()
            if data.count > 2 {
                packet = Data(data[2...data.count - 1])
            }
            let m = RtmReceivedMessage(fromUid: uid, messageType: messageType, messageContext: messageContext, packet: packet)
            delegate.didReceiveRtmMessage(m)
        }
    }
}

private enum RtmStatus: Int, Codable {
    case none = 0
    case rtmInfo = 1
    case login = 2
    case parmSet = 3
}
