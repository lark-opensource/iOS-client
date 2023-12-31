//
//  MeetingSessionTimeline.swift
//  ByteViewMeeting
//
//  Created by kiri on 2022/6/7.
//

import Foundation
import QuartzCore

struct MeetingSessionTimeline {
    let startTime: CFTimeInterval
    private(set) var endTime: CFTimeInterval?
    private(set) var stateTimelines: [StateTimeline]
    init(startTime: CFTimeInterval = CACurrentMediaTime()) {
        self.startTime = startTime
        self.stateTimelines = [StateTimeline(state: .start, startTime: startTime)]
    }

    mutating func transToState(_ state: MeetingState) {
        let time = CACurrentMediaTime()
        self.stateTimelines[self.stateTimelines.count - 1].endTime = time
        self.stateTimelines.append(StateTimeline(state: state, startTime: time))
        if state == .end {
            self.endTime = time
        }
    }

    func startTime(for state: MeetingState) -> CFTimeInterval? {
        stateTimelines.first { $0.state == state }?.startTime
    }

    struct StateTimeline {
        let state: MeetingState
        let startTime: CFTimeInterval
        var endTime: CFTimeInterval?

        fileprivate init(state: MeetingState, startTime: CFTimeInterval) {
            self.state = state
            self.startTime = startTime
        }
    }
}
