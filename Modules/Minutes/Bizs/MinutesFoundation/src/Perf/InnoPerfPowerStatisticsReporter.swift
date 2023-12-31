//
//  InnoPerfPowerStatisticsReporter.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/7/15.
//

import Foundation
import LKCommonsTracker
import Heimdallr

class InnoPerfPowerStatisticsReporter: Reporter {
    var category: [String: Any] = [:]
    var extra: [String: Any] = [:]

    let queue: DispatchQueue

    var currentWorkItem: DispatchWorkItem?

    @SyncedSetting private var config: VCInnoPerfConfig?
    var period: Int {
        return config?.powerReportInterval ?? 60
    }

    var lastTrackTime: Double?
    var lastLevel: Float?

    var metric: [String: Any] {
        let now = CFAbsoluteTimeGetCurrent()
        var value: [String: Any] = [:]
        value["thermal_state"] = ProcessInfo.processInfo.thermalState.rawValue

        value["start_level"] = lastLevel

        let endLevel = UIDevice.current.batteryLevel
        value["end_level"] = endLevel
        lastLevel = endLevel

        if let lastTime = lastTrackTime {
            let duration = Int((now - lastTime) * 1000)
            value["duration"] = duration
        }

        lastTrackTime = now

        return value
    }

    init(workQueue: DispatchQueue) {
        queue = workQueue
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(self, selector: #selector(batteryMonitorChanged),
                                               name: UIDevice.batteryStateDidChangeNotification,
                                               object: nil)

    }

    @objc private func batteryMonitorChanged(forcedStop: Bool = false) {
        guard currentWorkItem != nil else {
            return
        }

        fire(keepAlive: true, category: category)
    }

    func track() {
        let metric = self.metric
        var extra = self.extra
        extra["powerSaving"] = ProcessInfo.processInfo.isLowPowerModeEnabled

        var category = self.category
        category["sub_scene"] = HMDUITrackerManager.shared().scene
        category["is_plugging"] = (UIDevice.current.batteryState == .charging) || (UIDevice.current.batteryState == .full)
        #if DEBUG
        InnoPerfMonitor.logger.debug("inno_perf_power_statistics metric: \(metric), category: \(category), extra: \(extra)")
        #else
        let event = SlardarEvent(name: "inno_perf_power_statistics", metric: metric, category: category, extra: extra)
        Tracker.post(event)
        #endif
    }

    func perform() {
        let workItem = DispatchWorkItem { [weak self] in
            self?.track()
            self?.perform()
        }

        queue.asyncAfter(deadline: .now() + .seconds(period), execute: workItem)

        currentWorkItem = workItem
    }

    func fire(keepAlive: Bool, category: [String: Any]) {

        currentWorkItem?.cancel()
        currentWorkItem = nil

        queue.async {
            self.track()
            self.category = category
            if keepAlive {
                self.perform()
            }
        }

    }

    func update(extra: [String: Any]) {
        queue.async {
            self.extra = extra
        }
    }
}
