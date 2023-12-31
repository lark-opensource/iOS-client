//
//  RunloopMonitor.swift
//  RunloopTools
//
//  Created by KT on 2019/9/18.
//

import UIKit
import Foundation
import os.signpost
import LKCommonsLogging

/// Release 记录卡顿到日志，Debug输出signpost打点
public final class RunloopMonitor {
    public static var shared = RunloopMonitor()

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
    }

    @objc
    private func didEnterBackground() {
        self.lastRunloopStartTime = nil
        self.enable = false
    }

    @objc
    private func willEnterForeground() {
        self.lastRunloopStartTime = nil
        self.enable = true
    }

    #if DEBUG
    private var enable = true
    #else
    private var enable = false // Release 只有前台监测
    #endif

    private var runLoopCount: UInt64 = 0
    private var lastRunloopStartTime: CFAbsoluteTime?
    private let osLogger = OSLog(subsystem: "Lark", category: "RunLoop")
    private static let logger = Logger.log(RunloopMonitor.self)

    public func startRunLoopObserver() {
        let activityToObserve: CFRunLoopActivity = [.beforeTimers]
        let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, activityToObserve.rawValue, true, 0) { [weak self] (_, activity) in
            guard let self = self, self.enable, activity == .beforeTimers else { return }

            let current = CFAbsoluteTimeGetCurrent()
            if let lastTime = self.lastRunloopStartTime {
                let elapsed = current - lastTime
                // >400ms 日志记录卡顿
                if elapsed > 0.4 {
                    let during = String(elapsed)
                    RunloopMonitor.logger.error("Last Runloop Cost: " + during)
                }
            }
            self.lastRunloopStartTime = current

            // signpost 打点
            #if DEBUG
            guard #available(iOS 12.0, *) else { return }
            os_signpost(.end, log: self.osLogger, name: "RunLoop", signpostID: .init(self.runLoopCount))
            self.runLoopCount = (self.runLoopCount + 1) & UInt64.max
            os_signpost(.begin, log: self.osLogger, name: "RunLoop", signpostID: .init(self.runLoopCount))
            #endif
        }
        CFRunLoopAddObserver(RunLoop.main.getCFRunLoop(), observer, CFRunLoopMode.commonModes)
    }
}
