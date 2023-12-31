//
//  JoinMeetingQueue.swift
//  ByteView
//
//  Created by kiri on 2022/7/28.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting

final class JoinMeetingQueue {
    static let shared = JoinMeetingQueue()

    private init() {}

    @RwAtomic
    private var suspendCount = 0
    private var suspendMessages: [JoinMeetingMessage] = []

    // 挂起队列要实时，不能排队
    func suspend() {
        self.suspendCount += 1
    }

    // 恢复队列可以不着急
    func resume() {
        Queue.join.async {
            if self.suspendCount > 0 {
                self.suspendCount -= 1
            }
            if self.suspendCount == 0 {
                let messages = self.suspendMessages
                self.suspendMessages = []
                messages.forEach {
                    self.send($0)
                }
            }
        }
    }

    func send(_ message: JoinMeetingMessage) {
        Queue.join.async {
            if self.suspendCount > 0 {
                self.suspendMessages.append(message)
                return
            }
            MeetingManager.shared.handlePushMessage(message)
        }
    }

    private enum Queue {
        static let join = DispatchQueue(label: "ByteView.Private.JoinMeetingMessage", qos: .userInitiated)
    }
}

private extension MeetingManager {
    func handlePushMessage(_ message: JoinMeetingMessage) {
        let info = message.info
        if let sessionId = message.sessionId {
            if let session = findSession(sessionId: sessionId), !session.isEnd {
                session.sendToMachine(info: info)
            } else {
                Logger.meeting.error("handlePushMessage skipped, terminated session: MeetingSession(\(sessionId))[\(info.id)]")
            }
        } else if let factory = message.dependency {
            do {
                let dependency = try factory()
                let account = dependency.account
                if !account.isForegroundUser {
                    Logger.meeting.error("handlePushMessage skipped, user is not foregroundUser: \(account.userId)")
                    return
                }
                if MeetingTerminationCache.shared.isTerminated(info: info, account: account.user) {
                    Logger.meeting.error("handlePushMessage skipped: \(info.id) is terminated")
                    return
                }
                if !info.checkMyself(account.user) {
                    Logger.meeting.error("handlePushMessage skipped, checkMyself failed: \(account.user)")
                    return
                }
                startMeeting(.push(message), dependency: dependency, from: nil)
            } catch {
                Logger.meeting.error("handlePushMessage failed, cannot resolve dependency: \(error)")
            }
        }
    }
}
