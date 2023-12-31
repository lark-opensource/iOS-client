//
//  LarkLoggerMonitor.swift
//  LarkMonitor
//
//  Created by ByteDance on 2023/4/18.
//

import Foundation

public class LarkLoggerMonitor {
    public static let shared = LarkLoggerMonitor()
    var rustlogMonitor : BDPLLogMonitor?
    var applogMonitor : BDPLLogMonitor?
    var slardarLogMonitor : BDPLLogMonitor?
    let lock = NSLock()
    public func setupRustlogMonitor() -> Bool {
        // lint:disable:next lark_storage_check
        if let logMonitorConfig = UserDefaults.standard.dictionary(forKey: "lark_log_monitor_config") {
            if let conf = logMonitorConfig["rustlog"] as? Dictionary<String,Any> {
                let enable = conf["enable"] as? Bool ?? false
                if enable {
                    lock.lock()
                    if rustlogMonitor == nil {
                        let config = BDPLLogMonitorConfig()
                        config.timewindow = conf["time_window"] as? Int32 ?? 60
                        config.logThreshold = conf["log_threshold"] as? Int32 ?? 6000
                        config.enableLogCountMetrics = conf["enable_log_count_metrics"] as? Bool ?? false
                        rustlogMonitor = BDPLLogMonitorManager.monitor(withType: "rustlog", config: config)
                    }
                    rustlogMonitor?.start()
                    lock.unlock()
                    return true
                }
            }
        }
        return false
    }
    
    public func addRustLog(category : String, function : String) -> Void {
        lock.lock()
        let monitor = rustlogMonitor
        lock.unlock()
        if let monitor {
            if (category.isEmpty) {
                monitor.addLog(function)
            } else {
                monitor.addLog(category)
            }
        }
    }
    
    public func setupApplogMonitor() -> Bool {
        // lint:disable:next lark_storage_check
        if let logMonitorConfig = UserDefaults.standard.dictionary(forKey: "lark_log_monitor_config") {
            if let conf = logMonitorConfig["applog"] as? Dictionary<String,Any> {
                let enable = conf["enable"] as? Bool ?? false
                if enable {
                    lock.lock()
                    if applogMonitor == nil {
                        let config = BDPLLogMonitorConfig()
                        config.timewindow = conf["time_window"] as? Int32 ?? 60
                        config.logThreshold = conf["log_threshold"] as? Int32 ?? 6000
                        config.enableLogCountMetrics = conf["enable_log_count_metrics"] as? Bool ?? false
                        applogMonitor = BDPLLogMonitorManager.monitor(withType: "applog", config: config)
                    }
                    applogMonitor?.start()
                    lock.unlock()
                    return true
                }
            }
        }
        return false
    }
    
    public func addApplog(category : String) -> Void {
        lock.lock()
        let monitor = applogMonitor
        lock.unlock()
        if let monitor {
            monitor.addLog(category)
        }
    }
    
    public func setupSlardarLogMonitor() -> Bool {
        // lint:disable:next lark_storage_check
        if let logMonitorConfig = UserDefaults.standard.dictionary(forKey: "lark_log_monitor_config") {
            if let conf = logMonitorConfig["slardar_log"] as? Dictionary<String,Any> {
                let enable = conf["enable"] as? Bool ?? false
                if enable {
                    lock.lock()
                    if slardarLogMonitor == nil {
                        let config = BDPLLogMonitorConfig()
                        config.timewindow = conf["time_window"] as? Int32 ?? 60
                        config.logThreshold = conf["log_threshold"] as? Int32 ?? 6000
                        config.enableLogCountMetrics = conf["enable_log_count_metrics"] as? Bool ?? false
                        slardarLogMonitor = BDPLLogMonitorManager.monitor(withType: "slardar_log", config: config)
                    }
                    slardarLogMonitor?.start()
                    lock.unlock()
                    return true
                }
            }
        }
        return false
    }
    
    public func addSlardarLog(category : String) -> Void {
        lock.lock()
        let monitor = slardarLogMonitor
        lock.unlock()
        if let monitor {
            monitor.addLog(category)
        }
    }
}

public extension LarkLoggerMonitor {
    func totalRustLogCount() -> UInt64 {
        lock.lock()
        let monitor = rustlogMonitor
        lock.unlock()
        if let monitor {
            if monitor.enable {
                return UInt64(monitor.totalLogCount)
            }
        }
        return 0
    }
}
