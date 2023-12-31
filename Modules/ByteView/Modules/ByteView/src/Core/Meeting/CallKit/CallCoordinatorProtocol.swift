//
//  MockCallCoordinator.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/12/10.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork

enum CallEndedReason {
    case failed
    case remoteEnded
    case unanswered
    case answeredElsewhere
    case declinedElsewhere
}

extension CallEndedReason {
    /// 目前所有通话结束默认使用 `remoteEnded` 作为原因，
    /// 等后端完善 Participant.OfflineReason 枚举类型，
    /// 增加其它设备接听 / 挂断原因， 再做区分
    static var `default`: CallEndedReason {
        return .remoteEnded
    }
}

/// callkit 被忽略的原因
enum CallkitIgnoredReason: String {
    case timeout = "receive_timeout"
    case cancel = "remote_cancel"
    case disturbMode = "no_disturb_mode"
    case existed = "existed"
    case larkVoIPOngoing = "lark_voip_ongoing"
    case terminated = "terminated"
    case permissionFailed = "permission_failed"
    case otherUser = "other_user"
    case others = "others"
    case forceDropExpired = "force_drop_expired"
}

/// CallKit 上报消费结果
enum CallkitConsumeResult: Equatable {
    /// 消费成功
    case succeed
    /// 忽略
    case ignored(CallkitIgnoredReason)
    /// 需要降级到 App 内响铃弹窗
    case downgradeToAppRinging
    /// 系统报告的错误值，-1 是未知错误，具体参考:
    /// https://developer.apple.com/documentation/callkit/cxerrorcodeincomingcallerror/code/
    case error(Int)
}

typealias CallKitStartCallAction<T> = (@escaping (Result<T, Error>) -> Void) -> Void
protocol CallCoordinatorProtocol {
    func reportNewIncomingCall(info: VideoChatInfo, myself: Participant, completion: @escaping (Result<CallkitConsumeResult, Error>) -> Void)
    func requestStartCall<T>(action: @escaping CallKitStartCallAction<T>, completion: @escaping (Result<T, Error>) -> Void)
    func reportCallEnded(reason: CallEndedReason)
    func muteCallMicrophone(muted: Bool)
    func unmuteCallCamera()
    func reportEnteringOnTheCall(meeting: InMeetMeeting)
    func isByteViewCall(uuid: UUID, completion: @escaping (Bool) -> Void)
    func releaseHold()
    func waitAudioSessionActivated(completion: @escaping (Result<Void, Error>) -> Void)
    /// 是否有等待的事务
    func checkPendingTransactions(callback: @escaping (Bool) -> Void)
    var isEnabled: Bool { get }
}

final class MockCallCoordinator: CallCoordinatorProtocol {
    static var shared = MockCallCoordinator()
    func reportNewIncomingCall(info: VideoChatInfo, myself: Participant, completion: @escaping (Result<CallkitConsumeResult, Error>) -> Void) {
        completion(.success(.downgradeToAppRinging))
    }

    func requestStartCall<T>(action: @escaping CallKitStartCallAction<T>, completion: @escaping (Result<T, Error>) -> Void) {
        action(completion)
    }

    func reportEnteringOnTheCall(meeting: InMeetMeeting) {
    }

    func reportCallEnded(reason: CallEndedReason) {
    }

    func muteCallMicrophone(muted: Bool) {
    }

    func unmuteCallCamera() {
    }

    func isByteViewCall(uuid: UUID, completion: @escaping (Bool) -> Void) {
        completion(false)
    }

    func releaseHold() {
    }

    func waitAudioSessionActivated(completion: @escaping (Result<Void, Error>) -> Void) {
        completion(.success(Void()))
    }

    func checkPendingTransactions(callback: @escaping (Bool) -> Void) { callback(false) }

    var isEnabled: Bool { false }
}

extension MeetingSession {
    var callCoordinator: CallCoordinatorProtocol {
        #if BYTEVIEW_CALLKIT
        if let callKit = self.callKit, callKit.isEnabled {
            return callKit
        }
        #endif
        return MockCallCoordinator.shared
    }

    var isCallKit: Bool {
        callCoordinator.isEnabled
    }
}
