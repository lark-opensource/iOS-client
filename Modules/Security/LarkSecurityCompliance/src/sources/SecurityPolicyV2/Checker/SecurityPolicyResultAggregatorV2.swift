//
//  SecurityPolicyResultAggregator.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/9.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkPolicyEngine
import LarkSecurityComplianceInfra
import LarkContainer

extension SecurityPolicyV2 {
    
    struct ResultAggregator {
        let actionPriority: [String: Int] = [
            "TT_BLOCK": 600,
            "FILE_BLOCK_COMMON": 500,
            "DLP_CONTENT_SENSITIVE": 400,
            "DLP_CONTENT_DETECTING": 300,
            "FALLBACK_COMMON": 200,
            "UNIVERSAL_FALLBACK_COMMON": 100
        ]
        
        let resultMethodPriority: [ValidateResultMethod: Int] = [
            .fallback: 600,
            .downgrade: 500,
            .fastpass: 400,
            .serverStrategy: 300,
            .localStrategy: 200,
            .cache: 100
        ]
        
        var cacheStrategyPriority: Int {
            return resultMethodPriority[ValidateResultMethod.cache] ?? 0
        }
        
        private var fastPassResponse: ValidateResponse {
            return ValidateResponse(effect: .permit, actions: [], uuid: UUID().uuidString, type: .fastPass)
        }
        
        let userResolver: UserResolver
        
        let fallbackResultManager: FallbackResultProtocol
        private let settings: Settings
        
        init(resolver: UserResolver) throws {
            userResolver = resolver
            fallbackResultManager = try resolver.resolve(assert: FallbackResultProtocol.self)
            settings = try userResolver.resolve(assert: Settings.self)
        }
        
        func merge(policyModel: PolicyModel, results: [ValidateResultProtocol]) -> ValidateResult {
            
            // 全部决策均无结果，直接返回通过
            let validateInfos = createLogInfos(policyModel: policyModel, results: results)
            
            guard !results.isEmpty else {
                SCLogger.info("security policy: results is empty, merge result return default result")
                return fastPassResponse.validateResult(userResolver: userResolver, logInfos: validateInfos)
            }
            
            let denyResults = results.filter { result in
                return !result.isAllow
            }

            if denyResults.isEmpty {
                // 全部为allow结果，按照allow结果的优先级返回，allow结果全部为降级结果时，返回兜底结果
                if let allowResult = allowResult(results) {
                    return allowResult.validateResult(userResolver: userResolver, logInfos: validateInfos)
                }
                // 获取兜底结果
                let fallbackResult = fallbackResultManager.getClientFallBackResult(policyModel: policyModel)
                return fallbackResult
            } else {
                // 存在deny结果，按照action的优先级对deny的结果进行排序，返回最高优先级的deny结果
                guard let denyResult = denyResult(denyResults) else {
                    SCLogger.info("security policy: get highest priority deny result, merge result return default result")
                    return fastPassResponse.validateResult(userResolver: userResolver, logInfos: validateInfos)
                }
                return denyResult.validateResult(userResolver: userResolver, logInfos: validateInfos)
            }
        }
        
        // 获取deny结果中的最高优先级的deny结果
        private func denyResult(_ results: [ValidateResultProtocol]) -> ValidateResultProtocol? {
            let sortedResults = results.sorted { current, next in
                let currentHighestPriority = highestDenyPriority(of: current.actions)
                let nextHighestPriority = highestDenyPriority(of: next.actions)
                return currentHighestPriority > nextHighestPriority
            }
            
            return sortedResults.first
        }
        
        // 获取allow结果中的最高优先级allow结果
        private func allowResult(_ results: [ValidateResultProtocol]) -> ValidateResultProtocol? {
            let fistDowngradeResult = results.first { result in
                result.shouldFallback == false
            }
            
            // 存在降级结果，即排序取最高优先级结果，否则返回nil，上层取兜底结果
            guard let fistDowngradeResult = fistDowngradeResult else {
                return nil
            }
            // 按照优先级排序，返回最高优先级的结果
            let higestPriorityResult = highestPriorityAllowResult(results)
            return higestPriorityResult ?? fistDowngradeResult
        }
        
        private func highestPriorityAllowResult(_ results: [ValidateResultProtocol]) -> ValidateResultProtocol? {
            // 按结果来源优先级排序
            let sortedResults = results.sorted { current, next in
                let currentPriority = resultMethodPriority[current.resultMethod] ?? 0
                let nextPriority = resultMethodPriority[next.resultMethod] ?? 0
                return currentPriority > nextPriority
            }
            
            let increditableResult = sortedResults.first { result in
                result.isCredible == false
            }
            
            return increditableResult ?? sortedResults.first
        }
        
        private func highestDenyPriority(of actions: [Action]?) -> Int {
            guard let actions = actions else { return 0 }
            let action = actions.max { current, next in
                let currentPriority = actionPriority[current.name] ?? 0
                let nextPriority = actionPriority[next.name] ?? 0
                return currentPriority > nextPriority
            }
            guard let action else {
                return 0
            }
            return actionPriority[action.name] ?? 0
        }
    }
}
