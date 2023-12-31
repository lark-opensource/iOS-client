//
//  LarkDowngradeConfig.swift
//  LarkDowngrade
//
//  Created by SniperYJ on 2023/9/1.
//

import Foundation

public struct LarkPerformanceStrategyConfig {
    var downgradeValue: Double = 0
    var upgradeValue: Double = 0
    var times: Double = 0
}

private let lowDeviceDowngradeDefaultValue: Double = 7.8
private let overCPUDowngradeDefaultValue: Double = 0.8
private let overCPUUpgradeDefaultValue: Double = 0.3
private let overDeviceCPUDowngradeDefaultValue: Double = 0.9
private let overDeviceCPUUpgradeDefaultValue: Double = 0.5
private let cpuCheckDefaultTimes: Double = 30
private let overMemoryDowngradeDefaultValue: Double = 100
private let overMemoryUpgradeDefaultValue: Double = 300
private let overTemperatureDowngradeDefaultValue: Double = 1.0
private let overTemperatureUpgradeDefaultValue: Double = 0.0
private let overTemperatureCheckDefaultTimes: Double = 30

/// downgradeConfig
public class LarkUniversalDowngradeConfig {
    private var rwlock = pthread_rwlock_t()
    var enableDowngrade: Bool = false
    var checkIntervalTime: Double = 60
    
    private var overCPUConfig = LarkPerformanceStrategyConfig()
    private var overDeviceCPUConfig = LarkPerformanceStrategyConfig()
    private var lowDeviceConfig = LarkPerformanceStrategyConfig()
    private var overMemoryConfig = LarkPerformanceStrategyConfig()
    private var overTemperatureConfig = LarkPerformanceStrategyConfig()

    private var availableTaskList: [String] = []
    
    public init() {
        pthread_rwlock_init(&self.rwlock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&self.rwlock)
    }

    func getAvailableTaskList() -> [String] {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self.availableTaskList
    }

    func getOverCPUConfig() -> LarkPerformanceStrategyConfig {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self.overCPUConfig
    }

    func getOverDeviceCPUConfig() -> LarkPerformanceStrategyConfig {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self.overDeviceCPUConfig
    }

    func getLowDeviceConfig() -> LarkPerformanceStrategyConfig {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self.lowDeviceConfig
    }

    func getOverMemoryConfig() -> LarkPerformanceStrategyConfig {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self.overMemoryConfig
    }

    func getOverTemperatureConfig() -> LarkPerformanceStrategyConfig {
        pthread_rwlock_rdlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        return self.overTemperatureConfig
    }

    /**
     defultconfig =  {
         "enable_downgrade": False,
         "checkIntervalTime": 60,
         "availableTasks": [
            "xxxTask",
            "xxxTask"
         ],
         "PerformanceStrategy": {
             "lowDevice": {
                 "downgradeValue": 7.8,
                 "upgradeValue": 10.0
             },
             "overCPU": {
                 "downgradeValue": 0.8,
                 "upgradeValue": 0.3,
                 "times": 30
             },
             "overDeviceCPU": {
                 "downgradeValue": 0.9,
                 "upgradeValue": 0.5,
                 "times": 30
             },
             "overMemory": {
                 "downgradeValue": 100,
                 "upgradeValue": 300,
             },
             "overTemperature": {
                 "downgradeValue": 1.0,
                 "upgradeValue": 0.0,
                 "times": 30
             }
         }
     }
     */
    /// updateConfigInfo
    /// - Parameter dictionary: Settings
    public func updateWithDic(dictionary: [String: Any]) {
        pthread_rwlock_wrlock(&self.rwlock)
        defer { pthread_rwlock_unlock(&self.rwlock) }
        self.enableDowngrade = dictionary["enableDowngrade"] as? Bool ?? false
        if !self.enableDowngrade {
            return
        }
        self.availableTaskList = dictionary["availableTasks"] as? [String] ?? []
        self.checkIntervalTime  = dictionary["checkIntervalTime"] as? Double ?? 60 //升级间隔
        if let performanceConfig = dictionary["PerformanceStrategy"] as? [String: Any?] {
            performanceConfig.keys.forEach { key in
                switch key {
                case "lowDevice":
                    if let lowDeviceConfig = performanceConfig["lowDevice"] as? [String: Any?] {
                        self.lowDeviceConfig.downgradeValue = lowDeviceConfig["downgradeValue"] as? Double ?? lowDeviceDowngradeDefaultValue
                    }
                    break
                case "overCPU":
                    if let overCPUConfig = performanceConfig["overCPU"] as? [String: Any?] {
                        self.overCPUConfig.downgradeValue = overCPUConfig["downgradeValue"] as? Double ?? overCPUDowngradeDefaultValue
                        self.overCPUConfig.upgradeValue = overCPUConfig["upgradeValue"] as? Double ?? overCPUUpgradeDefaultValue
                        self.overCPUConfig.times = overCPUConfig["times"] as? Double ?? cpuCheckDefaultTimes
                    }
                    break
                case "overDeviceCPU":
                    if let overDeviceCPUConfig = performanceConfig["overDeviceCPU"] as? [String: Any?] {
                        self.overDeviceCPUConfig.downgradeValue = overDeviceCPUConfig["downgradeValue"] as? Double ?? overDeviceCPUDowngradeDefaultValue
                        self.overDeviceCPUConfig.upgradeValue = overDeviceCPUConfig["upgradeValue"] as? Double ?? overDeviceCPUUpgradeDefaultValue
                        self.overDeviceCPUConfig.times = overDeviceCPUConfig["times"] as? Double ?? cpuCheckDefaultTimes
                    }
                    break
                case "overMemory":
                    if let overMemoryConfig = performanceConfig["overMemory"] as? [String: Any?] {
                        self.overMemoryConfig.downgradeValue = overMemoryConfig["downgradeValue"] as? Double ?? overMemoryDowngradeDefaultValue
                        self.overMemoryConfig.upgradeValue = overMemoryConfig["upgradeValue"] as? Double ?? overMemoryUpgradeDefaultValue
                    }
                    break
                case "overTemperature":
                    if let overTemperatureConfig = performanceConfig["overTemperature"] as? [String: Any?] {
                        self.overTemperatureConfig.downgradeValue = overTemperatureConfig["downgradeValue"] as? Double ?? overTemperatureDowngradeDefaultValue
                        self.overTemperatureConfig.upgradeValue = overTemperatureConfig["upgradeValue"] as? Double ?? overTemperatureUpgradeDefaultValue
                        self.overTemperatureConfig.times = overTemperatureConfig["times"] as? Double ?? overTemperatureCheckDefaultTimes
                    }
                    break
                default:
                    break
                }
            }
        }
    }
}
