//
//  SecurityPolicyReporter.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/28.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkPolicyEngine
import LarkContainer
import UniverseDesignToast

extension SecurityPolicy {
    class LogReporter: LogReportService {
        let userResolver: UserResolver
        let service: PolicyEngineService?
        let reportFilterPolicySets: [String]
        let deleteFilterPolicySets: [String]
        let filterPointKeys: [String]
        
        var currentTime: TimeInterval {
            if #available(iOS 15, *) {
                return Date.now.timeIntervalSince1970 * 1000
            }
            return Date().timeIntervalSince1970 * 1000
        }
        // swiftlint:disable:next nesting
        enum OperateType: String {
            case report
            case delete
        }
        
        init(userResolver: UserResolver) throws {
            self.userResolver = userResolver
            self.service = try? userResolver.resolve(assert: PolicyEngineService.self)
            let settings = try userResolver.resolve(assert: SCRealTimeSettingService.self)
            self.reportFilterPolicySets = settings.array(.logReportFilterPolicySetKeys)
            self.deleteFilterPolicySets = settings.array(.logDeleteFilterPolicySetKeys)
            self.filterPointKeys = ["PC:CLIENT:ios:PointKey_CCM_OPEN_EXTERNAL_ACCESS"]
        }
        
        func config() {
            register()
        }
        
        func report(_ validateLogInfos: [ValidateLogInfo]) {
            let infos = evaluateInfos(validateInfos: validateLogInfos, operateType: .report)
            guard !infos.isEmpty else {
                SCLogger.info("Security policy report info list is empty")
                return
            }
            service?.reportRealLog(evaluateInfoList: infos)
            monitorInfo("log_report", uuids: infos.map { $0.evaluateUk })
        }
        
        func delete(_ validateLogInfos: [ValidateLogInfo]) {
            let infos = evaluateInfos(validateInfos: validateLogInfos, operateType: .delete)
            guard !infos.isEmpty else {
                SCLogger.info("Security policy delete info list is empty")
                return
            }
            service?.deleteDecisionLog(evaluateInfoList: infos)
            monitorInfo("log_delete", uuids: infos.map { $0.evaluateUk })
        }
        
        private func monitorInfo(_ eventName: String, uuids: [String]) {
            let uuidsString = uuids.reduce("") { partialResult, uuid in
                return partialResult.appending(",\(uuid)")
            }
            SCLogger.info("Security policy \(eventName) success, uuids = \(uuidsString)")
            SCMonitor.info(business: .security_policy, eventName: eventName, category: ["uuids": uuids])
        }
        
        private func evaluateInfos(validateInfos: [ValidateLogInfo], operateType: OperateType) -> [EvaluateInfo] {
            let infos = validateInfos.compactMap { info -> EvaluateInfo? in
                let policySetKeys = info.policySetKeys?.filter({ policySetKey in
                    return logShouldRemained(policySetKey, operateType: operateType)
                })
                guard let policySetKeys = policySetKeys, !policySetKeys.isEmpty else { return nil }
                return EvaluateInfo(evaluateUk: info.uuid, operateTime: String(Int64(currentTime)), policySetKeys: policySetKeys)
            }
            return  infos
        }
        
        func shouldGenerateLog(pointKey: String, policySetKey: String) -> Bool {
            return logShouldRemained(policySetKey, operateType: .report) && !filterPointKeys.contains(pointKey)
        }
        
         func logShouldRemained(_ policySetKey: String, operateType: OperateType) -> Bool {
            // 临时逻辑，过滤掉不需要上报的策略集的日志，避免引入对文件策略管理的影响
            var policySetKeys: [String] = []
            switch operateType {
            case .report:
                policySetKeys = self.reportFilterPolicySets
            case .delete:
                policySetKeys = self.deleteFilterPolicySets
            }
            return !policySetKeys.contains(policySetKey)
        }
    }
}

extension SecurityPolicy.LogReporter: SecurityPolicyCacheChangeAction {
    var identifier: String {
        return "SecurityPolicy.LogReporter"
    }
    
    func handleCacheAdd(newValues: [String: SceneLocalCache]) {
        // do nothing
        SCLogger.info("security policy reporter handleCacheAdd")
    }
    
    func handleCacheUpdate(oldValues: [String: SceneLocalCache], overwriteValues: [String: SceneLocalCache]) {
        let validateInfos = oldValues.map {
            return ValidateLogInfo(uuid: $1.uuid, policySetKeys: $1.policySetKeys)
        }
        delete(validateInfos)
    }
    
    func register() {
        let service = try? userResolver.resolve(assert: SecurityPolicyCacheProtocol.self)
        service?.registerCacheChangeObserver(observer: self)
    }
}
