//
//  IdleTimerMonitor.swift
//  ByteView
//
//  Created by kiri on 2020/8/9.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation

final class IdleTimerMonitor {
    static let logger = Logger.util

    private static var isLastIdleTimerDisabled = false
    private static var runningCount = 0

    static func start() {
        Util.runInMainThread {
            runningCount += 1
            if runningCount > 1 {
                return
            }

            isLastIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
            logger.info("start idle timer monitoring, last status is \(isLastIdleTimerDisabled)")

            updateIdleTimer()
            NotificationCenter.default.addObserver(Self.self, selector: #selector(updateIdleTimer),
                                                   name: UIApplication.didBecomeActiveNotification, object: nil)
            NotificationCenter.default.addObserver(Self.self, selector: #selector(updateIdleTimer),
                                                   name: UIApplication.willResignActiveNotification, object: nil)
        }
    }

    static func stop() {
        Util.runInMainThread {
            runningCount -= 1
            if runningCount > 0 {
                return
            } else if runningCount < 0 {
                runningCount = 0
                return
            }

            NotificationCenter.default.removeObserver(Self.self)
            UIApplication.shared.isIdleTimerDisabled = isLastIdleTimerDisabled
            logger.info("idle timer status is \(UIApplication.shared.isIdleTimerDisabled)")
        }
    }

    @objc static private func updateIdleTimer() {
        Util.runInMainThread {
            let isIdleTimerDisabled = UIApplication.shared.applicationState == .active
            if isIdleTimerDisabled == UIApplication.shared.isIdleTimerDisabled {
                return
            }

            self.logger.info("idle timer disabled should be \(isIdleTimerDisabled)")
            UIApplication.shared.isIdleTimerDisabled = isIdleTimerDisabled
            self.logger.info("idle timer status is \(UIApplication.shared.isIdleTimerDisabled)")
        }
    }
}
