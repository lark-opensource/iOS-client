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

extension SecurityPolicyV2 {
    final class StrategyEngineCaller {
        private let strategyEngine: PolicyEngineService

        private var observers: [StrategyEngineCallerObserver] = []

        init(userResolver: UserResolver) throws {
            strategyEngine = try userResolver.resolve(assert: PolicyEngineService.self)
        }

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
                DispatchQueue.runOnMainQueue {
                    let param = StrategyEngineCallerObserverParam(policyModels: policyModels,
                                                                  policyResponseMap: validateMap,
                                                                  trigger: callTrigger)
                    self.observers.forEach { observer in observer.notify(validateResult: param) }
                    SecurityPolicy.logger.info("security policy: strategy_engine_caller: strategy engine return responses: \(validateMap)")
                    complete?(validateMap)
                    let completeTime = CACurrentMediaTime()
                    let costTime = completeTime - startUpdateTime
                    SecurityPolicyEventTrack.larkSCSFileStrategyUpdate(trigger: callTrigger.rawValue,
                                                                       duration: costTime,
                                                                       result: validateMap.map { $0.value })
                }
            }
        }

        func downgradeDecision(policyModel: PolicyModel) -> ValidateResponse {
            SecurityPolicy.logger.info("security policy: strategy_engine_caller: strategy engine call downgradeDecision when validate policyModel: \(policyModel)")
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

        func registObserver(observer: StrategyEngineCallerObserver) {
            DispatchQueue.runOnMainQueue {
                self.observers.append(observer)
            }
        }
    }

    public struct StrategyEngineCallerObserverParam {
        let policyModels: [PolicyModel]
        let policyResponseMap: [String: ValidateResponse]
        let trigger: StrategyEngineCallTrigger
    }
}

extension SecurityPolicyV2.StrategyEngineCallerObserverParam {
    var successdAndFailedPolicyModels: ([PolicyModel], [PolicyModel]) {
        var failed: [PolicyModel] = []
        var successed: [PolicyModel] = []
        policyModels.forEach { policyModel in
            // TODO: 这个地方可以加个报警
            guard let validateResponse = self.policyResponseMap[policyModel.taskID] else { return }
            switch validateResponse.type {
            case .downgrade:
                failed.append(policyModel)
            default:
                successed.append(policyModel)
            }
        }
        return (successed, failed)
    }

    var successdAndFailedResponseMap: ([String: ValidateResponse],
                                       [String: ValidateResponse]) {
        var failed: [String: ValidateResponse] = [:]
        let successed = policyResponseMap.filter {
            switch $0.value.type {
            case .downgrade:
                failed.updateValue($0.value, forKey: $0.key)
                return false
            default:
                return true
            }
        }
        return (successed, failed)
    }
}

public protocol StrategyEngineCallerObserver {
    func notify(validateResult: SecurityPolicyV2.StrategyEngineCallerObserverParam)
}
