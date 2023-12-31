//
//  OPTrace+FeatureGating.swift
//  ECOProbe
//
//  Created by qsc on 2021/4/1.
//

import Foundation
import LarkContainer
import LKCommonsLogging

struct BatchMonitorFilter {
    let domainList: Set<String>
    let domainPrefixList: [String]
    let eventNameList: Set<String>
    let monitorIdList: Set<String>

    func match(domain: String, monitorId: String, eventName: String) -> Bool {
        if eventNameList.contains(eventName) {
            return true
        }

        if let _ =  domainPrefixList.first(where: { (domain_prefix) -> Bool in
            domain.hasPrefix(domain_prefix)
        }) {
            return true
        }

        if domainList.contains(domain) {
            return true
        }

        if monitorIdList.contains(monitorId) {
            return true
        }

        return false
    }

    init(data: [String: Array<AnyHashable>]) {
        self.domainList = Set(data["monitor_domain"] as? [String] ?? [])
        self.domainPrefixList = data["monitor_domain_prefix"] as? [String] ?? []
        self.eventNameList = Set(data["event_name"] as? [String] ?? [])
        self.monitorIdList = Set(data["monitor_id"] as? [String] ?? [])
    }
}

@objcMembers
public final class OPTraceBatchConfig: NSObject {
    static private let KeyMinaConfig = "optrace_batch_config"
    static private let KeyReportEnabled = "reportEnabled"
    static private let KeyLogEnabled = "logEnabled"
    static private let KeyBlackListEnabled = "batchBlackListEnabled"
    static private let KeyWhiteListEnabled = "batchWhiteListEnabled"
    static private let KeyBlackList = "batchBlackList"
    static private let KeyWhiteList = "batchWhiteList"
    static private let keyBizBlackList = "bizBlackList"

    static private let logger = Logger.oplog(OPTraceBatchConfig.self, category: "ECOProbe")

    // 不能用 @Provider, 因为会导致 link 时找不到 symbol, 即使 @nonobjc 也不行
    private var dependency: OPProbeConfigDependency? {
        return InjectedOptional<OPProbeConfigDependency>().wrappedValue// user:global
    }

    public private(set) var reportEnabled = false
    public private(set) var logEnabled = false
    private var reportBlackListEnabled = false
    private var reportWhiteListEnabled = false
    private var reportBlackList: BatchMonitorFilter?
    private var reportWhiteList: BatchMonitorFilter?
    private var bizBlackList: Set<String>
    public private(set) var rawConfig: [String: Any]

    static public let shared = OPTraceBatchConfig()
    
    private var apiReportConfig: [String: Any] = [:]
    private var apiReportBlackList: [String] = []

    public override init() {
        bizBlackList = []
        rawConfig = [:]
        super.init()
        readCurrentConfig()
    }

    func readCurrentConfig() {
        guard let dependency = dependency else {
            Self.logger.warn("update config failed, please assemble OPProbeConfigDependency")
            return
        }
        rawConfig = dependency.readMinaConfig(for: OPTraceBatchConfig.KeyMinaConfig)
        reportEnabled = rawConfig[OPTraceBatchConfig.KeyReportEnabled] as? Bool ?? false
        logEnabled = rawConfig[OPTraceBatchConfig.KeyLogEnabled] as? Bool ?? false
        reportBlackListEnabled = rawConfig[OPTraceBatchConfig.KeyBlackListEnabled] as? Bool ?? false
        reportWhiteListEnabled = rawConfig[OPTraceBatchConfig.KeyWhiteListEnabled] as? Bool ?? false

        let blackListData = rawConfig[OPTraceBatchConfig.KeyBlackList] as? [String: Array<AnyHashable>] ?? [:]
        let whiteListData = rawConfig[OPTraceBatchConfig.KeyWhiteList] as? [String: Array<AnyHashable>] ?? [:]
        let bizBlackListData = rawConfig[OPTraceBatchConfig.keyBizBlackList] as? [AnyHashable] ?? []

        reportWhiteList = BatchMonitorFilter(data: whiteListData)
        reportBlackList = BatchMonitorFilter(data: blackListData)
        bizBlackList = Set(bizBlackListData as? [String] ?? [])
        
        apiReportConfig = dependency.getRealTimeSetting(for: Self.kAPIReportConfigKey) ?? [:]
        apiReportBlackList = apiReportConfig[Self.kAPIReportBlackListKey] as? [String] ?? []
    }


    /// 判定埋点是否符合批量上报的条件
    /// 1. 开启黑名单的情况下，若命中黑名单，返回 false，不上报
    /// 2. 开启白名单的情况下，若**未**命中白名单，返回 false，上报
    /// 3. 未开启黑/白名单的情况下，返回 true，默认上报
    /// - Parameters:
    ///   - monitorDomain: domain
    ///   - monitorCode: code
    ///   - eventName: eventName
    /// - Returns: 是否要进行批量上报
    public func batchEnabledFor(eventName: String, monitorDomain: String, monitorId: String) -> Bool {
        guard reportEnabled else {
            return false
        }
        if(reportBlackListEnabled) {
            // 开启黑名单，命中的才返回 `false`
            if reportBlackList?.match(domain: monitorDomain, monitorId: monitorId, eventName: eventName) ?? false {
                return false
            }
        }

        if (reportWhiteListEnabled) {
            // 开启白名单，只有命中的才返回 `true`
            if let whiteList = reportWhiteList {
                return whiteList.match(domain: monitorDomain, monitorId: monitorId, eventName: eventName)
            } else {
                return false
            }
        }
        // 默认返回 `true`，未开启或未命中任何策略
        return true
    }


    /// 检查 bizName 是否在黑名单内
    /// - Parameter bizName: bizName
    /// - Returns: 命中黑名单情况下，返回 false，以关闭 trace 的批量上报能力
    public func checkBizBatchEnabled(bizName: String) -> Bool {
        if bizBlackList.contains(bizName) {
            return false
        }
        return true
    }
    
    public func checkApiReportEnabled(apiName: String) -> Bool {
        if (apiReportBlackList.contains(apiName)) {
            return false
        }
        return true
    }
}

extension OPTraceBatchConfig {
    static let kAPIReportConfigKey = "op_api_report_config"
    static let kAPIReportBlackListKey = "reportBlackList"
}
