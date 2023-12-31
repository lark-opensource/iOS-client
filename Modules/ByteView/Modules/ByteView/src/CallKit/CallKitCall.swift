//
//  CallKitCall.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/12/7.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import CallKit
import ByteViewCommon
import ByteViewMeeting
import ByteViewUI
import ByteViewNetwork

protocol CallKitCallDelegate: AnyObject {
    func didStartCall(_ call: CallKitCall)
    func didRemoveCall(_ call: CallKitCall)
    func didMuteMicrophone(_ call: CallKitCall, isMuted: Bool)
    func canHoldCall(_ call: CallKitCall, isOnHold: Bool) -> Bool
    func didAcceptRinging(_ call: CallKitCall, error: Error?)
    func performEndCall(_ call: CallKitCall, deferRequest: Bool, isAcceptOther: Bool) -> Bool
}

final class CallKitCall {
    let uuid = UUID()
    let userId: String
    let sessionId: String
    let isOutgoing: Bool
    let incomingCallParams: IncomingCallParams?
    var isMuted: Bool = false
    weak var delegate: CallKitCallDelegate?

    var status: Status {
        didSet {
            log("call setStatus: \(oldValue) -> \(status), uuid = \(uuid)")
        }
    }

    private var startCallAction: CXStartCallAction?
    private var endCallAction: CXEndCallAction?
    private var answerCallAction: CXAnswerCallAction?
    private let logger: Logger

    init(session: MeetingSession, incomingParams: IncomingCallParams) {
        self.userId = session.userId
        self.sessionId = session.sessionId
        self.logger = Logger.callKit.withContext(session.sessionId)
        self.incomingCallParams = incomingParams
        self.isOutgoing = false
        self.status = .ringing
        log("init CallKitCall<\(uuid)>, isVoipPush = \(incomingParams.isVoipPush)")
    }

    init<T>(session: MeetingSession, startAction: @escaping CallKitStartCallAction<T>, completion: @escaping (Result<T, Error>) -> Void) {
        self.userId = session.userId
        self.sessionId = session.sessionId
        self.logger = Logger.callKit.withContext(session.sessionId)
        self.incomingCallParams = nil
        self.isOutgoing = true
        self.status = .dialing(BlockDialingTransaction(action: startAction, callback: completion))
        log("init CallKitCall<\(uuid)>")
    }

    deinit {
        log("deinit CallKitCall<\(uuid)>")
    }

    func log(_ msg: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        logger.info("\(description): \(msg)", file: file, function: function, line: line)
    }

    func loge(_ msg: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        logger.error("\(description): \(msg)", file: file, function: function, line: line)
    }

    // MARK: - startCall
    func performStartCall(action: CXStartCallAction) {
        log("performStartCall: \(action.callUUID)")
        guard case let .dialing(transaction) = self.status else {
            loge("inconsistent state")
            action.fail()
            return
        }
        transaction.run()
        self.startCallAction = action
    }

    func reportStartCallSucceed() {
        log("reportStartCallSucceed \(self.uuid)")
        guard case .dialing = self.status else {
            loge("reportStartCallSucceed inconsistent state")
            return
        }
        self.status = .calling
        self.startCallAction?.fulfill(withDateStarted: Date())
        self.startCallAction = nil
    }

    func reportOutGoingConnected() {
        log("\(#function) \(self.uuid)")
        switch self.status {
        case .connecting, .calling:
            self.status = .connected
        default:
            loge("\(#function) inconsistent state")
        }
    }

    func performAnswerCall(action: CXAnswerCallAction) -> Bool {
        guard case .ringing = self.status else {
            loge("\(#function) failed, inconsistent state")
            self.status = .ended
            action.fail()
            delegate?.didAcceptRinging(self, error: CallKitCall.CallKitStateError.inconsistentState)
            return false
        }
        self.status = .answering
        self.answerCallAction = action
        delegate?.didAcceptRinging(self, error: nil)
        return true
    }

    func reportAnswerSucceed() {
        guard case .answering = self.status else {
            loge("\(#function) failed, inconsistent state")
            return
        }
        self.answerCallAction?.fulfill(withDateConnected: Date())
        self.answerCallAction = nil
        self.status = .connected
    }

    func reportAnswerFailed() {
        guard case .answering = self.status else {
            loge("\(#function) failed, inconsistent state")
            return
        }
        self.answerCallAction?.fail()
        self.answerCallAction = nil
        self.status = .ended
    }

    func performEnd(action: CXEndCallAction, deferRequest: Bool, isAcceptOther: Bool) -> Bool {
        switch self.status {
        case .dialing(let transaction):
            if let startCallAction = self.startCallAction {
                startCallAction.fail()
                self.startCallAction = nil
            }
            transaction.fail(error: VCError.userCancelOperation)
            self.status = .ending
            self.endCallAction = action
        case .calling, .connecting, .connected, .ringing, .answering:
            self.status = .ending
            self.endCallAction = action
        case .ending:
            break
        case .ended:
            action.fulfill()
        }

        if let delegate = self.delegate {
            return delegate.performEndCall(self, deferRequest: deferRequest, isAcceptOther: isAcceptOther)
        } else {
            return true
        }
    }

    /// 更新 Call 状态为结束
    /// - Returns: 是否需要调用 CallKit provider.reportCall:ended
    func reportEnded() -> Bool {
        switch self.status {
        case .dialing(let transaction):
            if let startCallAction = self.startCallAction {
                startCallAction.fail()
                self.startCallAction = nil
            }
            transaction.fail(error: VCError.userCancelOperation)
            self.status = .ended
        case .calling:
            self.status = .ended
        case .ending:
            self.endCallAction?.fulfill(withDateEnded: Date())
            self.endCallAction = nil
            self.status = .ended
            return false
        case .ringing:
            self.status = .ended
        case .answering:
            reportAnswerFailed()
        case .connecting:
            self.status = .ended
        case .connected:
            self.status = .ended
        case .ended:
            return false
        }
        return true
    }

    func performMuteCall(action: CXSetMutedCallAction, isTriggeredInApp: Bool) {
        let isMutedBeforeAction = self.isMuted
        self.isMuted = action.isMuted
        action.fulfill()
        if isTriggeredInApp {
            log("skip SetMutedAction from app")
            return
        }
        if action.isMuted == isMutedBeforeAction {
            log("system perform muted action with \(self.isMuted), but it is equal to call muted")
            return
        }
        self.delegate?.didMuteMicrophone(self, isMuted: action.isMuted)
    }

    func performHoldCall(action: CXSetHeldCallAction) {
        if let delegate = self.delegate, delegate.canHoldCall(self, isOnHold: action.isOnHold) {
            action.fulfill()
        } else {
            action.fail()
        }
    }
}

extension CallKitCall: CustomStringConvertible {
    var description: String {
        "CallKitCall(\(sessionId))[\(status)]"
    }
}

extension CallKitCall.Status: CustomStringConvertible {
    var description: String {
        switch self {
        case .ringing:
            return "ringing"
        case .answering:
            return "answering"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .dialing:
            return "dialing"
        case .calling:
            return "calling"
        case .ending:
            return "ending"
        case .ended:
            return "ended"
        }
    }
}

protocol CallKitDialingTransaction {
    func run()
    func fail(error: Error)
}

extension CallKitCall {
    enum Status: Equatable {
        case ringing
        case answering
        case connected
        case dialing(CallKitDialingTransaction)
        case calling
        case connecting
        case ending
        case ended

        static func == (lhs: CallKitCall.Status, rhs: CallKitCall.Status) -> Bool {
            return lhs.description == rhs.description
        }
    }

    struct IncomingCallParams {
        let isVoipPush: Bool
        let meetingId: String
        let interactiveId: String
        let meetingType: MeetingType
        let inviterId: String
        let meetingRole: Participant.MeetingRole?
        let callUpdate: CXCallUpdate
        let requestId: UUID

        init(pushInfo: VoIPPushInfo) {
            self.isVoipPush = true
            self.meetingId = pushInfo.conferenceID
            self.interactiveId = pushInfo.interactiveID
            self.meetingType = pushInfo.meetingType.vcType
            self.inviterId = pushInfo.inviterID
            self.meetingRole = pushInfo.role
            self.callUpdate = .from(pushInfo: pushInfo)
            self.requestId = pushInfo.requestId
        }

        init(info: VideoChatInfo, myself: Participant, topic: String) {
            self.isVoipPush = false
            self.meetingId = info.id
            self.interactiveId = myself.interactiveId
            self.meetingType = info.type
            self.inviterId = info.inviterId
            self.meetingRole = myself.meetingRole
            self.callUpdate = .from(userId: myself.user.id, info: info, topic: topic)
            self.requestId = UUID()
        }
    }

    final class BlockDialingTransaction<T>: CallKitDialingTransaction {
        enum State {
            case initial
            case run
            case failed
        }
        private var state: State = .initial
        private let action: (@escaping (Result<T, Error>) -> Void) -> Void
        private let callback: (Result<T, Error>) -> Void

        init(action: @escaping (@escaping (Result<T, Error>) -> Void) -> Void, callback: @escaping (Result<T, Error>) -> Void) {
            self.action = action
            self.callback = callback
        }

        func run() {
            guard self.state == .initial else {
                return
            }
            self.state = .run
            let completion = self.callback
            action(completion)
        }

        func fail(error: Error) {
            guard self.state == .initial else {
                return
            }
            self.state = .failed
            self.callback(.failure(error))
        }
    }

    enum CallKitStateError: Error {
        case inconsistentState
    }
}

extension CXCallUpdate {
    static func from(userId: String, info: VideoChatInfo, topic: String) -> CXCallUpdate {
        let update = CXCallUpdate.from(topic: topic, isInterview: info.meetingSource == .vcFromInterview, meetingType: info.type)
        CXHandleUtil.updateHandle(update, userId: userId, meetingId: info.id, meetingType: info.type, inviterId: info.inviterId)
        return update
    }

    static func from(userId: String, lobbyInfo: LobbyInfo, inviterId: String?) -> CXCallUpdate {
        let topic = I18n.View_M_WaitingEllipsis
        let update = CXCallUpdate.from(topic: topic, isInterview: false, meetingType: .meet)
        // callUpdate.hasVideo = true
        CXHandleUtil.updateHandle(update, userId: userId, meetingId: lobbyInfo.meetingId, meetingType: .meet, inviterId: inviterId ?? "")
        return update
    }

    static func from(pushInfo: VoIPPushInfo, ignoredReason: CallkitIgnoredReason? = nil) -> CXCallUpdate {
        let meetingType = pushInfo.meetingType.vcType
        let otherUser = ignoredReason == .otherUser
        let topic = otherUser ? "" : pushInfo.topic
        let update = CXCallUpdate.from(topic: topic, isInterview: pushInfo.isInterview, meetingType: meetingType)
        if !otherUser {
            // 收到非当前用户推送，caller 信息不写入到历史记录中
            CXHandleUtil.updateHandle(update,
                                      userId: pushInfo.userID,
                                      meetingId: pushInfo.conferenceID,
                                      meetingType: meetingType,
                                      inviterId: pushInfo.inviterID)
        }
        return update
    }

    private static func from(topic: String, isInterview: Bool, meetingType: MeetingType) -> CXCallUpdate {
        let callUpdate = CXCallUpdate()
        callUpdate.supportsHolding = true
        callUpdate.supportsDTMF = false
        callUpdate.supportsGrouping = false
        callUpdate.supportsUngrouping = false
        callUpdate.hasVideo = false
        if topic.isEmpty {
            callUpdate.localizedCallerName = I18n.View_MV_AppNameWithMeeting()
        } else if isInterview {
            callUpdate.localizedCallerName = I18n.View_M_VideoInterviewNameBraces(topic)
        } else if meetingType == .call {
            callUpdate.localizedCallerName = PhoneNumberUtil.format(topic) ?? topic
        } else {
            callUpdate.localizedCallerName = topic
        }
        let handle = CXHandle(type: .generic, value: topic)
        callUpdate.remoteHandle = handle
        return callUpdate
    }
}
