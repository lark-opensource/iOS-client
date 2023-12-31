//
//  PrivacyMonitor.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/9/22.
//

import Foundation
import ByteViewMeeting
import ByteViewTracker
import ByteViewRtcBridge

fileprivate extension Notification.Name {
    static let larkEnterContext = Notification.Name("LarkEnterContext")
    static let larkLeaveContext = Notification.Name("LarkLeaveContext")
}

final class PrivacyMonitor {
    static let shared = PrivacyMonitor()
    /// 结束会议后等待 rtc 释放的时间
    static let delayTime: TimeInterval = 3

    private static let contextName = "ByteViewMeeting"
    private static let logger = Logger.getLogger("Privacy", prefix: "ByteView")

    private var currentSessionId: String?
    private var unregisterTask: DispatchWorkItem?
    private var unlockTime: CFTimeInterval?
    private var hasJoinedChannel = false
    private let queue = DispatchQueue(label: "lark.byteview.privacy_monitor")

    func startMonitoring() {
        Self.logger.info("PrivacyMonitory start monitoring.")
        MeetingManager.shared.addListener(self)
    }

    // MARK: - Private

    private func registerAllowlist() {
        NotificationCenter.default.post(name: .larkEnterContext, object: nil, userInfo: ["name": Self.contextName])
    }

    private func unregisterAllowlist() {
        NotificationCenter.default.post(name: .larkLeaveContext, object: nil, userInfo: ["name": Self.contextName])
    }

    private func didEnterMeeting(sessionId: String) {
        Self.logger.info("Register allowlist for \(Self.contextName), currentID changed from \(currentSessionId) to \(sessionId)")
        unregisterTask?.cancel()
        unregisterTask = nil
        currentSessionId = sessionId
        registerAllowlist()
    }

    private func didLeaveMeeting(sessionId: String) {
        Self.logger.info("DidLeaveMeeting, currentID = \(currentSessionId)")
        let item = DispatchWorkItem { [weak self] in
            Self.logger.info("DidLeaveMeeting work item executed, id = \(sessionId), currentId = \(self?.currentSessionId)")
            guard let self = self, self.currentSessionId == sessionId else {
                Self.logger.info("New module started. No need to unregister allowlist")
                return
            }
            Self.logger.info("Unregister allowlist for \(Self.contextName)")
            self.unregisterAllowlist()
            self.unregisterTask?.cancel()
            self.unregisterTask = nil
            self.currentSessionId = nil
            if self.hasJoinedChannel {
                Self.logger.warn("Time for releasing rtc is too long. False positive privacy issues may occur.")
                DevTracker.post(.privacy(.leave_channel_too_slow))
            }
        }
        unregisterTask = item
        if hasJoinedChannel {
            queue.asyncAfter(deadline: .now() + Self.delayTime, execute: item)
            unlockTime = CACurrentMediaTime()
        } else {
            queue.async(execute: item)
        }
    }
}

extension PrivacyMonitor: RtcListener {
    func onJoinChannelSuccess() {
        queue.async { [weak self] in
            self?.hasJoinedChannel = true
            DevTracker.post(.criticalPath(.rtc_join_channel))
        }
    }

    func onRejoinChannelSuccess() {
        queue.async { [weak self] in
            self?.hasJoinedChannel = true
            DevTracker.post(.criticalPath(.rtc_rejoin_channel))
        }
    }

    func didLeaveChannel() {
        queue.async { [weak self] in
            guard let self = self else { return }
            if let unlockTime = self.unlockTime {
                let duration = CACurrentMediaTime() - unlockTime
                Self.logger.info("Time interval from unlocking module to leaving channel: \(duration)s")
                DevTracker.post(.criticalPath(.rtc_leave_channel).params([.duration: duration]))
            }
            // 不管此时有没有开始一个新会议，都可以安全地将 unlockTime 置空
            self.unlockTime = nil
            self.hasJoinedChannel = false
            self.unregisterTask?.perform()
        }
    }
}

extension PrivacyMonitor: MeetingManagerListener {
    func didCreateMeetingSession(_ session: MeetingSession) {
        session.addListener(self)
    }

    func didLeaveMeetingSession(_ session: MeetingSession, event: MeetingEvent) {
    }
}

extension PrivacyMonitor: MeetingSessionListener {
    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {
        let sessionId = session.sessionId
        Self.logger.info("Session(\(sessionId)) didEnterState isPending = \(session.isPending), from = \(from), to = \(state)")
        guard !session.isPending else { return }
        queue.async { [weak self] in
            if from == .start && state != .end {
                self?.didEnterMeeting(sessionId: sessionId)
            } else if state == .end {
                self?.didLeaveMeeting(sessionId: sessionId)
            }
        }
    }

    func didLeavePending(session: MeetingSession) {
        let sessionId = session.sessionId
        Self.logger.info("Session(\(sessionId)) didLeavePending, state = \(session.state)")
        if session.state != .end {
            queue.async { [weak self] in
                self?.didEnterMeeting(sessionId: sessionId)
            }
        }
    }
}
