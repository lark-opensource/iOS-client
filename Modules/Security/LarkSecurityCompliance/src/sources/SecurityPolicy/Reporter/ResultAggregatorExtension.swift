//
//  ResultAggregatorExtension.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/30.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra

extension SecurityPolicy.ResultAggregator {
    func createLogInfos(policyModel: PolicyModel, results: [ValidateResultProtocol]) -> [ValidateLogInfo] {
        let infos = results
            .filter({ result in
                return result.canReport
            })
            .map({ result in
                // 过滤可以上报的策略集类型
                let policySetKeys = result.policySetKeys?.filter({ policySetKey in
                    return self.logShouldRemained(pointKey: policyModel.pointKey.rawValue, policySetKey: policySetKey)
                })
                return ValidateLogInfo(uuid: result.uuid, policySetKeys: policySetKeys)
            })
        return infos
    }
    
    private func logShouldRemained(pointKey: String, policySetKey: String) -> Bool {
        // 临时逻辑，过滤掉不需要上报的策略集的日志，避免引入对文件策略管理的影响
        let logService = try? userResolver.resolve(assert: LogReportService.self)
        return logService?.shouldGenerateLog(pointKey: pointKey, policySetKey: policySetKey) ?? true
    }
}
