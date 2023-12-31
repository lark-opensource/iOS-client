//
//  ColdStartup.swift
//  LarkPerf
//
//  Created by KT on 2020/6/23.
//

import UIKit
import Foundation
import ThreadSafeDataStructure
import LKCommonsTracker
import LKCommonsLogging
import AppReciableSDK
import Heimdallr
import LarkPerfBase
import LarkStorage
import BootManager

/// 冷启动打点上报
public enum BootState {
    /// main开始执行
    case main
    /// 首屏UI渲染
    case firstRender
    /// 首屏数据UI渲染
    case firstScreenDataReady
    /// 最新数据UI渲染
    case fullDataReady
    //关键状态个数
    static var count = 4
    var slardarKey: String {
        switch self {
        case .main: return "main"
        case .firstRender: return "first_render"
        case .firstScreenDataReady: return "first_screen_data_ready"
        case .fullDataReady: return "full_data_ready"
        }
    }
}

/// 启动阶段用户可感知需要的耗时
public enum StateReciable: String {
    case stateReciableInit = "sdk_init"
    case stateReciableSetAccessToken = "sdk_set_access_token"
    case stateReciableGetFeedCards = "sdk_get_feed_cards"
}

/// 用户可感知上报的event
public enum ReciableEventType: String {
    case eventTypefeedFirstPaint = "feed_first_paint"
    case eventTypefirstFeedMeaningfulPaint = "first_feed_meaningful_paint"
}

/// 用户可感知上报error
public enum ReciableErrorType: Int {
    case reciableErrorTypeUnknown = 0
    case reciableErrorTypeNetwork = 1
    case reciableErrorTypeSDK = 2
}

/// 用户可感知启动来源
public enum ReciableSourceType: Int {
    case reciableSourceTypeUnknow = 0
    case reciableSourceTypeApp = 1
    case reciableSourceTypeNotification = 2
    case reciableSourceTypeLink = 3
}

public enum Operation: String {
    case databaseRekey = "database_rekey"
}

/// 冷启动打点上报
public final class ColdStartup {
    //单例，上报后释放
    public static var shared: ColdStartup? = ColdStartup()
    //端上耗时数据
    private var metric: SafeDictionary<BootState, TimeInterval> = [:] + .readWriteLock
    //rust耗时数据
    private var metricRust: SafeDictionary<StateReciable, TimeInterval> = [:] + .readWriteLock
    //可感知时间
    private var metricEvent: SafeArray<ReciableEventType> = [] + .readWriteLock
    
    //当前category
    public var category: String?
    //启动流程特殊耗时操作
    public var operation: Operation?
    //启动项
    public var launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    
    //标志位
    private var isReport: Bool = false
    private var isFirstFeedLoadFinish: Bool = false
    
    private static let logger = Logger.log("ColdStartup")
    private let lock = NSRecursiveLock()
   
    /*
     上报启动前CPU数据
     */
    //应用维度
    //应用cpu范围取值数组
    var appCpuValues: [Double] = []
    //应用cpu异常次数
    var appCpuWarnCount: Int = 0
    //应用cpu最大持续异常次数
    var appCpuWarnMaxDuring: Int = 0
    //应用CPU当前持续异常数
    var appCpuWarnDuring: Int = 0
    
    //设备维度
    //设备cpu范围取值数组
    var deviceCpuValues: [Double] = []
    //设备cpu异常次数
    var deviceCpuWarnCount: Int = 0
    //设备cpu最大持续异常次数
    var deviceCpuWarnMaxDuring: Int = 0
    //设备CPU当前异常数
    var deviceCpuWarnDuring: Int = 0
    
    //检测CPU定时器
    var monitorTimer: Timer?
    //上一次CPU时间
    var preCpuInfoData: host_cpu_load_info_data_t?
    //监听循环次数
    var monitorCycleCount: Int = 0
    //应用Cpu持续正常次数
    var appCpuNormalCount: Int = 0
    //设备Cpu持续正常次数
    var deviceCpuNormalCount: Int = 0
    //设备cpu恢复正常
    var deviceCpuNormal: Bool = false
    //应用cpu恢复正常
    var appCpuNormal: Bool = false
    
    //启动流程性监控
    //是否有列表滚动
    var isScrollIng: Bool = false
    //是否需要停止监控
    var needStopFluencyMonitor: Bool = false
    //开始开始监控时间
    var startFluencyMonitorTime: CFTimeInterval = CACurrentMediaTime()

    //fps的值
    private var fpsArray: SafeArray<HMDFPSMonitorRecord> = [] + .readWriteLock
    //drop的值
    private var fpsDropArray: SafeArray<HMDFrameDropRecord> = [] + .readWriteLock
   
    //HMD
    private var fpsCallbackOject: HMDMonitorCallbackObject?
    private var fpsDropCallbackOject: HMDMonitorCallbackObject?
    
    // 只有bytest打包才执行，用来显示trace信息
    #if IS_BYTEST_PACKAGE
    private let bytestStartTime: Int64 = Int64(LarkProcessInfoPrivate.processStartTime())
    private var bytestTraceArr: Array = [Any]()
    private var isLoadFirstRender: Bool = false
    private var mainEndTime: Int64?
    #endif

    init() {
        AppStartupMonitor.shared.start(key: .startup)
    }
    
    /// 启动阶段用户可感知需要上报的耗时
    /// - Parameters:
    ///   - state: 方法
    ///   - cost: 耗时
    public func doForRust(_ state: StateReciable, _ cost: TimeInterval) {
        metricRust[state] = cost
    }

    /// 启动状态改变
    public func `do`(_ state: BootState) {
        hmd_launch_optmizer_mark_key_point(state.slardarKey)
        let interval = LarkProcessInfo.sinceStart()
        //设置从启动到执行到当前节点的耗时
        metric[state] = interval
        
        //组装bytest相关数据
        #if IS_BYTEST_PACKAGE
        if state == .main { //启动到执行到main
            var extraDic: [String: Any] = [:]
            extraDic["metric_name"] = "main"
            extraDic["start_time"] = bytestStartTime
            extraDic["end_time"] = Int64(Date().timeIntervalSince1970 * 1000)
            mainEndTime = Int64(Date().timeIntervalSince1970 * 1000)
            bytestTraceArr.append(extraDic)
        }
        if state == .firstRender { //启动到执行到首屏UI渲染
            isLoadFirstRender = true
            var extraDic: [String: Any] = [:]
            extraDic["metric_name"] = "first_ui_render"
            extraDic["start_time"] = bytestStartTime
            extraDic["end_time"] = Int64(Date().timeIntervalSince1970 * 1000)
            bytestTraceArr.append(extraDic)
            //框架关键节点信息
            if let mainEndTime = mainEndTime {
                BootMonitor.shared.keyNodeDic.forEach { (key: BootKeyNode, value: (TimeInterval, TimeInterval)) in
                    var extraDic: [String: Any] = [:]
                    extraDic["metric_name"] = key.rawValue
                    //需要加上main函数的时间，获取绝对时间
                    extraDic["start_time"] = Int64(value.0) * 1_000 + mainEndTime
                    extraDic["end_time"] = Int64(value.1) * 1_000 + mainEndTime
                    bytestTraceArr.append(extraDic)
                }
            }
        }
        if state == .firstScreenDataReady { //启动到首屏数据渲染
            isLoadFirstRender = true
            var extraDic: [String: Any] = [:]
            extraDic["metric_name"] = "first_data_render"
            extraDic["start_time"] = bytestStartTime
            extraDic["end_time"] = Int64(Date().timeIntervalSince1970 * 1000)
            bytestTraceArr.append(extraDic)
        }
        #endif
        if state == .main {
            #if !DEBUG
            //开始CPU监听
            self.reportStartCPUInfo()
            #endif
        }
        if state == .firstRender {
            #if !DEBUG
            //开始流畅性监听
            self.startFluencyMonitor()
            #endif
            //判断是否是暖启动（不太准）
            LarkProcessInfoPrivate.isWarmLaunch()
        }
        
        //在首屏数据同步完成后上报数据
        if metric.keys.count == BootState.count {
            self.report()
            if isFirstFeedLoadFinish {
                HMDLaunchOptimizer.shared().markLaunchFinished()
            }
        }
    }

    /// 上报
    public func report() {
        lock.lock()
        defer { lock.unlock() }
        guard
            let firstRender = metric[.firstRender],
            let firstScreenData = metric[.firstScreenDataReady],
            AppStartupMonitor.shared.isFastLogin == true,
            AppStartupMonitor.shared.isBackgroundLaunch != true,
            launchOptions == nil,
            isReport == false
            else {
                return
        }
        //启动阶段app性能相关数据
        var appMetric: [String: TimeInterval] = [:]
        //启动阶段耗时相关数据（native + rust）
        var appLatency: [String: TimeInterval] = [:]
        
        //获取启动类型，和pageFault个数
        var data: [String: TimeInterval] = [:]
        data["is_warm_launch"] = TimeInterval(LarkProcessInfoPrivate.isWarmLaunch())
        data["hard_pagefault_count"] = TimeInterval(LarkProcessInfoPrivate.getHardPageFault())
        appMetric["is_warm_launch"] = TimeInterval(LarkProcessInfoPrivate.isWarmLaunch())
        appMetric["hard_pagefault_count"] = TimeInterval(LarkProcessInfoPrivate.getHardPageFault())
        
        // 获取App和system使用内存
        let memoryBytes = hmd_getMemoryBytes()
        let appMemory = memoryBytes.appMemory / 1024 / 1024
        let sysMemory = memoryBytes.usedMemory / 1024 / 1024
        data["app_memory"] = TimeInterval(appMemory)
        data["system_memory"] = TimeInterval(sysMemory)
        appMetric["app_memory"] = TimeInterval(appMemory)
        appMetric["system_memory"] = TimeInterval(sysMemory)
        
        //端上相关节点的耗时
        // 首屏渲染和首屏数据刷新，取最大的，为用户感知的首屏数据
        let latency = max(firstRender, firstScreenData)
        metric.forEach {
            data[$0.key.slardarKey] = $0.value
            appLatency[$0.key.slardarKey] = $0.value
        }
        data["latency"] = latency
        appLatency["latency"] = latency
        
        //merge rust相关节点耗时
        metricRust.forEach { (key: StateReciable, value: TimeInterval) in
            appLatency[key.rawValue] = value
        }
        ColdStartup.logger.info("boot_report_feed_first_renderLatency:\(latency)--->appLatency:\(appLatency)--->appMetric:\(appMetric)")
        
        #if !DEBUG
        guard let tab = self.category else { return }
        let slardarQosMocker = (HMDLaunchOptimizer.shared().appliedLaunchOptimizerFeature().rawValue & HMDLaunchOptimizerFeature.threadQoSMocker.rawValue) > 0 ? 1 : 0
        let slardarKeyQueueCollector = (HMDLaunchOptimizer.shared().appliedLaunchOptimizerFeature().rawValue & HMDLaunchOptimizerFeature.keyQueueCollector.rawValue) > 0 ? 1 : 0
        var extra: [String: Any] = [:]
        if let oper = operation {
            extra["operation"] = oper.rawValue
        }
       
        #if IS_BYTEST_PACKAGE
        extra["metric_extra"] = bytestTraceArr
        Tracker.post(SlardarEvent(name: "cold_startup",
                                  metric: data,
                                  category: ["tab": tab, "slardar_qos_mocker": slardarQosMocker, "slardar_key_queue_collector": slardarKeyQueueCollector],
                                  extra: extra))
        #else
        Tracker.post(SlardarEvent(name: "cold_startup",
                                  metric: data,
                                  category: ["tab": tab, "slardar_qos_mocker": slardarQosMocker, "slardar_key_queue_collector": slardarKeyQueueCollector],
                                  extra: extra))
        
        #endif
        reportForAppReciable(.eventTypefeedFirstPaint, latency)
        #endif
        isReport = true
    }

    /// 用户可感知上报
    /// - Parameters:
    ///   - eventType: 上报类型
    ///   - cost: 耗时 ms
    public func reportForAppReciable(_ eventType: ReciableEventType, _ cost: TimeInterval) {
        var appLatencyDetail: [String: TimeInterval] = [:]
        var appMetric: [String: Any] = [:]
        var appCategory: [String: Any] = [:]
        var event = ""
        var isNeedNet = false
        
        //启动触发来源
        var sourceType: ReciableSourceType = .reciableSourceTypeApp
        if launchOptions == nil {
            sourceType = .reciableSourceTypeApp
        } else {
            if launchOptions![.url] != nil || launchOptions![.sourceApplication] != nil {
                sourceType = .reciableSourceTypeLink
            } else if launchOptions![.remoteNotification] != nil {
                sourceType = .reciableSourceTypeNotification
            } else {
                sourceType = .reciableSourceTypeUnknow
            }
        }

        //设置上报数据
        appLatencyDetail["main_excute"] = metric[.main]
        appLatencyDetail["feed_data_ready"] = metric[.firstScreenDataReady]
        appLatencyDetail["feed_first_paint"] = metric[.firstRender]
        appLatencyDetail["sdk_init"] = metricRust[.stateReciableInit]
        appLatencyDetail["sdk_set_access_token"] = metricRust[.stateReciableSetAccessToken]
        appLatencyDetail["sdk_get_feed_cards"] = metricRust[.stateReciableGetFeedCards]
        appCategory["source_type"] = sourceType.rawValue
        appCategory["ios_startup_type"] = LarkProcessInfoPrivate.isWarmLaunch()
        appCategory["is_cold_startup"] = (LarkProcessInfoPrivate.isWarmLaunch() == 0 ? true : false)
        appMetric["ios_hard_page_fault_count"] = LarkProcessInfoPrivate.getHardPageFault()
        appMetric["ios_soft_page_fault_count"] = LarkProcessInfoPrivate.getSoftPageFault()
        
        switch eventType {
        case .eventTypefeedFirstPaint:
            event = "feed_first_paint"
            isNeedNet = false
        case .eventTypefirstFeedMeaningfulPaint:
            event = "first_feed_meaningful_paint"
            isNeedNet = true
            // 用于性能防劣化的线下APM上报
            hmd_launch_optmizer_mark_key_point("first_feed_load_finish")
            let slardarQosMocker = (HMDLaunchOptimizer.shared().appliedLaunchOptimizerFeature().rawValue & HMDLaunchOptimizerFeature.threadQoSMocker.rawValue) > 0 ? 1 : 0
            let slardarKeyQueueCollector = (HMDLaunchOptimizer.shared().appliedLaunchOptimizerFeature().rawValue & HMDLaunchOptimizerFeature.keyQueueCollector.rawValue) > 0 ? 1 : 0
            
            //上报数据
            #if !DEBUG
            //bytest场景
            #if IS_BYTEST_PACKAGE
            var extraDic: [String: Any] = [:]
            extraDic["metric_name"] = "first_feed_load_finish"
            extraDic["start_time"] = bytestStartTime
            extraDic["end_time"] = Int64(Date().timeIntervalSince1970 * 1000)
            var extraArr = [extraDic]
            Tracker.post(SlardarEvent(name: "cold_startup",
                                      metric: ["first_feed_load_finish": Int(cost)],
                                      category: ["slardar_qos_mocker": slardarQosMocker, "slardar_key_queue_collector": slardarKeyQueueCollector],
                                      extra: ["metric_extra": extraArr]))
            #else
            Tracker.post(SlardarEvent(name: "cold_startup",
                                      metric: ["first_feed_load_finish": Int(cost)],
                                      category: ["slardar_qos_mocker": slardarQosMocker, "slardar_key_queue_collector": slardarKeyQueueCollector],
                                      extra: [:]))
            #endif
            isFirstFeedLoadFinish = true
            if isReport {
                HMDLaunchOptimizer.shared().markLaunchFinished()
            }
            #endif
        }
        
        #if !DEBUG
        //可感知上报
        AppReciableSDK.shared.timeCost(params: TimeCostParams(
            biz: .Messenger,
            scene: .Feed,
            event: Event(rawValue: event)!,
            cost: Int(cost),
            page: event,
            extra: Extra(
                isNeedNet: isNeedNet,
                latencyDetail: appLatencyDetail,
                metric: appMetric,
                category: appCategory)))
        #endif
    }

    /// 用户可感知错误
    /// - Parameters:
    ///   - errorType: 错误类型
    ///   - errorCode: 错误码
    public func reportForAppReciableError(_ errorType: ReciableErrorType, _ errorCode: Int) {
        var error = 0
        switch errorType {
        case .reciableErrorTypeUnknown:
            error = 0
        case .reciableErrorTypeNetwork:
            error = 1
        case .reciableErrorTypeSDK:
            error = 2
        }
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Feed,
                                                        event: .firstFeedMeaningfulPaint,
                                                        errorType: ErrorType(rawValue: error)!,
                                                        errorLevel: .Fatal,
                                                        errorCode: errorCode,
                                                        userAction: "",
                                                        page: nil,
                                                        errorMessage: ""))
    }

    /// 首次登录Feed 同步耗时
    /// - Parameter cost: 耗时 ms
    public func reportForAppReciableFirstFeed(_ cost: TimeInterval) {
        guard UserSpace.ColdStartup.firstLoginFlag else {
            return
        }
        AppReciableSDK.shared.timeCost(params: TimeCostParams(
            biz: .Messenger,
            scene: .Feed,
            event: .firstLoginFeedLoad,
            cost: Int(cost),
            page: nil,
            extra: Extra(
                isNeedNet: true,
                latencyDetail: nil,
                metric: nil,
                category: nil)))
    }

    /// 首次登录Feed 同步耗时
    /// - Parameters:
    ///   - errorType: 错误类型
    ///   - errorCode: 错误码
    public func reportForAppReciableFirstFeedError(_ errorType: ReciableErrorType, _ errorCode: Int) {
        guard UserSpace.ColdStartup.firstLoginFlag else {
            return
        }
        var error = 0
        switch errorType {
        case .reciableErrorTypeUnknown:
            error = 0
        case .reciableErrorTypeNetwork:
            error = 1
        case .reciableErrorTypeSDK:
            error = 2
        }
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Feed,
                                                        event: .firstLoginFeedLoad,
                                                        errorType: ErrorType(rawValue: error)!,
                                                        errorLevel: .Fatal,
                                                        errorCode: errorCode,
                                                        userAction: "",
                                                        page: nil,
                                                        errorMessage: ""))
    }

    static func clear() {
        ColdStartup.shared = nil
    }
}

//CPU和流畅性监听
extension ColdStartup {
    //MARK: 启动CPU监控
    //上报启动CPU信息
    func reportStartCPUInfo() {
        //判断fg是否开启
        guard KVPublic.FG.startCpuReportEnable.value() == true else {
            return
        }
        //只有获取到评分才上报
        guard let deviceScore = KVPublic.Common.deviceScore.value(), deviceScore > 0 else {
            return
        }
        //启动监听timer
        monitorTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(monitorCallback), userInfo: nil, repeats: true)
        if let curTimer: Timer = monitorTimer {
            RunLoop.main.add(curTimer, forMode: .common)
        }
    }
    
    //监听回调
    @objc
    func monitorCallback() {
        self.monitorCycleCount += 1
        //获取设备CPU数据
        let currentCpuInfoData = LarkPerfBase.devicCpuUsageClock()
        if let preCpuInfoData = preCpuInfoData {
        let deviceCpu = LarkPerfBase.devicCpuUsage(begin: preCpuInfoData, end: currentCpuInfoData)
            self.deviceCpuValues.append(deviceCpu)
            //处理CPU异常逻辑
            if deviceCpu > ColdStartCpuConfig.getCurrentDeviceCpuConfig(configType: .deviceCpuWarnRate) {
                self.deviceCpuWarnCount += 1
                self.deviceCpuWarnDuring += 1
            } else { //CPU正常,统计当前最大持续异常
                if self.deviceCpuWarnDuring > self.deviceCpuWarnMaxDuring {
                    self.deviceCpuWarnMaxDuring = self.deviceCpuWarnDuring
                }
                self.deviceCpuWarnDuring = 0
            }
            //检查CPU平稳逻辑
            if deviceCpu < ColdStartCpuConfig.getCurrentDeviceCpuConfig(configType: .deviceCpuNormalRate) {
                self.deviceCpuNormalCount += 1
                if self.deviceCpuNormalCount >= 3, !self.deviceCpuNormal {
                    self.deviceCpuNormal = true
                }
            } else {
                self.deviceCpuNormalCount = 0
            }
        }
        self.preCpuInfoData = currentCpuInfoData
       
        //获取App CPU使用率
        if Double(LarkPerfBase.cpuNum()) > 0 {
            //获取CPU使用率
            let appCpu = LarkPerfBase.larkPerfCpuUsage() / Double(LarkPerfBase.cpuNum())
            self.appCpuValues.append(appCpu)
            //处理CPU异常逻辑
            if appCpu > ColdStartCpuConfig.getCurrentDeviceCpuConfig(configType: .appCpuWarnRate) {
                self.appCpuWarnCount += 1
                self.appCpuWarnDuring += 1
            } else { //CPU正常,统计当前最大持续异常
                if self.appCpuWarnDuring > self.appCpuWarnMaxDuring {
                    self.appCpuWarnMaxDuring = self.appCpuWarnDuring
                }
                self.appCpuWarnDuring = 0
            }
            //处理CPU平稳逻辑
            if appCpu < ColdStartCpuConfig.getCurrentDeviceCpuConfig(configType: .appCpuNormalRate) {
                self.appCpuNormalCount += 1
                if self.appCpuNormalCount >= ColdStartCpuConfig.cpuIdleTime(), !self.appCpuNormal {
                    self.appCpuNormal = true
                }
            } else {
                self.appCpuNormalCount = 0
            }
        }
        //达到最大统计次数，或者设备和APP CPU都趋于正常并且统计时间不低于10秒，处理埋点上报逻辑
        if monitorCycleCount >= ColdStartCpuConfig.monitorCycleMaxCount() || (self.appCpuNormal && self.deviceCpuNormal && monitorCycleCount > 10) {
            //停止流畅性监听
            self.stopFluencyMonitor()
            //计算device CPU平均值
            var deviceCpuTotalValue: Double = 0
            self.deviceCpuValues.forEach { cpuValue in
                deviceCpuTotalValue += cpuValue
            }
            var deviceCpuAvgValue: Double = 0
            if self.monitorCycleCount > 1 {
                deviceCpuAvgValue = deviceCpuTotalValue / Double(self.monitorCycleCount - 1)
            }
            
            //计算app CPU平均值
            var appCpuTotalValue: Double = 0
            self.appCpuValues.forEach { cpuValue in
                appCpuTotalValue += cpuValue
            }
            var appCpuAvgValue: Double = 0
            if self.monitorCycleCount > 1 {
                appCpuAvgValue = appCpuTotalValue / Double(self.monitorCycleCount)
            }

            //上报埋点
            let param: [String: Any] = [
                "deviceCpuValues": self.deviceCpuValues,
                "appCpuValues": self.appCpuValues,
                "deviceCpuAvgValue": deviceCpuAvgValue,
                "appCpuAvgValue": appCpuAvgValue,
                "deviceCpuWarnCount": self.deviceCpuWarnCount,
                "appCpuWarnCount": self.appCpuWarnCount,
                "appCpuWarnMaxDuring": self.appCpuWarnMaxDuring,
                "deviceCpuWarnMaxDuring": self.deviceCpuWarnMaxDuring,
                "detectionTime": self.monitorCycleCount
            ]
            Tracker.post(TeaEvent("appr_cold_start_cpu", params: param))
            //移除监听。
            self.removeMonitor()
        }
    }
    
    //移除监听
    func removeMonitor() {
        if monitorTimer != nil {
            self.monitorCycleCount = 0
            monitorTimer?.invalidate()
            monitorTimer = nil
        }
    }
    /*
     开始监控
     */
    func startFluencyMonitor() {
        //判断fg是否开启
        guard KVPublic.FG.startCpuReportEnable.value() == true else {
            return
        }
        //开始全量监听
        HMDFPSMonitor.shared().resume()
        HMDFrameDropMonitor.shared().resume()
        
        //开始监听fps
        fpsCallbackOject = HMDFPSMonitor.shared().addCallbackObject { [weak self] record in
            self?.handleFPS(record: record)
        }
        //开始监听drop
        fpsDropCallbackOject = HMDFrameDropMonitor.shared().addCallbackObject { [weak self] record in
            self?.handleFPSDrop(record: record)
        }
    }

    /*
     停止监控
     */
    func stopFluencyMonitor(forceStop: Bool = false) {
        //如果停止监控的时候还在滚动，或者非强制停止，需要等待滚动停止之后再停止，否则最后一次滚动的丢帧无法上报。
        guard !self.isScrollIng || forceStop else {
            self.needStopFluencyMonitor = true
            return
        }
        //移除callback
        HMDFPSMonitor.shared().remove(fpsCallbackOject)
        HMDFrameDropMonitor.shared().remove(fpsDropCallbackOject)
        //移除全量监听
        HMDFPSMonitor.shared().suspend()
        HMDFrameDropMonitor.shared().suspend()
        
        //上报数据
        self.reportFluencyData()
    }
    
    //上报数据
    func reportFluencyData() {
        //上报埋点数据
        var reportParam: [String: Any] = [:]
        
        //监控时长
        let monitorDuration = CACurrentMediaTime() - self.startFluencyMonitorTime
        reportParam["monitorDuration"] = monitorDuration
        
        //统计fps的值
        var scrollFPSTotal: Double = 0
        var scrollFPSCount: Int = 0
        var fpsTotal: Double = 0
        var fpsCount: Int = 0
        self.fpsArray.forEach { fpsRecord in
            //滚动
            if fpsRecord.isScrolling {
                scrollFPSTotal += fpsRecord.fps
                scrollFPSCount += 1
            }
            //全场景
            fpsTotal += fpsRecord.fps
            fpsCount += 1
        }
        //滚动时fps值
        if scrollFPSCount > 0 {
            reportParam["scrollFPS"] = Double(scrollFPSTotal) / Double(scrollFPSCount)
        }
        //全场景FPS值
        if fpsCount > 0 {
            reportParam["fps"] = Double(fpsTotal) / Double(fpsCount)
        }
        
        //计算fpsdrop的值
        var slidingTime: Double = 0             //滑动总时长
        var hitchTime: Double = 0               //丢帧时长
        var threeHitchTime: Double = 0          //丢三帧时长
        var sevenHitchTime: Double = 0          //丢7帧时长
        var twentyFiveHitchTime: Double = 0     //丢25帧时长
        self.fpsDropArray.forEach { dropRecord in
            slidingTime += dropRecord.slidingTime  //累计滑行时间
            hitchTime += dropRecord.hitchDuration  //累计卡顿时长
            //丢帧时长
            if let hitchDurDic = dropRecord.hitchDurDic {
                for (key, value) in hitchDurDic {
                    //统计丢三帧以上时长
                    if let key = key as? String, let hitchCount = Int(key), hitchCount > 2, let hitchDurValue = value as? Double {
                        threeHitchTime += hitchDurValue
                    }
                    //统计丢七帧以上时长
                    if let key = key as? String, let hitchCount = Int(key), hitchCount > 6, let hitchDurValue = value as? Double {
                        sevenHitchTime += hitchDurValue
                    }
                    //统计丢二十五帧以上时长
                    if let key = key as? String, let hitchCount = Int(key), hitchCount > 24, let hitchDurValue = value as? Double {
                        twentyFiveHitchTime += hitchDurValue
                    }
                }
            }
        }
        if slidingTime > 0 {
            //丢帧时长率
            let hitchTimeRate = hitchTime / slidingTime
            reportParam["hitchTimeRate"] = hitchTimeRate
            //丢三帧时长率
            let threeHitchTimeRate = threeHitchTime / slidingTime
            reportParam["threeHitchTimeRate"] = threeHitchTimeRate
            //丢七帧时长率
            let sevenHitchTimeRate = sevenHitchTime / slidingTime
            reportParam["sevenHitchTimeRate"] = sevenHitchTimeRate
            //丢二十五帧时长率
            let twentyFiveHitchTimeRate = twentyFiveHitchTime / slidingTime
            reportParam["twentyFiveHitchTimeRate"] = twentyFiveHitchTimeRate
        }
        //上报埋点
        Tracker.post(TeaEvent("appr_cold_start_fluency", params: reportParam))
    }

    //处理fps回调
    private func handleFPS(record: HMDMonitorRecord?) {
        //如果返回的数据类型不是我们想要的强制停止，以免一直空转
        guard let record = record as? HMDFPSMonitorRecord else {
            self.stopFluencyMonitor(forceStop: true)
            return
        }
        //判断是否滚动
        self.isScrollIng = record.isScrolling
        fpsArray.append(record)
    
        //滚动停止，并且需要停止监听，停止监听
        if needStopFluencyMonitor, !self.isScrollIng {
            self.stopFluencyMonitor()
        }
    }

    //处理fpsDrop
    private func handleFPSDrop(record: HMDMonitorRecord?) {
        //如果返回的数据类型不是我们想要的强制停止，以免一直空转
        guard let fpsRecord = record as? HMDFrameDropRecord else {
            self.stopFluencyMonitor(forceStop: true)
            return
        }
        self.fpsDropArray.append(fpsRecord)
        //尝试暂停监控
        if needStopFluencyMonitor {
            self.stopFluencyMonitor(forceStop: true)
        }
    }
}
