//
//  VcMeetingAdapter.swift
//  ByteView
//
//  Created by kiri on 2022/6/9.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork
import ByteViewTracker
import ByteViewRtcBridge
import LarkMedia

/// vc类型的MeetingSession适配器
final class VcMeetingAdapter: MeetingAdapter {
    static func handleMeetingEnvInitialization() {
        // 系统电话状态监听需要在入会前初始化
        _ = PhoneCall.shared

        let registry = MeetingComponentRegistry.shared(for: .vc)
        registry.registerComponent(VcMeetingSessionHandler.self, scope: .session)
        registry.registerComponent(MyselfNotifier.self, scope: .session)
        registry.registerComponent(StartState.self, state: .start)
        registry.registerComponent(PreparingState.self, state: .preparing)
        registry.registerComponent(DialingState.self, state: .dialing)
        registry.registerComponent(CallingState.self, state: .calling)
        registry.registerComponent(RingingState.self, state: .ringing)
        registry.registerComponent(PreLobbyState.self, state: .prelobby)
        registry.registerComponent(LobbyState.self, state: .lobby)
        registry.registerComponent(OnTheCallState.self, state: .onTheCall)
        registry.registerComponent(EndState.self, state: .end)
        registry.registerComponent(AudioDeviceManager.self, scope: .session)
        registry.registerComponent(MeetingEffectManger.self, scope: .session)

        _ = BusyRingingManager.shared
        _ = ReachabilityUtil.currentNetworkType
        PrivacyMonitor.shared.startMonitoring()

        loadGenericTypes()
        DispatchQueue.global().asyncAfter(deadline: .now()) {
            _ = InMeetRegistry.shared
        }
    }

    private static let forceEndEvents: Set<MeetingEventName> = [.userLeave, .forceExit, .noticeTerminated, .startAnother,
                                                                .changeAccount,
                                                                .serverError, .failedToActiveVcScene, .createMeetingFailed,
                                                                .meetingHasFinished,
                                                                .filteredByCallKit]
    private static let cannotEndEvents: Set<MeetingEventName> = [.userStartCall,
                                                                 .noticeCalling, .noticeRinging, .noticeOnTheCall,
                                                                 .noticePreLobby, .noticeLobby]
    private static let acceptOtherStates: Set<MeetingState> = [.ringing, .onTheCall, .prelobby, .lobby]
    private static let supportPendingStates: Set<MeetingState> = [.start, .preparing, .ringing, .end]

    static func handleEvent(_ event: MeetingEvent, session: MeetingSession) throws -> MeetingState {
        let to = try transition(event: event, session: session)
        if session.isPending, !supportPendingStates.contains(to) {
            throw MeetingStateError.pendingNotSupported
        }
        return to
    }

    private static func transition(event: MeetingEvent, session: MeetingSession) throws -> MeetingState {
        let currentState = session.state
        let eventName = event.name

        if currentState == .end {
            // end状态不接受任何事件
            throw cannotEndEvents.contains(eventName) ? MeetingStateError.unexpectedEvent : MeetingStateError.ignore
        }

        if let info = event.videoChatInfo {
            try validVideoChatInfo(info, session: session)
        }

        if forceEndEvents.contains(eventName) {
            // 通用事件处理，状态内不再单独处理
            return .end
        }

        if eventName == .acceptOther, acceptOtherStates.contains(currentState) {
            return .end
        }

        // 状态派发
        switch (currentState, eventName) {
        case (.preparing, .startPreparing),
            (.ringing, .noticeRinging),
            (.calling, .noticeCalling),
            (.onTheCall, .noticeOnTheCall),
            (.lobby, .noticeLobby),
            (.lobby, .noticeMoveToLobby),
            (.prelobby, .noticePreLobby):
            // 重复进入状态机，忽略
            throw MeetingStateError.ignore
        case (_, .noticeOnTheCall):
            return .onTheCall
        case (.start, .startPreparing):
            return .preparing
        case (.preparing, .userStartCall):
            return .dialing
        case (.dialing, .noticeCalling):
            return .calling
        case (.preparing, .noticeRinging):
            return .ringing
        case (.preparing, .noticePreLobby):
            return .prelobby
        case (.preparing, .noticeLobby), (.ringing, .noticeLobby), (.prelobby, .noticeLobby), (.onTheCall, .noticeMoveToLobby):
            return .lobby
        case (.preparing, .receiveOther), (.preparing, .voipDualPullFailed),
            (.calling, .callingTimeOut),
            (.ringing, .ringingTimeOut),
            (.lobby, .lobbyNotSupport), (.lobby, .hostRejectLobby),
            (.prelobby, .lobbyNotSupport), (.prelobby, .hostRejectLobby),
            (.onTheCall, .userEnd), (.onTheCall, .autoEnd), (.onTheCall, .trialTimeout), (.onTheCall, .leaveBecauseUnsafe),
            (.onTheCall, .rtcError), (.onTheCall, .heartbeatStop), (.onTheCall, .mediaServiceLost):
            return .end
        default:
            break
        }
        throw MeetingStateError.unexpectedEvent
    }

    private static func validVideoChatInfo(_ info: VideoChatInfo, session: MeetingSession) throws {
        guard let myself = info.participant(byUser: session.account) else {
            session.loge("Invalid info, myself is nil")
            throw MeetingStateError.invalidInfo
        }

        let state = session.state
        if state == .calling || state == .onTheCall, let oldInteractiveId = session.myself?.interactiveId, !oldInteractiveId.isEmpty,
           !myself.interactiveId.isEmpty, myself.interactiveId != oldInteractiveId {
            // 会中过滤无效的 interactiveID 的 VideoChatInfo 数据
            // https://bytedance.feishu.cn/docs/doccnLH72stoeJTUplX28k3ChZe
            session.loge("Inconsistent interactiveID received!")
            throw MeetingStateError.invalidInfo
        }
    }

    private static func loadGenericTypes() {
        // 初始化泛型缓存，防止崩溃
        // https://t.wtturl.cn/rwFAFxV/
        let testObj: Any = NSObject()
        _ = testObj as? FollowGrootSession
        _ = testObj as? SketchGrootSession
        _ = testObj as? VCNoticeGrootSession
    }
}

enum MeetingStateError: String, Error {
    /// 需要被忽略的action，如ringing状态下的noticeRinging
    case ignore
    /// 不正确的action
    case unexpectedEvent
    case pendingNotSupported
    case missingContext
    case invalidInfo
    case unexpectedStatus
}
