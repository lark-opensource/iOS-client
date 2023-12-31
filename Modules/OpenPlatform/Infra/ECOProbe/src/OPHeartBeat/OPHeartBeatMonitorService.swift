//
//  OPHeartBeatMonitorService.swift
//  ECOProbe
//
//  Created by lixiaorui on 2021/7/9.
//

import Foundation
import LarkContainer
import LKCommonsLogging
import ECOProbeMeta

fileprivate extension String {
    static let hearBeatMonitorEventName = "openplatform_ecosystem_monitor_report_heartbeat"
    static let enableHeartBeatMonitorFG = "ecosystem.monitor.heartbeat.enable"
    static let heartBeatInterval = "heartBeatInterval"
    static let maxReportCount = "maxReportCount"
    static let opmonitorHeartBeatConifg = "opmonitor_heartbeat_conifg"
}

// 埋点上报数据
fileprivate  struct OPHeartBeatMonitorMonitorData {
    // 数据源信息
    var sourceData: OPMonitorEvent
    // 数据源状态
    var status: OPHeartBeatMonitorSourceStatus = .unknown
    // 该数据源已上报次数
    var reportedCount: Int = 0
}

// 心跳埋点相关配置,从FG和Settings拉取
fileprivate struct OPHeartBeatMonitorConfiguration {

    // 心跳间隔时长，用于设置timer周期，默认30s
    var heartBeatInterval: TimeInterval = 30

    // 心跳埋点总开关，FG控制，默认关闭
    var enableHeartBeatMonitor: Bool = false

    // 每个ID最大可上报次数, 默认240
    var maxReportCount: Int = 240

}

fileprivate class WeakWrapper<T: AnyObject> {
    weak var value : T?
    init (value: T?) {
        self.value = value
    }
}

// 心跳埋点服务
// see: https://bytedance.feishu.cn/docs/doccnD5dUwyktb99uyRjZL5IMff#
@objcMembers
public final class OPHeartBeatMonitorService: NSObject {

    public static let `default` = OPHeartBeatMonitorService()

    private var dependency: OPProbeConfigDependency? {
        return InjectedOptional<OPProbeConfigDependency>().wrappedValue// user:global
    }

    static private let logger = Logger.oplog(OPHeartBeatMonitorService.self, category: "ECOProbe")

    // 轮询Timer，Lark后台时停止
    private var timer: Timer?

    // 心跳配置，从FG和Settings拉取
    private var configuration = OPHeartBeatMonitorConfiguration()

    // 注册了心跳埋点的数据源 & 待上报的数据
    private var heartBeatSources: [String: (provider: WeakWrapper<OPHeartBeatMonitorBizProvider>,
                                            data: OPHeartBeatMonitorMonitorData)] = [:]

    private override init() {
        super.init()
        updateConfig()
        if self.configuration.enableHeartBeatMonitor {
            self.timer = Timer(timeInterval: self.configuration.heartBeatInterval,
                               target: self,
                               selector: #selector(triggerHeartBeatMonitor),
                               userInfo: nil,
                               repeats: true)
            RunLoop.main.add(self.timer!, forMode: .common)
            self.timer?.fire()
        }
    }

    deinit {
        timer?.invalidate()
        timer = nil
        triggerHeartBeatMonitor()
    }

    // 外部调用，注册心跳埋点
    public func registerHeartBeat(with source: OPHeartBeatMonitorBizSource, provider: OPHeartBeatMonitorBizProvider) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        guard configuration.enableHeartBeatMonitor else {
            Self.logger.info("heartBeat monitor disabled")
            return
        }
        Self.logger.info("register heartbeat for id: \(source.heartBeatID)")
        guard !source.heartBeatID.isEmpty else {
            assertionFailure("can not register heartbeat for empty sourceID")
            return
        }
        var data = OPHeartBeatMonitorMonitorData(sourceData: source.monitorData, status: .active)
        if let existData = heartBeatSources[source.heartBeatID]?.data {
            data.reportedCount = existData.reportedCount
        }
        heartBeatSources[source.heartBeatID] = (WeakWrapper(value: provider), data)
    }

    // 外部调用，停止心跳埋点
    public func endHeartBeat(for heartBeatID: String) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        guard configuration.enableHeartBeatMonitor else {
            Self.logger.info("heartBeat monitor disabled")
            return
        }
        Self.logger.info("end heartbeat for id: \(heartBeatID)")
        heartBeatSources[heartBeatID]?.data.status = .unknown
    }

    @objc
    private func triggerHeartBeatMonitor() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        guard configuration.enableHeartBeatMonitor else {
            Self.logger.info("heartBeat monitor disabled")
            return
        }
        for (id, (provider, cacheData)) in heartBeatSources {
            // 若provider已经释放，则状态置为unknown
            var data = cacheData
            let currentStats = provider.value?.getCurrentStatus(of: id) ?? .unknown
            data.reportedCount = cacheData.reportedCount + 1
            data.status = currentStats
            heartBeatSources[id]?.data = data
        }
        // 上报所有cache里的点
        if !heartBeatSources.isEmpty {
            let cacheData = heartBeatSources.map {
                return $0.value.data.sourceData.jsonData ?? ""
            }

            OPMonitor(name: String.hearBeatMonitorEventName,
                      code: EPMMonitorBaseHeartbeatCode.heartbeat_report)
                .setPlatform(.tea)
                .addCategoryValue("active_ids", cacheData)
                .flush()
        }

        // 移除所有状态为unknown的cache
        // 移除所有已达到最高上报次数的cache
        heartBeatSources = heartBeatSources.filter({ $0.value.data.reportedCount < configuration.maxReportCount && $0.value.data.status == .active })
    }

    private func updateConfig() {
        guard let dependency = dependency else {
            Self.logger.warn("config update failed, please Assemble OPProbeConfigDependency")
            return
        }

        let enableHeartBeatMonitor = dependency.getFeatureGatingBoolValue(for: String.enableHeartBeatMonitorFG)
        let heartBeatSettings = dependency.readMinaConfig(for: String.opmonitorHeartBeatConifg)
        let heartBeatInterval = heartBeatSettings[String.heartBeatInterval] as? TimeInterval ?? 30
        let maxReportCount = heartBeatSettings[String.maxReportCount] as? Int ?? 240
        configuration = OPHeartBeatMonitorConfiguration(heartBeatInterval: heartBeatInterval, enableHeartBeatMonitor: enableHeartBeatMonitor, maxReportCount: maxReportCount)
        Self.logger.info("update config, enableHeartBeatMonitor: \(enableHeartBeatMonitor),heartBeatInterval: \(heartBeatInterval), maxReportCount: \(maxReportCount)")
    }
}
