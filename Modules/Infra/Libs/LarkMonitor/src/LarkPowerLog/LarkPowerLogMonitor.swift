//
//  LarkPowerLogMonitor.swift
//  LarkMonitor
//
//  Created by yuanzhangjing on 2022/7/29.
//

import Foundation
import BootManager
import LKCommonsLogging
import LKCommonsTracker
import LarkRustClient
import RustPB
import LarkContainer
import RxSwift
import LarkSetting
import LarkSensitivityControl
import EEAtomic

private let logger = Logger.log(LarkPowerLogMonitor.self, category: "PowerLog")

public final class LarkPowerLogMonitorLaunchTask: FlowBootTask, Identifiable { //Global
    public static var identify = "PowerLogMonitorLaunchTask"
    
    public override func execute(_ context: BootContext) {
        DispatchQueue.global().async {
            LarkPowerLogMonitor.sharedInstance.execute()

            let val = Tracker.experimentValue(key: "optimize_hmd_power_enable", shouldExposure: true) as? Bool
            UserDefaults.standard.set(val, forKey: "optimize_hmd_power_enable")
        }
    }
}

private final class LarkPowerLogMonitor: NSObject, BDPowerLogManagerDelegate {
    
    let globalService = Container.shared.resolve(GlobalRustService.self)

    static let sharedInstance = LarkPowerLogMonitor()

    private let powerLogMonitorEvent = "power_log_monitor_event_dev"
    
    private let disposeBag = DisposeBag()
    
    private var startupSession : BDPowerLogSession?
    
    private var once = false
    
    private let startupDelay = 30
        
    @LazyRawSetting(key: UserSettingKey.make(userKeyLiteral: "lark_ios_powerlog_monitor_config")) private var powerlogSettings: [String: Any]?
    
    override init() {}
    
    func printInfoLog(_ log: String) {
        logger.info(log)
    }

    func printWarningLog(_ log: String) {
        logger.warn(log)
    }

    func printErrorLog(_ log: String) {
        logger.error(log)
    }
    
    func getifaddrs(_ ifaddrs_val: UnsafeMutablePointer<UnsafeMutablePointer<ifaddrs>?>!) -> Bool {
        do{
            try DeviceInfoEntry.getifaddrs(forToken: Token("LARK-PSDA-powerlog_net_traffic"), ifaddrs_val)
            return true
        } catch {
            logger.error("get ifaddrs error")
        }
        return false
    }

    func uploadLogInfo(_ logInfo: [AnyHashable: Any]?, extra: [AnyHashable: Any]?) {
        if logInfo == nil {
            return
        }
        var params = logInfo ?? [AnyHashable: Any]()
        if let e = extra {
            if JSONSerialization.isValidJSONObject(e) {
                let data = try? JSONSerialization.data(withJSONObject: e, options: JSONSerialization.WritingOptions(rawValue: 0))
                if let d = data {
                    params["extra"] = String(data: d, encoding: .utf8)
                }
            } else {
                params["extra"] = ""
            }
        }

        Tracker.post(TeaEvent(powerLogMonitorEvent, params: params))

        let metricKeys: [AnyHashable] = [
            "total_cpu_time",
            "total_cpu_usage",
            "total_time",
            "peak_cpu_usage",
            "device_cpu_active_time",
            "device_cpu_total_time",
            "device_cpu_usage",
            "thermal_critical_time",
            "thermal_fair_time",
            "thermal_nominal_time",
            "thermal_serious_time",
            "battery_level",
            "battery_level_cost",
            "battery_level_cost_speed",
            "brightness",
            "num_of_cores",
            "num_of_active_cores",
            "start_ts",
            "end_ts",
            "parent_session_start_ts",
            "parent_session_end_ts",
            "parent_session_duration"
        ]

        var metric = [AnyHashable: Any]()
        var category = [AnyHashable: Any]()

        if let l = logInfo {
            for item in l {
                if metricKeys.contains(item.key) {
                    metric[item.key] = item.value
                } else {
                    category[item.key] = item.value
                }
            }
        }

        Tracker.post(SlardarEvent(name: powerLogMonitorEvent, metric: metric, category: category, extra: extra ?? [:]))
    }
    
    func uploadEvent(_ event: String, logInfo: [AnyHashable : Any]?, extra: [AnyHashable : Any]?) {
        if logInfo == nil {
            return
        }
        var params = logInfo ?? [AnyHashable: Any]()
        if let e = extra {
            if JSONSerialization.isValidJSONObject(e) {
                let data = try? JSONSerialization.data(withJSONObject: e, options: JSONSerialization.WritingOptions(rawValue: 0))
                if let d = data {
                    params["extra"] = String(data: d, encoding: .utf8)
                }
            } else {
                params["extra"] = ""
            }
        }
        
        Tracker.post(TeaEvent(event, params: params))
    }
    
    func transformNetEvent(reqData : Tool_V1_GetNetDetailMetricsReqData) -> BDPowerLogNetEvent {
        let ret  = BDPowerLogNetEvent()
        ret.startTime = reqData.startTs
        ret.endTime = reqData.endTs
        ret.sysTime = bd_powerlog_current_sys_ts()
        ret.sendBytes = reqData.sendBytes
        ret.recvBytes = reqData.recvBytes
        return ret
    }
    
    func transformIntervalData(intervalData : Tool_V1_GetNetDetailMetricsIntervalData) -> BDPowerLogNetMetricsInterval {
        let ret  = BDPowerLogNetMetricsInterval()
        ret.reqCount = intervalData.reqCnt
        ret.sendBytes = intervalData.sendBytes
        ret.recvBytes = intervalData.recvBytes
        if intervalData.hasFirstReq {
            ret.firstEvent = transformNetEvent(reqData: intervalData.firstReq)
        }
        if intervalData.hasLastReq {
            ret.lastEvent = transformNetEvent(reqData: intervalData.lastReq)
        }
        return ret
    }

    
    func transformNetMetrics(netMetricsResp : Tool_V1_GetNetMetricsResponse) -> BDPowerLogNetMetrics {
        let ret  = BDPowerLogNetMetrics()
        ret.reqCount = netMetricsResp.reqCnt
        ret.lastReqTime = netMetricsResp.lastReqTs
        ret.sendBytes = netMetricsResp.sendBytes
        ret.recvBytes = netMetricsResp.recvBytes
        ret.timestamp = bd_powerlog_current_ts()
        if !netMetricsResp.detailDatas.isEmpty {
            ret.intervalDatas =  []
            for (index, item) in netMetricsResp.detailDatas.enumerated() {
                ret.intervalDatas?.append(transformIntervalData(intervalData: item))
            }
        }
        return ret
    }
    
    func collectNetMetrics() -> BDPowerLogNetMetrics? {
        var ret:BDPowerLogNetMetrics?
        let request = RustPB.Tool_V1_GetNetMetricsRequest()
        globalService?.sendSyncRequest(request).subscribe { [self] (response: Tool_V1_GetNetMetricsResponse) in
            ret = self.transformNetMetrics(netMetricsResp: response)
        } onError: { error in
            logger.info("collectNetMetrics error \(error)")
        }.disposed(by: disposeBag)
        return ret
    }
    
    func execute() {
        
        var enablePowerMonitor = true
        
        var enableStartUpSession = false
        if let settings = powerlogSettings {
            if let val = settings["enable_powerlog_monitor"] as? Bool {
                enablePowerMonitor = val
            }
            
            if let val = settings["enable_startup_session"] as? Bool {
                enableStartUpSession = val
            }
            
            if let val = settings["optimize_config"] as? Dictionary<AnyHashable, Any> {
                LarkPowerOptimizeConfig.update(val)
            }
        }
        
        logger.info("powerlog monitor is \(enablePowerMonitor)")

        if enablePowerMonitor {
            
            self.setupLogMonitor()
            
            start()
            
            if enableStartUpSession {
                self.collectStartUpSession()
            }
        } else {
            stop()
        }
    }

    func start() {
        let config = BDPowerLogConfig()
        
        if let settings = powerlogSettings {
            
            logger.info("powerlog settings = \(settings)")
            
            if let val = settings["enable_net_metrics"] as? Bool {
                config.enableNetMonitor = val
            }
            
            if let val = settings["enable_net_urlsession_metrics"] as? Bool {
                config.enableURLSessionMetrics = val
            }
            
            let highpowerConfig = BDPowerLogHighPowerConfig()
            
            if let val = settings["enable"] as? Bool {
                highpowerConfig.enable = val
            }
            
            if let val = settings["app_time_window"] as? Int32 {
                highpowerConfig.appTimeWindow = val
            }
            if let val = settings["app_cpu_time_threshold"] as? Int32 {
                highpowerConfig.appCPUTimeThreshold = val
            }
            if let val = settings["app_time_window_max"] as? Int32 {
                highpowerConfig.appTimeWindowMax = val
            }
            
            if let val = settings["device_time_window"] as? Int32 {
                highpowerConfig.deviceTimeWindow = val
            }
            if let val = settings["device_cpu_time_threshold"] as? Int32 {
                highpowerConfig.deviceCPUTimeThreshold = val
            }
            if let val = settings["device_time_window_max"] as? Int32 {
                highpowerConfig.deviceTimeWindowMax = val
            }
            
            if let val = settings["enable_stack_sample"] as? Bool {
                highpowerConfig.enableStackSample = val
            }
            if let val = settings["stack_sample_interval"] as? Double {
                highpowerConfig.stackSampleInterval = val
            }
            
            if let val = settings["stack_sample_thread_count"] as? Int32 {
                highpowerConfig.stackSampleThreadCount = val
            }
            
            if let val = settings["stack_sample_thread_usage_threshold"] as? Double {
                highpowerConfig.stackSampleThreadUsageThreshold = val
            }
            
            if let val = settings["stack_sample_cool_down_interval"] as? Int32 {
                highpowerConfig.stackSampleCoolDownInterval = val
            }
            
            if let val = settings["enable_scene_update_session"] as? Bool {
                config.enableSceneUpdateSession = val
            }

            if let val = settings["scene_update_session_min_time"] as? Int32 {
                config.sceneUpdateSessionMinTime = val
            }
            
            if let val = settings["ignore_scene_update_background_session"] as? Bool {
                config.ignoreSceneUpdateBackgroundSession = val
            }
            
            config.highpowerConfig = highpowerConfig
            
            if let val = settings["subscene_config"] as? Dictionary<AnyHashable, Any> {
                config.subsceneConfig = val
            }
            
            if let val = settings["enable_webkit_monitor"] as? Bool {
                config.enableWebKitMonitor = val
            }
        } else {
            logger.info("powerlog settings is null")
        }
        
        if (config.subsceneConfig == nil) {
            var floatingMeetingConfig = [AnyHashable: Any]()
            let vc: [AnyHashable] = [
                "ByteView.FloatingInMeetingViewController"
            ]
            let window: [AnyHashable] = [
                "LarkSuspendable.SuspendWindow",
                "ByteView.FloatingWindow"
            ]
            floatingMeetingConfig["vc"] = vc
            floatingMeetingConfig["window"] = window
            var defaultSubsceneConfig = [AnyHashable: Any]()
            defaultSubsceneConfig["floating_meeting"] = floatingMeetingConfig
            config.subsceneConfig = defaultSubsceneConfig
        }
        
        BDPowerLogManager.config = config
        BDPowerLogManager.start()
        BDPowerLogManager.delegate = self
        logger.info("powerlog monitor start, net monitor=\(config.enableNetMonitor), urlsession metrics=\(config.enableURLSessionMetrics)")
    }

    func stop() {
        BDPowerLogManager.delegate = nil
        BDPowerLogManager.stop()
        logger.info("powerlog monitor stop")
    }
    
    func setupLogMonitor() {
        _ = SettingManager.shared.observe(key: .make(userKeyLiteral: "lark_ios_powerlog_monitor_config")) //Global
            .subscribe(onNext: { (value) in
                // 涉及到 Any 类型读写，不做 lark_storage 检查
                // lint:disable lark_storage_check
                if let logMonitorConfig = value["log_monitor_config"] as? Dictionary<String, Any> {
                    UserDefaults.standard.set(logMonitorConfig, forKey: "lark_log_monitor_config")
                } else {
                    UserDefaults.standard.removeObject(forKey: "lark_log_monitor_config")
                }
                // lint:enable lark_storage_check
            })
    }
    
    @objc func didEnterBackground() {
        if let s = self.startupSession {
            BDPowerLogManager.end(s)
            self.startupSession = nil
        }
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    func collectStartUpSession() {
        if BDPowerLogManager.isRunning() {
            DispatchQueue.main.async { [self] in
                if self.once {
                    return
                }
                self.once = true
                
                let config = BDPowerLogSessionConfig()
                config.uploadWhenAppStateChanged = false
                config.ignoreBackground = true
                self.startupSession = BDPowerLogManager.beginSession("startup", config: config)
                
                NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(startupDelay), execute: {
                    if let s = self.startupSession {
                        BDPowerLogManager.end(s)
                        self.startupSession = nil
                    }
                })
            }
        }
    }
}
