//
//  MeetingManager.swift
//  ByteViewMeeting
//
//  Created by kiri on 2022/6/6.
//

import Foundation
import ByteViewCommon

public protocol MeetingManagerListener: AnyObject {
    func didCreateMeetingSession(_ session: MeetingSession)
    func didLeaveMeetingSession(_ session: MeetingSession, event: MeetingEvent)
}

public final class MeetingManager {
    public static let shared = MeetingManager()

    @RwAtomic
    public private(set) var sessions: [MeetingSession] = []
    private let listeners = Listeners<MeetingManagerListener>()

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeAccount),
                                               name: VCNotification.didChangeAccountNotification, object: nil)
    }

    @objc private func didChangeAccount() {
        leaveAll(.init(name: .changeAccount))
    }

    public func leaveAll(_ event: MeetingEvent) {
        let sessions = self.sessions
        self.sessions = []
        sessions.forEach { $0.sendEvent(event) }
    }
}

public extension MeetingManager {
    func addListener(_ listener: MeetingManagerListener) {
        listeners.addListener(listener)
    }

    func removeListener(_ listener: MeetingManagerListener) {
        listeners.removeListener(listener)
    }

    /// 这里创建的session一定要流转到end才会结束，否则会一直留在内存中
    /// - parameter initialTask: 初始化任务（before all components）
    /// - parameter forcePending: 是否强制pending
    func createSession(_ sessionType: MeetingSessionType, forcePending: Bool = false,
                       file: String = #fileID, function: String = #function, line: Int = #line) -> MeetingSession {
        sessionType.helper.initializeEnvOnce()
        let isPending = forcePending || currentSession != nil
        let session = MeetingSession(sessionType: sessionType, isPending: isPending, delegate: self)
        Logger.meeting.info("didCreateMeetingSession \(session)", file: file, function: function, line: line)
        sessions.append(session)
        listeners.forEach {
            $0.didCreateMeetingSession(session)
        }
        return session
    }

    func findSession(sessionId: String) -> MeetingSession? {
        sessions.first { $0.sessionId == sessionId }
    }

    func findSession(meetingId: String, sessionType: MeetingSessionType) -> MeetingSession? {
        sessions.first { $0.sessionType == sessionType && $0.meetingId == meetingId }
    }

    var currentSession: MeetingSession? {
        sessions.first { !$0.isPending }
    }

    var hasActiveMeeting: Bool { sessions.contains(where: { $0.isActive }) }

    func removeAllSessions(event: MeetingEvent) {
        let sessions = self.sessions
        self.sessions = []
        sessions.forEach { session in
            session.sendEvent(event)
        }
    }
}

extension MeetingManager: MeetingSessionDelegate {
    func didLeaveSession(_ session: MeetingSession, event: MeetingEvent) {
        let sessionId = session.sessionId
        sessions.removeAll { $0.sessionId == sessionId }
        listeners.forEach {
            $0.didLeaveMeetingSession(session, event: event)
        }
        Logger.meeting.info("didLeaveSession \(session), event = \(event.name)")
        if currentSession == nil {
            findNextSession()?.leavePending()
        }
    }

    private func findNextSession() -> MeetingSession? {
        let candidates = sessions.filter { $0.state != .end }
        // 先找忙线
        let nextSession = candidates.compactMap { session -> (CFTimeInterval, MeetingSession)? in
            if let time = session.timeline.startTime(for: .ringing) {
                return (time, session)
            } else {
                return nil
            }
        }.max { lhs, rhs in
            lhs.0 < rhs.0
        }?.1
        if let session = nextSession {
            return session
        }
        // 再找其他
        if let session = candidates.max(by: { $0.timeline.startTime < $1.timeline.startTime }) {
            return session
        }
        return nil
    }
}
