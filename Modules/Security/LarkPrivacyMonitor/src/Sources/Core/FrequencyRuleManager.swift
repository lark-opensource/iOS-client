//
//  FrequencyRuleManager.swift
//  LarkPrivacyMonitor
//
//  Created by huanzhengjie on 2023/5/25.
//

import TSPrivacyKit

protocol MutexConfig {
    /// 频次阈值
    var maxCalledTimes: Int { get }
    /// 时间间隔
    var timeInterval: Int { get }
    /// 队列最大长度
    var maxStoreSize: Int { get }
}

/// api 维度配置
struct FrequencyApiMutexConfig: MutexConfig {
    let maxCalledTimes: Int
    let timeInterval: Int
    let maxStoreSize: Int
    let apiName: String
}

/// dataType 维度配置
struct FrequencyDataTypeMutexConfig: MutexConfig {
    let maxCalledTimes: Int
    let timeInterval: Int
    let maxStoreSize: Int
    let dataType: String
    /// 白名单
    let ignoreCondition: [String]?
}

/// 缓存事件
struct FrequencyEvent {
    let topPageName: String
    let callTime: Int64 = Int64(CFAbsoluteTimeGetCurrent() * 1000)
}

/// 频控规则逻辑
final class FrequencyRuleManager {
    /// 单例
    public static let shared = FrequencyRuleManager()
    /// 规则配置
    private lazy var mutexConfigs = [String: MutexConfig]()
    /// 事件缓存
    private lazy var eventCaches = [String: [FrequencyEvent]]()
    /// 豁免API白名单
    private lazy var excludeApis = [String]()
    /// 采样率
    private lazy var sampleRate: Int64 = 10
    /// 是否获取主线程堆栈信息
    private lazy var enableMainThreadBacktraces: Bool = true
    private let lock = NSLock()
    private init() {}

    /// 更新频控规则配置
    func updateConfig(_ monitorConfig: [String: Any]) {
        guard !monitorConfig.isEmpty else {
            return
        }

        guard let ruleConfig = monitorConfig["frequency_rules"] as? [[String: Any]] else {
            return
        }
        lock.lock()
        defer {
            lock.unlock()
        }
        for config in ruleConfig {
            guard let maxCalledTimes = config["max_called_times"] as? Int,
                  maxCalledTimes > 0,
                  let timeInterval = config["time_interval"] as? Int,
                  timeInterval > 0 else {
                continue
            }
            let maxStoreSize = max((config["max_store_size"] as? Int) ?? 100, maxCalledTimes)
            if let mutexApis = config["guard_range_mutex_apis"] as? [String] {
                for apiName in mutexApis {
                    let mutexConfig = FrequencyApiMutexConfig(maxCalledTimes: max(maxCalledTimes, 1),
                                                              timeInterval: max(timeInterval, 1),
                                                              maxStoreSize: maxStoreSize,
                                                              apiName: apiName)
                    mutexConfigs[apiName] = mutexConfig
                }
            } else if let datatypeConfigs = config["guard_range_mutex_datatypes"] as? [[String: Any]] {
                for datatypeConfig in datatypeConfigs {
                    guard let datatype = datatypeConfig["datatype"] as? String else {
                        continue
                    }
                    let mutexConfig = FrequencyDataTypeMutexConfig(maxCalledTimes: max(maxCalledTimes, 1),
                                                                   timeInterval: max(timeInterval, 1),
                                                                   maxStoreSize: maxStoreSize,
                                                                   dataType: datatype,
                                                                   ignoreCondition: datatypeConfig["ignore_condition"] as? [String])
                    mutexConfigs[datatype] = mutexConfig
                    if let excludeApis = datatypeConfig["exclude_apis"] as? [String] {
                        self.excludeApis.append(contentsOf: excludeApis)
                    }
                }
            }
        }
        sampleRate = max((monitorConfig["sample_rate"] as? Int64) ?? 10, 10)
        enableMainThreadBacktraces = monitorConfig["enable_main_thread_backtraces"] as? Bool ?? true
    }

    /// 规则检测逻辑，命中规则则触发数据上报
    func handleRuleCheck(event: TSPKEvent) {
        guard let apiModel = event.eventData?.apiModel,
              let apiName = apiModel.apiMethod,
              let dataType = apiModel.dataType else {
              return
        }
        let apiClass = apiModel.apiClass ?? ""
        if Thread.current.isMainThread && !enableMainThreadBacktraces {
            DispatchQueue.global().async {
                self.ruleCheck(with: event,
                               apiClass: apiClass,
                               apiName: apiName,
                               dataType: dataType)

            }
        } else {
            self.ruleCheck(with: event,
                           apiClass: apiClass,
                           apiName: apiName,
                           dataType: dataType)
        }
    }

    private func ruleCheck(with event: TSPKEvent,
                           apiClass: String,
                           apiName: String,
                           dataType: String) {
        lock.lock()
        defer {
            lock.unlock()
        }
        // 1. 检查是否有配置
        guard let apiFullName = TSPKUtils.concateClassName(apiClass, method: apiName, joiner: "_"),
              let config = (mutexConfigs[apiFullName] ?? mutexConfigs[dataType]) else {
            return
        }
        // 2. 豁免api
        guard !excludeApis.contains(apiFullName) else {
            return
        }
        // 3. 白名单场景
        let topPageName = event.eventData?.topPageName ?? ""
        if let config = config as? FrequencyDataTypeMutexConfig,
           config.ignoreCondition?.contains(topPageName) ?? false {
            return
        }

        let now = Int64(CFAbsoluteTimeGetCurrent() * 1000)

        let events = eventCaches[apiFullName] ?? [FrequencyEvent]()
        let beforeRemoveCount = events.count
        var newEvents = events.filter({ event in
            // 4. 过滤超时缓存事件
            return (now - event.callTime) <= config.timeInterval * 1000
        })

        newEvents.append(FrequencyEvent(topPageName: topPageName))
        if newEvents.count > config.maxStoreSize {
            // 5. 清理超长队列
            newEvents.removeSubrange(0..<(newEvents.count - config.maxStoreSize))
        }
        eventCaches[apiFullName] = newEvents
        let currentCount = newEvents.count
        guard currentCount > config.maxCalledTimes && enableReport() else {
            return
        }

        let historyTopPageNames = newEvents.map { frequencyEvent in
            return frequencyEvent.topPageName
        }
        let firstCallTime = newEvents.first?.callTime ?? 0
        let historyCallTimes = newEvents.map { frequencyEvent in
            return frequencyEvent.callTime - firstCallTime
        }

        // 6. 命中规则，数据上报
        let uploadEvent = TSPKUploadEvent()
        let pipelineType = event.eventData?.apiModel?.pipelineType ?? ""
        uploadEvent.eventName = String("PrivacyBadcase-\(pipelineType)-report_for_frequency_rule")
        let backtraceService = (PNSServiceCenter.sharedInstance().getInstance(PNSBacktraceProtocol.self)) as? PNSBacktraceProtocol
        uploadEvent.backtraces = backtraceService?.getBacktracesWithSkippedDepth(0, needAllThreads: false)

        let params = NSMutableDictionary()
        params["source"] = TSPKRuleEngineSpaceGuard
        params[TSPKMonitorSceneKey] = "report_for_frequency_rule"
        params["api"] = apiFullName
        params["method"] = apiName
        params["pipeline_type"] = pipelineType
        params["data_types"] = [dataType]
        params["history_top_page_names"] = historyTopPageNames
        params["history_call_times"] = historyCallTimes
        params["appStatus"] = event.eventData?.appStatus ?? ""
        params["settingVersion"] = TSPKUtils.settingVersion()
        params["kitVerison"] = TSPKUtils.version()
        params["action"] = "report"
        params[TSPKPermissionTypeKey] = dataType
        params["top_page_name"] = topPageName
        params["topPageName"] = topPageName
        params["frequency_max_called_times"] = config.maxCalledTimes
        params["frequency_time_interval"] = config.timeInterval
        params["before_remove_count"] = beforeRemoveCount
        uploadEvent.params = params
        let filterParams = NSMutableDictionary()
        filterParams.addEntries(from: (params as? [AnyHashable: Any]) ?? [:])
        uploadEvent.filterParams = filterParams
        TSPKReporter.shared().report(uploadEvent)
    }

    /// 上报采样率，默认10%
    private func enableReport() -> Bool {
        if sampleRate <= 1 {
            return true
        }
        let currentTime = Int64(CFAbsoluteTimeGetCurrent() * 1_000_000) // μs
        return currentTime % sampleRate == 0
    }

}

/// 敏感API调用切面
final class FrequencyRuleSubscriber: NSObject, TSPKSubscriber {
    func uniqueId() -> String {
        return "FrequencyRuleSubscriber"
    }

    func canHandelEvent(_ event: TSPKEvent) -> Bool {
        if PrivacyMonitor.shared.isLowMachineOrPrivateKA {
            return false
        }
        return true
    }

    func hanleEvent(_ event: TSPKEvent) -> TSPKHandleResult? {
        FrequencyRuleManager.shared.handleRuleCheck(event: event)
        return nil
    }

}
