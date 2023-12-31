//
//  LagFrequencyMonitor.swift
//  LarkPerf
//
//  Created by sniperj on 2020/6/23.
//

import UIKit
import Foundation
import LKCommonsLogging
import LKCommonsTracker
import Heimdallr

/// LagMonitor
public final class LagFrequencyMonitor {
    private static let serviceName = "app_lag_time"
    /// dispatch_once
    public static let shared = LagFrequencyMonitor()
    private let appStartTime = AppMonitor.getStartupTimeStamp()

    /// start Lag monitor
    public func start() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receiveANR),
                                               name: Notification.Name("HMDANROverNotification"),
                                               object: nil)
    }

    /// end Lag monitor
    public func end() {
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func receiveANR(_ noti: Notification) {
        if let info = noti.object as? HMDANRMonitorInfo {
            let sinceStartup = CACurrentMediaTime() * 1_000 - AppMonitor.getStartupTimeStamp()
            let sinceLatestEnterForeground = CACurrentMediaTime() * 1_000 - AppMonitor.getEnterForegroundTimeStamp()
            Tracker.post(SlardarEvent(name: LagFrequencyMonitor.serviceName,
                                      metric: ["latency": info.duration],
                                      category: ["proccess": "Lark"],
                                      extra: ["since_startup": sinceStartup,
                                              "since_latest_enter_foreground": sinceLatestEnterForeground]))
        }
    }
}
