//
//  MeetingSession.swift
//  ByteViewMeeting
//
//  Created by kiri on 2022/5/31.
//

import Foundation
import ByteViewCommon
import ByteViewTracker

internal protocol MeetingSessionDelegate: AnyObject {
    func didLeaveSession(_ session: MeetingSession, event: MeetingEvent)
}

public enum MeetingSessionType: String, Hashable, CustomStringConvertible {
    /// 视频会议
    case vc

    public var description: String { rawValue }
}

public final class MeetingSession {
    public let sessionId: String
    public let sessionType: MeetingSessionType

    @RwAtomic
    public var meetingId: String = ""

    @RwAtomic
    public internal(set) var state: MeetingState = .start

    @RwAtomic
    public internal(set) var isPending: Bool

    private let logger: Logger
    private let listeners = Listeners<MeetingSessionListener>()
    private weak var delegate: MeetingSessionDelegate?

    // @RwAtomic, 都在state的queue里，无需锁
    private(set) var timeline = MeetingSessionTimeline()

    private static let sessionIdGenerator = UUIDGenerator()

    internal init(sessionType: MeetingSessionType, isPending: Bool, delegate: MeetingSessionDelegate) {
        self.sessionId = Self.sessionIdGenerator.generate()
        self.sessionType = sessionType
        self.isPending = isPending
        self.logger = Logger.meeting.withContext(sessionId)
        self.delegate = delegate
        log("init")
        MeetingComponentCache.shared.createSessionCache(sessionId)
        DevTracker.post(.criticalPath(.create_meeting_instance).category(.meeting).params([.env_id: sessionId, "is_pending": isPending]))
    }

    deinit {
        log("deinit")
        cleanCache(isDeinit: true)
        DevTracker.post(.criticalPath(.release_meeting_instance).category(.meeting).params([.env_id: sessionId]))
    }

    private func cleanCache(isDeinit: Bool) {
        MeetingAttributeCache.shared.leaveSession(sessionId: sessionId, isDeinit: isDeinit)
    }
}

public extension MeetingSession {
    func addListener(_ listener: MeetingSessionListener) {
        listeners.addListener(listener)
    }

    func removeListener(_ listener: MeetingSessionListener) {
        listeners.removeListener(listener)
    }

    func start() {
        executeInQueue(source: "startMeeting") {
            MeetingComponentCache.shared.enter(state: .start, session: self)
        }
    }

    /// 发送状态机事件
    /// - 时序：
    ///     - listener willEnterState
    ///     - old components release
    ///     - var state changed
    ///     - new components create
    ///     - listener didEnterState
    ///     - (end) didLeaveMeetingSession
    ///     - completion
    ///     - (end) clean components and attributes
    func sendEvent(_ event: MeetingEvent, file: String = #fileID, function: String = #function, line: Int = #line,
                   completion: ((Result<(MeetingState, MeetingState), Error>) -> Void)? = nil) {
        executeInQueue(source: event.name.rawValue, file: file, function: function, line: line) {
            self.sendEventInternal(event, file: file, function: function, line: line, completion: completion)
        }
    }

    func sendEvent(name: MeetingEventName, params: [MeetingAttributeKey: Any] = [:],
                   file: String = #fileID, function: String = #function, line: Int = #line,
                   completion: ((Result<(MeetingState, MeetingState), Error>) -> Void)? = nil) {
        sendEvent(.init(name: name, params: params), file: file, function: function, line: line, completion: completion)
    }

    // leavePending 的两种情况：1. 用户主动接受忙线响铃；2. 用户正在进行的会议或通话结束，下一通忙线会议自动 leave pending
    func leavePending(file: String = #fileID, function: String = #function, line: Int = #line) {
        if !self.isPending { return }
        let lastSession = MeetingManager.shared.currentSession
        self.isPending = false
        if let lastSession = lastSession {
            log("leavePending, lastSession is \(lastSession)", file: file, function: function, line: line)
            lastSession.sendEvent(name: .acceptOther, params: [.otherSession: self])
        } else {
            log("leavePending, lastSession is nil", file: file, function: function, line: line)
        }
        self.listeners.forEach {
            $0.didLeavePending(session: self)
        }
    }

    func log(_ msg: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        logger.info("\(description): \(msg)", file: file, function: function, line: line)
    }

    func loge(_ msg: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        logger.error("\(description): \(msg)", file: file, function: function, line: line)
    }
}

extension MeetingSession {
    private static let stateQueue = DispatchQueue(label: "ByteView.Meeting.State", qos: .userInitiated)
    /// 在状态机的queue里执行代码
    public func executeInQueue(source: String, file: String = #fileID, function: String = #function, line: Int = #line, action: @escaping () -> Void) {
        let startTime = CACurrentMediaTime()
        MeetingSession.stateQueue.async {
            let latency = Int((CACurrentMediaTime() - startTime) * 1000)
            let timeoutLatency: Int = 2000
            if latency > timeoutLatency {
                DevTracker.post(.warning(.state_queue_timeout).category(.meeting).subcategory(.state)
                    .params([.env_id: self.sessionId, .latency: latency, .from_source: source]), file: file, function: function, line: line)
            }
            let executeTime = CACurrentMediaTime()
            action()
            let elapse = CACurrentMediaTime() - executeTime
            if elapse > 2 {
                DevTracker.post(.warning(.state_execute_timeout).category(.meeting).subcategory(.state)
                    .params([.env_id: self.sessionId, .elapse: elapse, .from_source: source]), file: file, function: function, line: line)
            }
        }
    }

    private func sendEventInternal(_ event: MeetingEvent, file: String, function: String, line: Int,
                                   completion: ((Result<(MeetingState, MeetingState), Error>) -> Void)?) {
        let eventName = event.name.description
        log("🚚 start sendEvent: \(eventName)", file: file, function: function, line: line)
        guard let machine = helper.adapter else {
            self.listeners.forEach {
                $0.didFailToExecuteEvent(event, session: self, error: MeetingError.adapterNotFound)
            }
            loge("🚫 sendEvent failed: \(eventName), implementorNotFound", file: file, function: function, line: line)
            completion?(.failure(MeetingError.adapterNotFound))
            return
        }
        do {
            let t0 = CACurrentMediaTime()
            let oldState = self.state
            let state = try machine.handleEvent(event, session: self)
            self.transition(event, from: oldState, to: state, completion: completion)
            // nolint-next-line: magic number
            let duration = round((CACurrentMediaTime() - t0) * 1e6) / 1e3
            log("✅ sendEvent success: \(eventName), state: \(oldState) ➡️ \(state), duration = \(duration)ms", file: file, function: function, line: line)
        } catch {
            self.listeners.forEach {
                $0.didFailToExecuteEvent(event, session: self, error: error)
            }
            completion?(.failure(error))
            loge("🚫 sendEvent failed: \(eventName), error = \(error)", file: file, function: function, line: line)
        }
    }

    private func transition(_ event: MeetingEvent, from oldState: MeetingState, to state: MeetingState,
                            completion: ((Result<(MeetingState, MeetingState), Error>) -> Void)?) {
        if state == oldState {
            completion?(.success((oldState, state)))
            return
        }

        // listener先离开旧状态
        // component后离开旧状态
        self.listeners.forEach {
            $0.willEnterState(state, from: oldState, event: event, session: self)
        }
        MeetingComponentCache.shared.exchangeScope(event: event, leave: oldState, enter: state, session: self) {
            self.state = state
            self.timeline.transToState(state)
            DevTracker.post(.criticalPath(.enter_meeting_state).category(.meeting).params([.env_id: sessionId, .target: state.description, .from_source: event.name.rawValue]))

        }
        // component先进入新状态
        // listener后进入新状态
        self.listeners.forEach {
            $0.didEnterState(state, from: oldState, event: event, session: self)
        }
        if state == .end {
            // 1. component和listener都处理完了，通知MeetingMananger删除session
            delegate?.didLeaveSession(self, event: event)
            // 2. 然后回调外部的completion（这时候component和attributes还在）
            completion?(.success((oldState, state)))
            // 3. 清理component和attributes
            MeetingComponentCache.shared.leaveSession(session: self)
            self.cleanCache(isDeinit: false)
            // 4. 检测内存泄漏
            MemoryLeakTracker.addJob(self, event: .warning(.leak_meeting).category(.meeting).params([.env_id: sessionId]),
                                     associatedKey: self.sessionId)
        } else {
            completion?(.success((oldState, state)))
        }
    }
}

extension MeetingSession: CustomStringConvertible {
    public var description: String {
        "MeetingSession(\(sessionId))[\(sessionType)][\(meetingId)][\(state)]\(isPending ? "[pending]" : "")"
    }
}

private extension MeetingState {
    static let nonActiveStates: Set<MeetingState> = [.start, .preparing, .end]
    static let lobbyStates: Set<MeetingState> = [.lobby, .prelobby]
}

extension MeetingSession {

    /// state = end
    public var isEnd: Bool { state == .end }

    /// state > preparing && state != end
    public var isActive: Bool { !MeetingState.nonActiveStates.contains(state) }

    public var isInLobby: Bool { MeetingState.lobbyStates.contains(state) }
}
