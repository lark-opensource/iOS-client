//
//  TestExtension.swift
//  LarkFileSystemDev
//
//  Created by PGB on 2020/4/1.
//

import Foundation
@testable import LarkFileSystem

extension MonitorConfig: CustomStringConvertible {
    public convenience init?(configDict: [String: Any]) {
        guard let configName = configDict["config_name"] as? String,
            let classifications = configDict["classifications"] as? [String: [Any]],
            let operations = configDict["operations"] as? [String: String] else { return nil }
        var conditions: [Condition] = []
        for (classification, conditionDicts) in classifications {
            for conditionDict in conditionDicts {
                guard let conditionDict = conditionDict as? [String: String],
                    let regex = conditionDict["regex"] else { return nil }
                conditions.append(
                    Condition(classification: classification,
                              regex: regex,
                              type: ConditionType(rawValue: conditionDict["type"] ?? "all") ?? .all,
                              itemName: conditionDict["item_name"])
                )
            }
        }
        self.init(configName: configName,
                  maxLevel: configDict["max_level"] as? Int,
                  conditions: conditions,
                  operations: operations,
                  extra: configDict["extra"] as? [String: Any])
    }

    public var description: String {
        return [self.configName,
                self.maxLevel?.description,
                self.conditions.sorted { $0.regex > $1.regex }.map { $0.description }.description,
                self.operations.sorted { $0.key > $1.key }.description,
                self.extra?.sorted { $0.key > $1.key }.description]
            .description
    }
}

extension LarkDiskMonitor {
    public convenience init (configDict: [String: Any]) {
        let monitorConfigDicts = (configDict["configs"] as? [[String: Any]]) ?? []
        let latestScannedDate = Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: LarkDiskMonitor.latestMonitoredTimestampKey))
        let shouldRunDailyScan = !latestScannedDate.isSameDay(date: Date())
        let configs = monitorConfigDicts.compactMap { MonitorConfig(configDict: $0) }.filter { config in
            // 其他配置，保证最多一天执行一次
            return config.configName == "problem_solving" || shouldRunDailyScan
        }
        self.init(monitorConfigs: configs)
    }
}

extension Condition: CustomStringConvertible {
    public var description: String {
        return [self.classification,
                self.regex,
                self.type.rawValue,
                self.itemName].description
    }
}
