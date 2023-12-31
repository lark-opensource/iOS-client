//
//  PowerConsumptionExtendedStatistic+jscall.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2022/9/26.
//  


import Foundation
import SKFoundation
import LKCommonsTracker
import LarkSetting
import SwiftyJSON

/// Docs功耗统计:MS环境
public protocol DocsPowerLogMagicShareContext: AnyObject {
    
    /// 在MS场景中是否是小窗模式，true表示小窗，false表示大窗，nil表示非MS场景
    var isInMagicShareFloatingWindow: Bool? { get }
    
}

private var jscallFreqConfigCacheKey: UInt8 = 0

extension PowerConsumptionExtendedStatistic { // MARK: web bridge调用
    
    private var jsbCallConfigCache: JSBCallConfigCache? {
        get { objc_getAssociatedObject(self, &jscallFreqConfigCacheKey) as? JSBCallConfigCache }
        set { objc_setAssociatedObject(self, &jscallFreqConfigCacheKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    private class func isJSMonitorFeatureEnabled() -> Bool {
        if let value = _isJSMonitorFeatureEnabled.value { // 只计算一次,节约性能
            return value
        }
        let newValue: Bool
        let rawDict = (try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "larkweb_jsbcall_powerlog_config"))) ?? [:]
        if let enabled = rawDict["monitor_enabled"] as? Bool { // 优先使用settings中的配置
            newValue = enabled
        } else {
            newValue = LKFeatureGating.jsbCallMonitorEnabled // 兜底使用FG中的配置
        }
        _isJSMonitorFeatureEnabled.value = newValue
        return newValue
    }
    
    /// 监控js 调用
    public class func trackJSCall(method: String, params: [String: Any], webViewId: String, currentUrl: URL?) {
        
        guard isJSMonitorFeatureEnabled() else { return }
        
        workQueue.async {
            _trackJSCall(method: method, params: params, webViewId: webViewId, currentUrl: currentUrl)
            _recognizeHighFrequencyJSCall(method: method)
        }
    }
    
    private class func _trackJSCall(method: String, params: [String: Any], webViewId: String, currentUrl: URL?) {
        
        var identifier = ""
        if let deviceid = DocsTracker.shared.deviceid, !deviceid.isEmpty {
            identifier.append(deviceid + "_")
        }
        if !webViewId.isEmpty {
            identifier.append(webViewId + "_")
        }
        if let urlStr = currentUrl?.absoluteString, !urlStr.isEmpty {
            identifier.append("\(urlStr.hashValue)" + "_")
        }
        identifier.append("\(ObjectIdentifier(UIApplication.shared))" + "_")
        identifier.append("\(ObjectIdentifier(self))")
        
        var parameters = [String: Any]()
        parameters["jsb_webview_id"] = identifier
        parameters["api_name"] = method
        parameters["net_level"] = ttNetworkQualityRawValue
        parameters[PowerConsumptionStatisticParamKey.isForeground] = shared.isForeground
        if let value = shared.docsMSContext?.isInMagicShareFloatingWindow {
            parameters["vc_floating"] = value // 是否是MS小窗
        }
        
        if method == DocsJSService.reportSendEvent.rawValue,
           let data = params["data"] as? [String: Any], let stage = data["stage"] as? String {
            parameters["jsb_state"] = stage
        }
        
        let event = SlardarEvent(name: ReportEvent.jsbCall.rawValue,
                                 metric: [:],
                                 category: parameters,
                                 extra: [:])
        Tracker.post(event)
        DocsTracker.newLog(event: ReportEvent.jsbCall.teaEvent, parameters: parameters) // Tea埋点
    }
    
    private class func _recognizeHighFrequencyJSCall(method: String) {
        
        if shared.jsbCallConfigCache == nil {
            shared.jsbCallConfigCache = JSBCallConfigCache()
        }
        
        guard let expectedSeconds = shared.jsbCallConfigCache?.getDurationFor(method: method),
            let totalCount = shared.jsbCallConfigCache?.getTotalCountFor(method: method) else {
            return
        }
        
        let actualSecondsSpent: Double?
        if let logger = jsbCallDict.value(ofKey: method) {
            if let duration = logger.markCalled() {
                actualSecondsSpent = duration
                jsbCallDict.removeValue(forKey: method)
            } else {
                actualSecondsSpent = nil
                jsbCallDict.updateValue(logger, forKey: method)
            }
        } else {
            let newLogger = JSBCallLogger(bufferSize: totalCount)
            newLogger.markCalled()
            jsbCallDict.updateValue(newLogger, forKey: method)
            actualSecondsSpent = nil
        }
        
        guard let actualSeconds = actualSecondsSpent,
              actualSeconds < Double(expectedSeconds) else { return }
        
        let category: [String: Any] = ["api_name": method, "counter": totalCount]
        let event = SlardarEvent(name: ReportEvent.jsbFreq.rawValue,
                                 metric: ["duration": actualSeconds],
                                 category: category,
                                 extra: [:])
        Tracker.post(event)
        DocsLogger.info("\(Self.logPrefix) js freq call: method:\(method), counter:\(totalCount), duration:\(actualSeconds)")
    }
}

private extension LKFeatureGating {
    
    /// 是否开启jsb调用监控
    @FeatureGating(key: "larkwebview.jsb.call_report")
    static var jsbCallMonitorEnabled: Bool = false
}

extension PowerConsumptionExtendedStatistic {
    
    final class JSBCallLogger { // 用于统计单个method调用次数
        
        let bufferSize: Int // 最大调用次数
        private var initCallTime: Double? // 初始调用时间戳
        private var counter = 0 // 调用计数器
        
        init(bufferSize: Int) {
            self.bufferSize = bufferSize
        }
        
        /// 标记一次调用，如果达到最大次数则返回总耗时，否则返回nil
        @discardableResult
        func markCalled() -> Double? {
            if initCallTime == nil {
                initCallTime = CFAbsoluteTimeGetCurrent()
            }
            if counter < bufferSize {
                counter += 1
            }
            if counter == bufferSize {
                let now = CFAbsoluteTimeGetCurrent()
                let duration = now - (initCallTime ?? 0)
                return duration
            } else {
                return nil
            }
        }
    }
    
    final class JSBCallConfigCache: NSObject { // 用于获取Setting配置的不同method调用频率预期
        
        struct Config {
            let method: String // 方法名
            let totalCount: Int // 总调用次数
            let duration: Int // 预期从0次达到`总调用次数`期间，不超过的秒数
        }
        
        private static var methodKey: String { "method" }
        private static var totalCountKey: String { "totalCount" }
        private static var durationKey: String { "duration" }
        private let freqConfigs: [String: Config] // 高频方法调用配置, key: js方法名
        private let normalConfig: Config? // 普通方法调用配置
        
        override init() {
            let settingKey = UserSettingKey.make(userKeyLiteral: "larkweb_jsbcall_powerlog_config")
            let rawDict = (try? SettingManager.shared.setting(with: settingKey)) ?? [:]
            
            if let normal = rawDict["jscall_normal_config"] as? [String: Any],
               let totalCount = normal[Self.totalCountKey] as? Int,
               let duration = normal[Self.durationKey] as? Int {
                normalConfig = .init(method: "", totalCount: totalCount, duration: duration)
            } else {
                normalConfig = nil
            }
            
            var dict = [String: Config]()
            let freqSet = (rawDict["jscall_freq_config"] as? [[String: Any]]) ?? []
            for freq in freqSet {
                let method = freq[Self.methodKey] as? String
                let totalCount = freq[Self.totalCountKey] as? Int
                let duration = freq[Self.durationKey] as? Int
                if let method = method, let totalCount = totalCount, let duration = duration {
                    dict[method] = .init(method: method, totalCount: totalCount, duration: duration)
                }
            }
            freqConfigs = dict
            super.init()
        }
        
        func getDurationFor(method: String) -> Int? {
            if let config = freqConfigs[method] {
                return config.duration
            }
            return normalConfig?.duration
        }
        
        func getTotalCountFor(method: String) -> Int? {
            if let config = freqConfigs[method] {
                return config.totalCount
            }
            return normalConfig?.totalCount
        }
    }
}
