//
//  Monitor.swift
//  LarkSecurityComplianceInfra
//
//  Created by ByteDance on 2022/8/17.
//

import Foundation
import ECOProbe
import LKCommonsTracker
import LarkSetting

/**
 安全合规子功能，新增请添加枚举
 */
public enum SCMonitorBusiness: String {
    case snc                    // 兜底，不应该使用

    /** 安全合规对客 **/
    case no_permission          // 条件访问控制
    
    case tenant_restrict        // 限制登录

    case security_policy        // 文件策略管理

    case app_lock               // 锁屏保护

    case watermark              // 水印

    case paste_protect          // 粘贴保护

    case security_audit         // 审计SDK

    case encryption_upgrade     // 密钥升级
    
    case file_stream            // 文件加解密

    /** 安全合规基建 **/
    case policy_engine          // 策略引擎

    case privacy_monitor        // 敏感api监控

    case psda    // 敏感api管控（psda）

    case settings // SCSetting
}
/**
 单事件名打点场景
 */
public enum SCMonitorSingleEvent: String {
    /** 基础能力 **/
    case network_state_monitor   // 网络请求错误
    
    case network_request_monitor // 网络请求数量

    case storage                // 本地存储
    
    case paste_protect          // 粘贴保护
    
    case device_status          // 设备申报
}

private protocol SCMonitorProtocol {
    static func info(business: SCMonitorBusiness, eventName: String, category: [String: Any]?, metric: [String: Any]?)

    static func error(business: SCMonitorBusiness, eventName: String, error: Error?, extra: [String: Any]?)

    static func info(singleEvent: SCMonitorSingleEvent, category: [String: Any]?, metric: [String: Any]?)

    static func error(singleEvent: SCMonitorSingleEvent, error: Error?, extra: [String: Any]?)
}

public struct SCMonitor {

    private static var useSlardarMonitor: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: "admin.security.scs_monitor") // Global
    }

    public static func info(business: SCMonitorBusiness, eventName: String, category: [String: Any]? = [:], metric: [String: Any]? = [:]) {
        if useSlardarMonitor {
            SlardarTracker.info(business: business, eventName: eventName, category: category, metric: metric)
        } else {
            OPMonitorTracker.info(business: business, eventName: eventName, category: category, metric: metric)
        }
    }

    public static func error(business: SCMonitorBusiness, eventName: String, error: Error? = nil, extra: [String: Any]? = nil) {
        if useSlardarMonitor {
            SlardarTracker.error(business: business, eventName: eventName, error: error, extra: extra)
        } else {
            OPMonitorTracker.error(business: business, eventName: eventName, error: error, extra: extra)
        }
    }

    public static func info(singleEvent: SCMonitorSingleEvent, category: [String: Any]? = [:], metric: [String: Any]? = [:]) {
        if useSlardarMonitor {
            SlardarTracker.info(singleEvent: singleEvent, category: category, metric: metric)
        } else {
            OPMonitorTracker.info(singleEvent: singleEvent, category: category, metric: metric)
        }
    }

    public static func error(singleEvent: SCMonitorSingleEvent, error: Error?, extra: [String: Any]?) {
        if useSlardarMonitor {
            SlardarTracker.error(singleEvent: singleEvent, error: error, extra: extra)
        } else {
            OPMonitorTracker.error(singleEvent: singleEvent, error: error, extra: extra)
        }
    }
}

private struct OPMonitorTracker: SCMonitorProtocol {
    static func info(business: SCMonitorBusiness, eventName: String, category: [String: Any]? = [:], metric: [String: Any]? = [:]) {
        flushInfo(name: "scs_\(business)_\(eventName)", category: category, metric: metric)
    }

    static func error(business: SCMonitorBusiness, eventName: String, error: Error? = nil, extra: [String: Any]? = nil) {
        flushError(name: "scs_\(business)_\(eventName)", error: error, extra: extra)
    }

    static func info(singleEvent: SCMonitorSingleEvent, category: [String: Any]?, metric: [String: Any]?) {
        flushInfo(name: "scs_\(singleEvent)", category: category, metric: metric)
    }

    static func error(singleEvent: SCMonitorSingleEvent, error: Error?, extra: [String: Any]?) {
        flushError(name: "scs_\(singleEvent)", error: error, extra: extra)
    }

    private static func flushInfo(name: String, category: [String: Any]?, metric: [String: Any]?) {
        name.precheck()
        let monitor = OPMonitor(name)

        if let category = category {
            for item in category {
                monitor.addCategoryValue(item.key, item.value)
            }
        }

        if let metric = metric {
            for item in metric {
                monitor.addMetricValue(item.key, item.value)
            }
        }

        monitor.flush()
    }

    private static func flushError(name: String, error: Error?, extra: [String: Any]?) {
        name.precheck()
        let monitor = OPMonitor(name)

        if let extra = extra {
            for item in extra {
                monitor.addCategoryValue(item.key, item.value)
            }
        }

        monitor.setResultTypeFail().setError(error).flush()
    }
}

private struct SlardarTracker: SCMonitorProtocol {
    static func info(business: SCMonitorBusiness, eventName: String, category: [String: Any]? = [:], metric: [String: Any]? = [:]) {
        postInfo(name: "scs_\(business)_\(eventName)", category: category, metric: metric)
    }

    static func error(business: SCMonitorBusiness, eventName: String, error: Error? = nil, extra: [String: Any]? = nil) {
        postError(name: "scs_\(business)_\(eventName)", error: error, extra: extra)
    }

    static func info(singleEvent: SCMonitorSingleEvent, category: [String: Any]?, metric: [String: Any]?) {
        postInfo(name: "scs_\(singleEvent)", category: category, metric: metric)
    }

    static func error(singleEvent: SCMonitorSingleEvent, error: Error?, extra: [String: Any]?) {
        postError(name: "scs_\(singleEvent)", error: error, extra: extra)
    }

    private static func postInfo(name: String, category: [String: Any]? = [:], metric: [String: Any]? = [:]) {
        name.precheck()
        Tracker.post(SlardarEvent(name: name,
                                  metric: metric ?? [:],
                                  category: category ?? [:],
                                  extra: [:]))
    }

    private static func postError(name: String, error: Error? = nil, extra: [String: Any]? = nil) {
        name.precheck()
        var category: [String: Any] = ["status": 1]

        if let nsError = error as? NSError {
            category["error_code"] = nsError.code
            category["error_domain"] = nsError.domain
            category["error_msg"] = nsError.localizedDescription
        }

        if let lscError = error as? LSCError {
            category["description"] = lscError.description
        }

        if let extra = extra {
            category = category.merging(extra) { $1 }
        }

        Tracker.post(SlardarEvent(name: name,
                                  metric: [:],
                                  category: category,
                                  extra: [:]))
    }
}

private extension String {
    func precheck() {
        assert(self.count <= 50, "event name length should be less than or equal to 50 characters")
        assert(NSPredicate(format: "SELF MATCHES %@", "^[a-zA-Z0-9_]+$").evaluate(with: self), "event name should contain only alphanumeric and underline")
    }
}
