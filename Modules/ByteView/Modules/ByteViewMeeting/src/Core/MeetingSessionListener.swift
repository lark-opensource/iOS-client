//
//  MeetingSessionListener.swift
//  ByteViewMeeting
//
//  Created by kiri on 2022/6/1.
//

import Foundation

public protocol MeetingSessionListener: AnyObject {
    func willEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession)
    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession)
    func didFailToExecuteEvent(_ event: MeetingEvent, session: MeetingSession, error: Error)
    func didLeavePending(session: MeetingSession)
}

public extension MeetingSessionListener {
    func willEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {}
    func didEnterState(_ state: MeetingState, from: MeetingState, event: MeetingEvent, session: MeetingSession) {}
    func didFailToExecuteEvent(_ event: MeetingEvent, session: MeetingSession, error: Error) {}
    func didLeavePending(session: MeetingSession) {}
}
