//
//  StrategyEngineCaller.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/16.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkAccountInterface
import LarkPolicyEngine
import LarkContainer

final class StrategyEngineCaller {
    @LarkContainer.Provider var strategyEngine: PolicyEngineService
    @LarkContainer.Provider var userService: PassportUserService

    private var observerList: [((StrategyEngineCallerObserverParam) -> Void)] = []

    // 异步
    func checkAuth(policyModels: [PolicyModel],
                   callTrigger: StrategyEngineCallTrigger,
                   complete: (([String: ValidateResponse]) -> Void)?) {
        let startUpdateTime = CACurrentMediaTime()
        let requestMap = policyModels.reduce([String: ValidateRequest]()) { prior, element in
            var tempMap = prior
            tempMap.updateValue(wrapPolicyModel(policyModel: element), forKey: element.taskID)
            return tempMap
        }

        strategyEngine.asyncValidate(requestMap: requestMap) { [weak self] validateMap in
            guard let self else { return }
            var needCacheMap = validateMap
            let needCacheModels = policyModels.filter {
                let isNotNeedCache = SecurityPolicyConstKey.disableCacheList.contains($0.pointKey)
                if isNotNeedCache { needCacheMap.removeValue(forKey: $0.taskID) }
                return !isNotNeedCache
            }
            let param = StrategyEngineCallerObserverParam(policyModels: needCacheModels,
                                                          policyResponseMap: needCacheMap,
                                                          trigger: callTrigger)
            self.observerList.forEach { observerBlock in observerBlock(param) }
            SPLogger.info("security policy: strategy_engine_caller: strategy engine return responses: \(validateMap)")
            complete?(validateMap)
            let completeTime = CACurrentMediaTime()
            let costTime = completeTime - startUpdateTime
            SecurityPolicyEventTrack.larkSCSFileStrategyUpdate(trigger: callTrigger.rawValue,
                                                               duration: costTime,
                                                               result: validateMap.map { $0.value })
        }
    }

    func downgradeDecision(policyModel: PolicyModel) -> ValidateResponse {
        SPLogger.info("security policy: strategy_engine_caller: strategy engine call downgradeDecision when validate policyModel: \(policyModel)")
        let engineParam = wrapPolicyModel(policyModel: policyModel)
        return strategyEngine.downgradeDecision(request: engineParam)
    }

    private func wrapPolicyModel(policyModel: PolicyModel) -> ValidateRequest {
        return ValidateRequest(pointKey: policyModel.pointKey.rawValue, entityJSONObject: policyModel.entity.asParams())
    }

    func isEnableFastPass(policyModel: PolicyModel) -> Bool {
        let request = wrapPolicyModel(policyModel: policyModel)
        return strategyEngine.enableFastPass(request: request)
    }

    func register(observer: Observer) {
        strategyEngine.register(observer: observer)
    }

    func remove(observer: Observer) {
        strategyEngine.remove(observer: observer)
    }

    func registerAuth(observer: @escaping ((StrategyEngineCallerObserverParam) -> Void)) {
        observerList.append(observer)
    }
}

public struct StrategyEngineCallerObserverParam {
    let policyModels: [PolicyModel]
    let policyResponseMap: [String: ValidateResponse]
    let trigger: StrategyEngineCallTrigger
}
