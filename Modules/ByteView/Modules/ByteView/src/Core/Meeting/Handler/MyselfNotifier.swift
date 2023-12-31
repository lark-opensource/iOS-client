//
//  MyselfNotifier.swift
//  ByteView
//
//  Created by kiri on 2022/6/14.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork

protocol MyselfListener: AnyObject {
    /// 除了初始值之外，myself的变化由allParticipants变化触发
    func didChangeMyself(_ myself: Participant, oldValue: Participant?)
}

/// 使用范围超出了OnTheCall，单独通知
final class MyselfNotifier: MeetingComponent {
    private let sessionId: String
    @RwAtomic
    private(set) var myself: Participant?
    private let listeners = Listeners<MyselfListener>()

    init?(session: MeetingSession, event: MeetingEvent, fromState: MeetingState) {
        self.sessionId = session.sessionId
    }

    func willReleaseComponent(session: MeetingSession, event: MeetingEvent, toState: MeetingState) {
    }

    func addListener(_ listener: MyselfListener, fireImmediately: Bool = true) {
        listeners.addListener(listener)
        if fireImmediately, let myself = self.myself {
            listener.didChangeMyself(myself, oldValue: nil)
        }
    }

    func removeListener(_ listener: MyselfListener) {
        listeners.removeListener(listener)
    }

    func update(_ myself: Participant, fireListeners: Bool = true) {
        if myself != self.myself {
            let oldValue = self.myself
            self.myself = myself

            if oldValue?.meetingRole == .webinarAttendee || myself.meetingRole == .webinarAttendee,
               oldValue?.meetingRole != myself.meetingRole {
                Logger.webinarRole.info("self participant role change \(oldValue?.meetingRole) --> \(myself.meetingRole)")
            }
            // fill tracker common params first
            TrackContext.shared.updateContext(for: sessionId, block: { $0.update(myself: myself) })
            if fireListeners {
                listeners.forEach {
                    $0.didChangeMyself(myself, oldValue: oldValue)
                }
            }
        }
    }

    func updateBinder(_ binder: Participant?) {
        myself?.binder = binder
    }
}

extension MeetingSession {
    /// 使用范围超出了OnTheCall，单独通知
    func addMyselfListener(_ listener: MyselfListener, fireImmediately: Bool = true) {
        component(for: MyselfNotifier.self)?.addListener(listener, fireImmediately: fireImmediately)
    }

    func removeMyselfListener(_ listener: MyselfListener) {
        component(for: MyselfNotifier.self)?.removeListener(listener)
    }

    var myself: Participant? {
        if state == .lobby || state == .prelobby { return nil }
        return component(for: MyselfNotifier.self)?.myself
    }
}
