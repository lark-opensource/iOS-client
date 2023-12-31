//
//  LarkDiskMonitor.swift
//  DateToolsSwift
//
//  Created by PGB on 2020/3/16.
//

import Foundation
import LKCommonsTracker
import LKCommonsLogging
import RustPB

public class LarkDiskMonitor {
    static let eventName = "disk_size_monitor"
    static let latestMonitoredTimestampKey = "com.lark.larkFileSystem.latestMonitoredTimestamp"

    static let logger = Logger.log(LarkDiskMonitor.self, category: "LarkFileSystem.LarkDiskMonitor")

    let monitorConfigs: [MonitorConfig]

    public convenience init(rawConfig: RawConfig) {
        let latestScannedDate = Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: LarkDiskMonitor.latestMonitoredTimestampKey))
        let shouldRunDailyScan = !latestScannedDate.isSameDay(date: Date())
        let configs = rawConfig.configs.compactMap { MonitorConfig(rawConfig: $0) }.filter { config in
            // 其他配置，保证最多一天执行一次
            return config.configName == "problem_solving" || shouldRunDailyScan
        }
        self.init(monitorConfigs: configs)
    }

    public init (monitorConfigs: [MonitorConfig]) {
        self.monitorConfigs = monitorConfigs
    }

    public func run() {
        guard !monitorConfigs.isEmpty else { return }

        let scanner = LarkDiskScanner()
        let result: ScanResult = scanner.scan(from: "")
        var configTimeConsuming: [String: Double] = [:]
        for config in monitorConfigs {
            LarkDiskMonitor.logger.info("start executing monitor config: \(config.configName)")
            let start = Date()

            let classifiedFiles = config.classify(files: result.fileItems)
            let reassembledFiles = config.reassemble(classifiedFiles: classifiedFiles)
            config.operate(on: reassembledFiles)

            let totalTime = -start.timeIntervalSinceNow
            configTimeConsuming["time:"+config.configName] = totalTime
            LarkDiskMonitor.logger.info("finish executing monitor config: \(config.configName) in \(totalTime)s")
        }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: LarkDiskMonitor.latestMonitoredTimestampKey)
        Tracker.post(SlardarEvent(
            name: LarkDiskMonitor.eventName,
            metric: configTimeConsuming,
            category: [:],
            extra: [:])
        )
    }

}
