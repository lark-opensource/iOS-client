//  BTStatisticManager.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/8/31.
//

import Foundation
import Heimdallr
import SKFoundation
import ThreadSafeDataStructure
import LarkSetting

// 参考：https://bytedance.feishu.cn/wiki/EzpPwTBbgiSvrCk4NXbcxpvrnfc
final class BTStatisticManager: BTStatisticServiceProtocol {
    private static let tag = "StatisticServiceImpl"

    static let shared: BTStatisticManager? = {
        guard UserScopeNoChangeFG.LYL.enableStatisticTrace else {
            return nil
        }
        return internalShared
    }()

    private static let internalShared = BTStatisticManager()

    // 可能耗时操作，例如 consumer，放入 serialQueue 执行
    static let serialQueue = DispatchQueue(label: "SKFoundation.BTStatistic.queue", qos: .background)

    private static var traceIdToTrace: [String: BTStatisticTrace] {
        get { _traceIdToTrace.getImmutableCopy() }
        set { _traceIdToTrace.replaceInnerData(by: newValue) }
    }
    private static var _traceIdToTrace: SafeDictionary<String, BTStatisticTrace> = [:] + .semaphore

    private let fgSetting: [String: Any]
    let configSetting: [String: Any]

    init() {
        do {
            fgSetting = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_base_performance_fg_key"))
        } catch let error {
            fgSetting = [String: Any]()
            DocsLogger.btError("get settings ccm_base_performance_fg_key \(error)")
        }
        do {
            configSetting = try SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "ccm_base_performance_config"))
        } catch let error {
            configSetting = [String: Any]()
            DocsLogger.btError("get settings ccm_base_performance_config \(error)")
        }
    }

    func isTraceEnd(traceId: String) -> Bool {
        guard let trace = Self.traceIdToTrace[traceId] else {
            BTStatisticLog.logInfo(tag: Self.tag, message: "addTraceExtra get trace fail")
            return true
        }
        return trace.isStop
    }

    func stopTrace(traceId: String) {
        stopTrace(traceId: traceId, includeChildren: true)
    }

    func stopTrace(traceId: String, includeChildren: Bool) {
        // 等待 consumer 执行结束，再 stop
        Self.serialQueue.async {
            guard let trace = Self.traceIdToTrace[traceId] else {
                BTStatisticLog.logInfo(tag: Self.tag, message: "stopTrace get trace fail")
                return
            }
            trace.stop(includeChildren: includeChildren)
        }
    }

    func addTraceExtra(traceId: String, extra: [String : Any]) {
        guard let trace = Self.traceIdToTrace[traceId] else {
            BTStatisticLog.logInfo(tag: Self.tag, message: "addTraceExtra get trace fail")
            return
        }
        trace.addExtra(extra: extra)
    }

    func stopAllTrace() {
        // 等待 consumer 执行结束，再 stop
        Self.serialQueue.async {
            Self.traceIdToTrace.forEach { (_, trace) in
                trace.stop(includeChildren: true)
            }
            Self.traceIdToTrace.removeAll()
        }
    }

    func createNormalTrace(parentTrace: String?) -> String {
        let trace = BTStatisticNormalTrace(parentTraceId: parentTrace, traceProvider: self)
        Self.traceIdToTrace[trace.traceId] = trace
        return trace.traceId
    }

    func addNormalConsumer(traceId: String, consumer: BTStatisticNormalConsumer) {
        guard let trace = Self.traceIdToTrace[traceId] else {
            BTStatisticLog.logInfo(tag: Self.tag, message: "addNormalConsumer getTrace fail")
            return
        }
        trace.add(consumer: consumer)
    }

    func removeNormalConsumer(traceId: String, consumer: BTStatisticNormalConsumer) {
        guard let trace = Self.traceIdToTrace[traceId] else {
            BTStatisticLog.logInfo(tag: Self.tag, message: "removeNormalConsumer getTrace fail")
            return
        }
        trace.remove(consumer: consumer)
    }

    func addNormalPoint(traceId: String, point: BTStatisticNormalPoint) {
        guard let trace = Self.traceIdToTrace[traceId] as? BTStatisticNormalTrace else {
            BTStatisticLog.logInfo(tag: Self.tag, message: "addNormalPoint getTrace fail")
            return
        }
        trace.add(point: point)
    }

    func createFPSTrace(parentTrace: String?) -> BTStatisticFPSTrace {
        let trace = BTStatisticFPSTrace(parentTraceId: parentTrace, traceProvider: self)
        Self.traceIdToTrace[trace.traceId] = trace
        return trace
    }

    func addFPSConsumer(traceId: String, consumer: BTStatisticFPSConsumer) {
        guard let trace = Self.traceIdToTrace[traceId] else {
            BTStatisticLog.logInfo(tag: Self.tag, message: "addFPSConsumer getTrace fail")
            return
        }
        trace.add(consumer: consumer)
    }

    func removeFPSConsumer(traceId: String, consumer: BTStatisticFPSConsumer) {
        guard let trace = Self.traceIdToTrace[traceId] else {
            BTStatisticLog.logInfo(tag: Self.tag, message: "removeFPSConsumer getTrace fail")
            return
        }
        trace.remove(consumer: consumer)
    }

    func removeAllConsumer(traceId: String) {
        guard let trace = Self.traceIdToTrace[traceId] else {
            BTStatisticLog.logInfo(tag: Self.tag, message: "removeAllConsumer getTrace fail")
            return
        }
        trace.removeAllConsumer()
    }

    func allowedNormalStateDropDetect(isAllowed: Bool) {
        guard UserScopeNoChangeFG.LYL.enableBaseFPSDrop else {
            return
        }
        HMDFrameDropMonitor.shared().allowedNormalStateSample(isAllowed, callbackInterval: BTStatisticConstant.dropCallbackInterval)
    }
}

extension BTStatisticManager: BTStatisticTraceInnerProvider {
    func getLogger() -> BTStatisticLoggerProvider {
        return self
    }

    func getUUId() -> String {
        return BTStatisticUtils.generateTraceId()
    }

    func getTrace(traceId: String, includeStop: Bool) -> BTStatisticTrace? {
        guard let trace = Self.traceIdToTrace[traceId] else {
            BTStatisticLog.logInfo(tag: Self.tag, message: "getTrace fail")
            return nil
        }
        if !includeStop, trace.isStop == true {
            BTStatisticLog.logInfo(tag: Self.tag, message: "trace is stop")
            return nil
        }
        return trace
    }

    func removeTrace(traceId: String, includeChild: Bool) {
        Self.traceIdToTrace.removeValue(forKey: traceId)
    }
}

extension BTStatisticManager: BTStatisticLoggerProvider {
    func send(trace: BTStatisticTrace, eventName: String, params: [String : Any]) {
        var realParams = params
        realParams[BTStatisticConstant.traceId] = trace.traceId
        realParams[BTStatisticConstant.parentTraceId] = trace.parentTraceId

        if realParams[BTStatisticConstant.FG] == nil, let fgs = fgParams(eventName: eventName) {
            // 直接加到 trace extra，这样单个 trace 只会添加一次
            BTStatisticManager.shared?.addTraceExtra(traceId: trace.traceId, extra: [BTStatisticConstant.FG: fgs])
        }

        let extra = trace.getExtra(includeParent: true)
        realParams.merge(extra, uniquingKeysWith: { (cur, _) in cur })
        DocsTracker.newLog(event: eventName, parameters: realParams)

        BTStatisticLog.logInfo(tag: Self.tag, message: "send \(eventName), \(realParams)")
    }

    private func fgParams(eventName: String) -> [String: Bool]? {
        guard let fgKeys = fgSetting[eventName] as? [String] else {
            return nil
        }
        var fgs = [String: Bool]()
        for key in fgKeys {
            let fgKey = FeatureGatingManager.Key(stringLiteral: key)
            let fg = FeatureGatingManager.shared.featureGatingValue(with: fgKey)
            fgs[key] = fg
        }
        return fgs
    }
}
