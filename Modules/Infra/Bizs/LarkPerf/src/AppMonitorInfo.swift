//
//  AppMonitorInfo.swift
//  LarkPerf
//
//  Created by qihongye on 2020/6/23.
//

import UIKit
import Foundation

/// App monitor info for startupTimeStamp and enterForegroundTimeStamp
public final class AppMonitor {
    /// shared
    public static let shared = AppMonitor()

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppMonitor.applicationWillResignActiveNotification),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppMonitor.applicationDidBecomeActiveNotification),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppMonitor.applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(AppMonitor.applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    /// start appMonitor
    @inline(__always)
    public func startMonitor() {
        LagFrequencyMonitor.shared.start()
        NetFlowMonitor.shared.start()
    }

    /// regist rust flow
    /// - Parameter rustFlow: rustflow callback
    @inline(__always)
    public func registRustFlow(rustFlow: @escaping RustFlow) {
        NetFlowMonitor.shared.updateRustFlow(rustFlow: rustFlow)
    }
    /// Return app startup timestamp which set by `initStartupTimeStamp()`.
    /// - Returns:Millisecond timestamp startup
    @inline(__always)
    public static func getStartupTimeStamp() -> CFTimeInterval {
        return app_monitor_get_startup_timestamp()
    }

    /// Return latest enter foreground timestamp which set by `initStartupTimeStamp()`.
    /// - Returns: Millisecond timestamp enter foreground
    @inline(__always)
    public static func getEnterForegroundTimeStamp() -> CFTimeInterval {
        return app_monitor_get_enter_foreground_timestamp()
    }

    /// Called inside `UIApplication.applicationDidEnterBackground`
    @objc
    func applicationDidEnterBackground() {
        LagFrequencyMonitor.shared.end()
        NetFlowMonitor.shared.end()
        CoreEventMonitor.didEnterBackground()
    }

    /// Called inside `UIApplication.applicationWillEnterForeground`
    @objc
    func applicationWillEnterForeground() {
        Self.setEnterForegroundTimeStamp()
        LagFrequencyMonitor.shared.start()
        NetFlowMonitor.shared.start()
    }

    @objc
    func applicationWillResignActiveNotification() {

    }

    @objc
    func applicationDidBecomeActiveNotification() {

    }

    @discardableResult
    @inline(__always)
    static func initStartupTimeStamp() -> CFTimeInterval {
        let timestamp = CACurrentMediaTime() * 1_000
        app_monitor_set_startup_timestamp(timestamp)
        return timestamp
    }

    @inline(__always)
    static func setEnterForegroundTimeStamp() {
        app_monitor_set_enter_foreground_timestamp(CACurrentMediaTime() * 1_000)
    }

    @inline(__always)
    static func getMillisecondSinceStartup(_ currentTimeStamp: CFTimeInterval) -> CFTimeInterval {
        return currentTimeStamp - app_monitor_get_startup_timestamp()
    }

    @inline(__always)
    static func getMillisecondSinceForeground(_ currentTimeStamp: CFTimeInterval) -> CFTimeInterval {
        let latestForegroundTimestamp = app_monitor_get_enter_foreground_timestamp()
        if latestForegroundTimestamp == 0 {
            return getMillisecondSinceStartup(currentTimeStamp)
        }
        return currentTimeStamp - latestForegroundTimestamp
    }
}
