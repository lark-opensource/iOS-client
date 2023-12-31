//
//  MeetingEvent.swift
//  ByteView
//
//  Created by kiri on 2022/6/9.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork

extension MeetingEvent {
    // MARK: - 客户端行为

    /// 主叫呼叫
    static func userStartCall(params: CallEntryParams) -> MeetingEvent {
        .init(name: .userStartCall, params: ["callEntryParams": params])
    }
    /// 客户端超时
    static let ringingTimeOut = MeetingEvent(name: .ringingTimeOut)
    /// 客户端超时
    static let callingTimeOut = MeetingEvent(name: .callingTimeOut)
    /// 用户离开会议
    static func userLeave(isHoldPstn: Bool, shouldDeferRemote: Bool = false, roomId: String = "", roomInteractiveID: String = "") -> MeetingEvent {
        .init(name: .userLeave, params: ["isHoldPstn": isHoldPstn, "shouldDeferRemote": shouldDeferRemote, "roomId": roomId, "roomInteractiveID": roomInteractiveID])
    }
    static let userLeave = MeetingEvent(name: .userLeave)

    /// 结束会议
    static let userEnd = MeetingEvent(name: .userEnd)

    /// 被系统过滤
    static let filteredByCallKit = MeetingEvent(name: .filteredByCallKit)

    /// 时长耗尽
    static func trialTimeout(planType: PlanType, isFree: Bool) -> MeetingEvent {
        .init(name: .trialTimeout, params: ["planType": planType, "isFree": isFree])
    }
    /// 强制退出
    static let forceExit = MeetingEvent(name: .forceExit)
    /// 发起/加入另一个会议
    static func startAnother(isJoined: Bool) -> MeetingEvent {
        .init(name: .startAnother, params: ["isJoined": isJoined])
    }
    /// 安全策略条件不满足
    static let leaveBecauseUnsafe = MeetingEvent(name: .leaveBecauseUnsafe)
    /// 单人自动结束
    static let autoEnd = MeetingEvent(name: .autoEnd)
    /// 媒体服务重置
    static func mediaServiceLost(isHoldPstn: Bool, shouldDeferRemote: Bool = false) -> MeetingEvent {
        .init(name: .mediaServiceLost, params: ["isHoldPstn": isHoldPstn, "shouldDeferRemote": shouldDeferRemote])
    }

    // MARK: - 服务端数据
    static func noticeCalling(_ info: VideoChatInfo) -> MeetingEvent { .init(name: .noticeCalling, params: ["info": info]) }
    static func noticeRinging(_ info: VideoChatInfo) -> MeetingEvent { .init(name: .noticeRinging, params: ["info": info]) }
    static func noticeOnTheCall(_ info: VideoChatInfo) -> MeetingEvent { .init(name: .noticeOnTheCall, params: ["info": info]) }
    static func noticePreLobby(_ info: LobbyInfo) -> MeetingEvent { .init(name: .noticePreLobby, params: ["info": info]) }
    static func noticeLobby(_ info: LobbyInfo) -> MeetingEvent { .init(name: .noticeLobby, params: ["info": info]) }
    static func noticeTerminated(_ info: VideoChatInfo) -> MeetingEvent { .init(name: .noticeTerminated, params: ["info": info]) }

    // 会中移入等候室
    static func noticeMoveToLobby(_ lobbyParticipant: LobbyParticipant, subType: MeetingSubType) -> MeetingEvent { .init(name: .noticeMoveToLobby, params: ["info": LobbyInfo(isJoinLobby: true, isJoinPreLobby: false, lobbyParticipant: lobbyParticipant, preLobbyParticipant: nil, meetingSubType: subType)]) }

    /// 进入会前阶段，用于precheck和join
    static func startPreparing(_ entry: MeetingEntry) -> MeetingEvent { .init(name: .startPreparing, params: ["entry": entry]) }

    /// 收到其他会议的推送，用于结束start和preparing状态的当前会议
    static let receiveOther = MeetingEvent(name: .receiveOther)

    // MARK: - Errors

    /// 会议不支持等候室
    static let lobbyNotSupport = MeetingEvent(name: .lobbyNotSupport)
    /// 主持人拒绝加入等候室
    static let hostRejectLobby = MeetingEvent(name: .hostRejectLobby)
    /// 会议已结束
    static let meetingHasFinished = MeetingEvent(name: .meetingHasFinished)
    /// 会中心跳中断
    static func heartbeatStop(_ reason: ByteviewHeartbeatStop.Reason, offlineReason: Participant.OfflineReason?) -> MeetingEvent {
        var params: [MeetingAttributeKey: Any] = ["reason": reason]
        if let offlineReason = offlineReason {
            params["offlineReason"] = offlineReason
        }
        return .init(name: .heartbeatStop, params: params)
    }
    /// 服务器出错
    static func serverError(_ error: ServerBadType) -> MeetingEvent { .init(name: .serverError, params: ["error": error]) }
    /// 流媒体SDK出错
    static func rtcError(_ error: RtcEndEvent) -> MeetingEvent { .init(name: .rtcError, params: ["error": error]) }
    /// 找不到合适的UIWindowScene来展示
    static let failedToActiveVcScene = MeetingEvent(name: .failedToActiveVcScene)
    static let createMeetingFailed = MeetingEvent(name: .createMeetingFailed)

    static func voipDualPullFailed(uuid: String) -> MeetingEvent { .init(name: .voipDualPullFailed, params: ["uuid": uuid]) }
}

extension MeetingEventName {
    // MARK: - 客户端行为
    /// 主叫呼叫
    static let userStartCall: MeetingEventName = "userStartCall"
    /// 客户端超时
    static let ringingTimeOut: MeetingEventName = "ringingTimeOut"
    /// 客户端超时
    static let callingTimeOut: MeetingEventName = "callingTimeOut"
    /// 离开会议
    static let userLeave: MeetingEventName = "userLeave"
    /// 结束会议
    static let userEnd: MeetingEventName = "userEnd"
    /// 时长耗尽
    static let trialTimeout: MeetingEventName = "trialTimeout"
    /// 强制退出
    static let forceExit: MeetingEventName = "forceExit"
    /// 发起/加入另一个会议
    static let startAnother: MeetingEventName = "startAnother"
    /// 安全策略条件不满足
    static let leaveBecauseUnsafe: MeetingEventName = "leaveBecauseUnsafe"
    /// 单人自动结束
    static let autoEnd: MeetingEventName = "autoEnd"
    /// callkit 上报被系统拦截
    static let filteredByCallKit: MeetingEventName = "filteredByCallKit"
    /// 媒体服务重置
    static let mediaServiceLost: MeetingEventName = "mediaServiceLost"

    // MARK: - 服务端数据
    static let noticeCalling: MeetingEventName = "noticeCalling"
    static let noticeRinging: MeetingEventName = "noticeRinging"
    static let noticeOnTheCall: MeetingEventName = "noticeOnTheCall"
    static let noticePreLobby: MeetingEventName = "noticePreLobby"
    static let noticeLobby: MeetingEventName = "noticeLobby"
    static let noticeTerminated: MeetingEventName = "noticeTerminated"

    // 会中移入等候室
    static let noticeMoveToLobby: MeetingEventName = "noticeMoveToLobby"

    static let startPreparing: MeetingEventName = "startPreparing"

    // 收到其他会议的推送，用于结束start和preparing状态的当前会议
    static let receiveOther: MeetingEventName = "receiveOther"

    // MARK: - Errors
    /// 会议不支持等候室
    static let lobbyNotSupport: MeetingEventName = "lobbyNotSupport"
    /// 主持人拒绝加入等候室
    static let hostRejectLobby: MeetingEventName = "hostRejectLobby"
    /// 会议已结束
    static let meetingHasFinished: MeetingEventName = "meetingHasFinished"
    /// 会中心跳中断
    static let heartbeatStop: MeetingEventName = "heartbeatStop"
    /// 服务器出错
    static let serverError: MeetingEventName = "serverError"
    /// 流媒体SDK出错
    static let rtcError: MeetingEventName = "rtcError"
    /// 找不到合适的UIWindowScene来展示
    static let failedToActiveVcScene: MeetingEventName = "failedToActiveVcScene"
    static let createMeetingFailed: MeetingEventName = "createMeetingFailed"
    static let voipDualPullFailed: MeetingEventName = "voipDualPullFailed"
}

private func computeMeetingEndReason(offlineReason: Participant.OfflineReason) -> MeetEndReason? {
    // https://meego.feishu.cn/larksuite/story/detail/8682060
    // 通过 HeartbeatStop 中的 offline reason，计算离会原因，优化 Toast 提示
    switch offlineReason {
    case .kickOut:
        return .beKickedOut(inLobby: false)
    case .end:
        return .beHungUp(nil)
    case .acceptOther:
        return .oppositeAcceptOther(nil)
    case .leave:
        return .leave
    case .leaveBecauseUnsafe:
        return .leaveBecauseUnsafe
    default:
        return nil
    }

}

extension MeetingEvent {
    // 通话/会议结束原因
    func endReason(account: ByteviewUser, fromState: MeetingState) -> MeetEndReason? {
        switch name {
        case .ringingTimeOut, .callingTimeOut:
            return .timeout
        case .userLeave:
            switch fromState {
            case .dialing, .calling:
                return .cancel
            case .ringing:
                return .reject
            case .prelobby, .lobby:
                return .hangUp(inLobby: true, isHoldPstn: false)
            case .onTheCall:
                return .hangUp(inLobby: false, isHoldPstn: isHoldPstn)
            case .start, .preparing, .end:
                return nil
            }
        case .userEnd:
            return .userEnd
        case .trialTimeout:
            return .trialTimeout(planType, isFree: isFree)
        case .forceExit, .changeAccount:
            return .beInterrupted(isHoldPstn: isHoldPstn)
        case .startAnother:
            return .startAnother(isJoined: isJoined)
        case .acceptOther:
            return .acceptOther
        case .noticeTerminated:
            return videoChatInfo?.meetEndReason(account: account)
        case .leaveBecauseUnsafe:
            return .leaveBecauseUnsafe
        case .rtcError:
            if let error = params["error"] as? RtcEndEvent {
                return .streamingSDKBad(error)
            }
        case .serverError:
            if let error = params["error"] as? ServerBadType {
                return .serverBad(error)
            }
        case .heartbeatStop:
            if let reason = params["reason"] as? ByteviewHeartbeatStop.Reason, reason == .invalid {
                return .beHungUp(nil)
            } else if let offlineReason = params["offlineReason"] as? Participant.OfflineReason {
                return computeMeetingEndReason(offlineReason: offlineReason)
            } else {
                return .serverBad(.heartBeatStopped)
            }
        case .lobbyNotSupport, .hostRejectLobby:
            return .beKickedOut(inLobby: true)
        case .meetingHasFinished:
            return .meetingHasFinished
        case .autoEnd:
            return .autoEnd
        case .mediaServiceLost:
            return .mediaServiceLost
        default:
            return nil
        }
        return nil
    }
}

extension MeetingEvent {
    var meetingEntry: MeetingEntry? { params["entry"] as? MeetingEntry }
    var startCallParams: StartCallParams? { params["callEntryParams"] as? StartCallParams }
    var enterpriseCallParams: EnterpriseCallParams? { params["callEntryParams"] as? EnterpriseCallParams }
    var videoChatInfo: VideoChatInfo? { params["info"] as? VideoChatInfo }
    var lobbyInfo: LobbyInfo? { params["info"] as? LobbyInfo }
    var shouldDeferRemote: Bool { param(for: "shouldDeferRemote", defaultValue: false) }
    var isHandleMeetingEndManually: Bool { param(for: "isHandleMeetingEndManually", defaultValue: false) }
    var roomId: String? { params["roomId"] as? String }
    var roomInteractiveID: String? { params["roomInteractiveID"] as? String }

    func handleMeetingEndManually() -> MeetingEvent {
        appendParam(true, for: "isHandleMeetingEndManually")
    }
}

private extension MeetingEvent {
    var isHoldPstn: Bool { param(for: "isHoldPstn", defaultValue: false) }
    var planType: PlanType { param(for: "planType", defaultValue: .unknown) }
    var isFree: Bool { param(for: "isFree", defaultValue: false) }
    var isJoined: Bool { param(for: "isJoined", defaultValue: false) }
}
