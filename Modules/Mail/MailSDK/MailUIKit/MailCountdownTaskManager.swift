//
//  MailCountdownTaskManager.swift
//  MailSDK
//
//  Created by Ender on 2023/5/18.
//

import Foundation

final class MailCountdownTaskManager {
    var timer: CADisplayLink?
    var timeLeave: Int64?
    var lastTimestamp: CFTimeInterval?
    var update: ((Int64) -> Void)?
    var complete: (() -> Void)?

    static let `default` = MailCountdownTaskManager()

    func initTask(timeSecond: Int64, onUpdate: ((Int64) -> Void)?, onComplete: (() -> Void)?) {
        timeLeave = timeSecond
        update = onUpdate
        complete = onComplete
        timing()
    }

    private func timing() {
        timer?.invalidate()
        timer = CADisplayLink(target: self, selector: #selector(updateHandler))
        if let newTimer = timer {
            newTimer.add(to: .main, forMode: .default)
            newTimer.preferredFramesPerSecond = 5
        }
    }

    @objc
    private func updateHandler() {
        guard var timeLeave = timeLeave else { return }
        guard let timer = self.timer else { return }
        if let timestamp = lastTimestamp {
            if timer.timestamp - timestamp >= 1 {
                timeLeave = timeLeave - 1
                lastTimestamp = timer.timestamp
            }
        } else {
            self.lastTimestamp = timer.timestamp
        }
        if timeLeave <= 0 {
            complete?()
            self.reset()
        } else {
            update?(timeLeave)
            self.timeLeave = timeLeave
        }
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        timeLeave = nil
        lastTimestamp = nil
        update = nil
        complete = nil
    }
}
