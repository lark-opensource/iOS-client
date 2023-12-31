//
//  LarkMemoryPressureMonitor.swift
//  LarkMonitor-LarkMonitorAuto
//  内存压力监听
//  Created by CL7R on 2022/7/7.
//

import Foundation
import LKCommonsTracker
import LKCommonsLogging
import BootManager
import Heimdallr

public final class LarkMemoryPressureMonitor: FlowBootTask, Identifiable { //Global
    public static var identify = "MemoryPressureMonitorLaunchTask"

    public override var runOnlyOnce: Bool {
        return true
    }

    public override func execute(_ context: BootContext) {
        MemoryPressureMonitor.addNotification()
    }
}

private final class MemoryPressureMonitor {

    private static let memoryPressureEvent = "memory_pressure_monitor"

    private static let logger = Logger.log(MemoryPressureMonitor.self)

    static func addNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(memoryPressureWarningAction(_:)),
                                               name: NSNotification.Name(rawValue: KHMDMemoryMonitorMemoryWarningNotificationName),
                                               object: nil)
    }

    @objc static func memoryPressureWarningAction(_ noti: NSNotification) {
        var memoryPressueCategory: [String: Any] = [:]
        var memoryPressueExtra: [String: Any] = [:]
        var memoryValue: [String: Any] = [:]
        let userInfo = noti.userInfo
        let memoryPressureTypeValue = userInfo?["type"] as? Int32
        // 获取App和system使用内存
        let memoryBytes = hmd_getMemoryBytes()
        let appMemory = memoryBytes.appMemory / 1024 / 1024
        let sysMemory = memoryBytes.usedMemory / 1024 / 1024
        memoryValue["app_memory"] = appMemory
        memoryValue["system_memory"] = sysMemory
        // 内存压力类型
        switch memoryPressureTypeValue {
        case 2:
            memoryPressueCategory["memory_pressure_type"] = -1
        case 4:
            memoryPressueCategory["memory_pressure_type"] = 0
        case 8:
            memoryPressueCategory["memory_pressure_type"] = 1
        case 16:
            memoryPressueCategory["memory_pressure_type"] = 2
            memoryPressueCategory["memory_pressure_scene"] = HMDUITrackerManager.shared().scene
        case 32:
            memoryPressueCategory["memory_pressure_type"] = 4
            memoryPressueCategory["memory_pressure_scene"] = HMDUITrackerManager.shared().scene
        case 128:
            memoryPressueCategory["memory_pressure_type"] = 16
            memoryPressueCategory["memory_pressure_scene"] = HMDUITrackerManager.shared().scene
        default:
            memoryPressueCategory["memory_pressure_type"] = -2
        }
        memoryPressueCategory["scene"] = HMDUITrackerManager.shared().scene
        memoryPressueExtra["lastScene"] = HMDUITrackerManager.shared().lastScene
        logger.info("[memoryPressure-log] \(memoryPressueCategory["memory_pressure_type"]), " +
                    "appMemory = \(appMemory), sysMemory = \(sysMemory), " +
                    "scene = \(memoryPressueCategory["scene"]), lastScene = \(memoryPressueExtra["lastScene"])")
        Tracker.post(SlardarEvent(name: memoryPressureEvent,
                                  metric: memoryValue,
                                  category: memoryPressueCategory,
                                  extra: memoryPressueExtra))
    }
}
