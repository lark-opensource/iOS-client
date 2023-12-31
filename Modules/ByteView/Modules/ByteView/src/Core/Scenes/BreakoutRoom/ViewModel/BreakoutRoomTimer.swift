//
//  BreakoutRoomTimer.swift
//  ByteView
//
//  Created by kiri on 2021/5/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

protocol BreakoutRoomTimerObsesrver: AnyObject {
    /// 分组讨论持续时长
    func breakoutRoomTimeDuration(_ time: TimeInterval)
    /// 主持人结束分组讨论
    func breakoutRoomWillEnd(total time: TimeInterval, closeReason: BreakoutRoomInfo.CloseReason)
    /// 分组讨论结束倒计时
    func breakoutRoomEndTimeDuration(_ time: TimeInterval, closeReason: BreakoutRoomInfo.CloseReason)
    /// 分组讨论剩余时长
    func breakoutRoomRemainingTime(_ time: TimeInterval?)
}

extension BreakoutRoomTimerObsesrver {
    func breakoutRoomTimeDuration(_ time: TimeInterval) {}
    func breakoutRoomWillEnd(total time: TimeInterval, closeReason: BreakoutRoomInfo.CloseReason) {}
    func breakoutRoomEndTimeDuration(_ time: TimeInterval, closeReason: BreakoutRoomInfo.CloseReason) {}
    func breakoutRoomRemainingTime(_ time: TimeInterval?) {}
}

final class BreakoutRoomTimer: InMeetDataListener {
    private let meeting: InMeetMeeting
    private var meetingDuration: TimeInterval = 0 {
        didSet { self.notifyRemainingTime() }
    }
    private var startTime: TimeInterval = 0
    private var startTimer: Timer?
    private var endTime: TimeInterval = 0
    private var endTimer: Timer?
    private var prevRoomInfo: BreakoutRoomInfo?

    var remainingTime: TimeInterval? {
        guard meeting.data.isBreakoutRoomAutoFinishEnabled else { return nil }
        guard let roomInfo = meeting.data.inMeetingInfo?.breakoutRoomInfos.first else { return nil }
        if roomInfo.status == .countDown { return 0 }
        if roomInfo.status != .onTheCall { return nil }
        return TimeInterval(roomInfo.finishFromStartTime / 1000) - meetingDuration
    }

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        setupDurationTimer()
    }

    private let observers = Listeners<BreakoutRoomTimerObsesrver>()
    func addObserver(_ observer: BreakoutRoomTimerObsesrver, fireImmediately: Bool = true) {
        observers.addListener(observer)
        if fireImmediately {
            if startTime > 0 {
                observer.breakoutRoomTimeDuration(startTime)
            }
            if endTime > 0 {
                let closeReason = meeting.data.breakoutRoomInfo?.closeReason ?? .unknown
                observer.breakoutRoomWillEnd(total: endTime, closeReason: closeReason)
                observer.breakoutRoomEndTimeDuration(endTime, closeReason: closeReason)
            }
        }
    }

    func invalid() {
        invalidStartTime()
        invalidEndTime()
    }

    private func setupDurationTimer() {
        self.meetingDuration = Date().timeIntervalSince(meeting.startTime)
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] (t) in
            if let self = self {
                self.meetingDuration = Date().timeIntervalSince(self.meeting.startTime)
            } else {
                t.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
    }

    private func setupStartTimer(_ first: TimeInterval) {
        Util.runInMainThread {
            self.startTime = first
            self.startTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
                if let self = self {
                    self.startTime += 1
                    self.notifyStartTime()
                } else {
                    t.invalidate()
                }
            }
        }
    }

    private func setupEndTimer(_ first: TimeInterval) {
        Util.runInMainThread {
            self.endTime = first
            self.endTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] t in
                if let self = self {
                    self.endTime -= 1
                    self.notifyEndTime()
                } else {
                    t.invalidate()
                }
            }
        }
    }

    private var breakoutRoomCountDownTime: TimeInterval {
        let settings = meeting.data.inMeetingInfo?.meetingSettings.breakoutRoomSettings
        if let settings = settings, settings.countdownEnabled { return settings.countdownDuration }
        return TimeInterval(0)
    }

    private func refreshTimers() {
        invalid()
        if let info = meeting.data.breakoutRoomInfo {
            let meetingST = meeting.info.startTime
            if info.status == .onTheCall {
                let gap = max(info.startTime - meetingST, 0) // ms
                let time = meetingDuration - TimeInterval(gap / 1000)
                setupStartTimer(round(time))
                Logger.breakoutRoom.debug("startTime = \(time) s, gap = \(gap) ms")
            } else if info.status == .countDown {
                let time = self.breakoutRoomCountDownTime
                guard time > 0 else { return }
                notifyEndTotalTime(floor(time))
                setupEndTimer(floor(time))
            }
        }
    }

    private func invalidStartTime() {
        startTimer?.invalidate()
        startTimer = nil
        startTime = 0
    }

    private func invalidEndTime() {
        endTimer?.invalidate()
        endTimer = nil
        endTime = 0
    }

    private func notifyStartTime() {
        observers.forEach { $0.breakoutRoomTimeDuration(startTime) }
    }

    private func notifyEndTotalTime(_ t: TimeInterval) {
        let closeReason = meeting.data.breakoutRoomInfo?.closeReason ?? .unknown
        observers.forEach { $0.breakoutRoomWillEnd(total: t, closeReason: closeReason) }
    }

    private func notifyEndTime() {
        let closeReason = meeting.data.breakoutRoomInfo?.closeReason ?? .unknown
        observers.forEach { $0.breakoutRoomEndTimeDuration(endTime, closeReason: closeReason) }
    }

    private func notifyRemainingTime() {
        guard let remainingTime = self.remainingTime else { return }
        observers.forEach { $0.breakoutRoomRemainingTime(remainingTime) }
    }
}

extension BreakoutRoomTimer: BreakoutRoomManagerObserver {
    func breakoutRoomInfoChanged(_ info: BreakoutRoomInfo?) {
        if info?.breakoutRoomId != self.prevRoomInfo?.breakoutRoomId || info?.status != self.prevRoomInfo?.status {
            self.prevRoomInfo = info
            refreshTimers()
        }
    }
}
