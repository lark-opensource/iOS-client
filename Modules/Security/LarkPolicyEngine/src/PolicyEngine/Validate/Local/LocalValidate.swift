//
//  LocalValidate.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/9/30.
//

import Foundation
import LarkSnCService
import ByteDanceKit

private let reportQueue = DispatchQueue(label: "policy_engine.local_validate.report_queue", qos: .default)

final class LocalValidate {

    let service: SnCService

    init(service: SnCService) {
        self.service = service
    }

    func validate(
        requestMap: [String: ValidateRequest],
        context: ValidateContext
    ) -> [String: ValidateResponse] {
        var resultMap = [String: ValidateResponse]()

        for (taskID, request) in requestMap {
            do {
                resultMap[taskID] = try validate(request: request, context: context)
            } catch let error as PolicyEngineError {
                resultMap[taskID] = ValidateResponse(effect: .indeterminate, actions: [], uuid: request.uuid, type: .local, errorMsg: error.message)
                error.report(monitor: service.monitor)
                service.logger?.error("uuid:\(request.uuid), message:\(error.message)")
            } catch let error as ActionResolverError {
                resultMap[taskID] = ValidateResponse(effect: .indeterminate, actions: [], uuid: request.uuid, type: .local, errorMsg: error.description)
                service.logger?.error("uuid:\(request.uuid), message:\(error.description)")
            } catch {
                // 未知异常
                let err = PolicyEngineError(error: .policyError(.unknow), message: error.localizedDescription)
                resultMap[taskID] = ValidateResponse(effect: .indeterminate, actions: [], uuid: request.uuid, type: .local, errorMsg: err.message)
                err.report(monitor: service.monitor)
                service.logger?.error("uuid:\(request.uuid), message:\(err.message)")
            }
        }
        return resultMap
    }

    private func validate(request: ValidateRequest, context: ValidateContext) throws -> ValidateResponse {
        let startTime = CFAbsoluteTimeGetCurrent()
        guard let pointcut = context.pointCutProvider.selectPointcutInfo(by: request) else {
            // 没有查询到切点，1. 服务端没有下发， 2. 切点信息拉取失败
            let errorMsg = "Can not find pointcut by pointKey :\(request.pointKey)"
            service.logger?.error(errorMsg)
            return ValidateResponse(effect: .indeterminate, actions: [], uuid: request.uuid, type: .local, errorMsg: errorMsg)
        }
        let supportPolicyTypes = pointcut.appliedPolicyTypes.filter { policyType in
            return SUPPORT_POLICY_TYPES.contains { $0 == policyType }
        }
        guard let policyType = supportPolicyTypes.first else {
            // 切点没有配置要执行的策略类型
            let errorMsg = "Can not find policy type in pointcut info, pointkey: \(request.pointKey)"
            service.logger?.error(errorMsg)
            return ValidateResponse(effect: .indeterminate, actions: [], uuid: request.uuid, type: .local, errorMsg: errorMsg)
        }

        // 构建参数上下文
        var params: [String: Any] = [:]
        for (key, valueFunc) in context.baseParam {
            params[key] = valueFunc.value()
        }
        pointcut.tags.forEach { item in
            params[item.key] = item.value
        }
        for (key, value) in pointcut.contextDerivation {
            params[key] = (request.entityJSONObject as NSDictionary).value(forKeyPath: value) ?? params[key]
        }
        for (key, value) in context.factors {
            params[key] = value
        }
        service.logger?.info("validate request, uuid: \(request.uuid), pointKey:\(request.pointKey), params:\(params)")

        // 查询策略组合算法
        let combineAlgorithm = try context.policyProvider.selectPolicyCombineAlgorithm(by: policyType)
        // 选取策略
        let policies = context.policyProvider.selectPolicy(by: policyType)
        if policies.isEmpty {
            service.logger?.info("uuid:\(request.uuid), Can not find policy by policy type: \(policyType)")
            return ValidateResponse(effect: .notApplicable, actions: [], uuid: request.uuid, type: .local)
        }

        let runnerContext = RunnerContext(uuid: request.uuid,
                                          contextParams: params,
                                          policies: policies,
                                          combineAlgorithm: combineAlgorithm,
                                          service: service)
        
        // 无策略优先级信息
        guard let priorityData = context.priorityProvider.priorityData else {
            service.logger?.info("uuid:\(request.uuid), Can not get policy priority data")
            return ValidateResponse(effect: .indeterminate, actions: [], uuid: request.uuid, type: .local)
        }
        let result = try priorityData.excute(context: runnerContext)
        
        let actions = try result.combinedActions.compactMap { actionName in
            return try ActionResolver.resolve(action: actionName, request: request)
        }

        var response = ValidateResponse(effect: result.combinedEffect, actions: actions, uuid: request.uuid, type: .local, policySetKeys: [policyType.rawValue])
        response.logInfo.parseCost = result.cost.parseCost
        response.logInfo.execCost = result.cost.execCost
        response.logInfo.paramCost = result.cost.paramCost
        response.logInfo.exprCount = result.cost.exprCount
        response.logInfo.totalCost = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1_000_000)
        response.logInfo.exprEngineType = result.cost.excutorType
        if result.combinedEffect == .deny {
            reportQueue.async { [weak self] in
                self?.reportLocalValidateLog(validateRequest: request, runnerResult: result, policyType: policyType, contextParam: params)
            }
        }
        return response
    }

    private func reportLocalValidateLog(validateRequest: ValidateRequest,
                                        runnerResult: RunnerResult,
                                        policyType: PolicyType,
                                        contextParam: [String: Any]) {
        let reportURL = "/lark/scs/guardian/policy_engine/policy_log/report/v2"
        guard let domain: String = service.environment?.get(key: "domain") else {
            // lost domain
            service.logger?.error("uuid:\(validateRequest.uuid), lost domain, please set domain before use policy engine.")
            assertionFailure("uuid:\(validateRequest.uuid), lost domain，please set domain.")
            return
        }

        var request = HTTPRequest(domain, path: reportURL, method: .post)
        request.retryCount = 2
        request.retryDelay = .seconds(5)
        var enablePolicies = [ [String: Any] ]()
        runnerResult.hits.forEach { policyItemResult in
            enablePolicies.append(
                [
                    "policyID": policyItemResult.policy.id,
                    "policyName": policyItemResult.policy.name,
                    "version": policyItemResult.policy.version,
                    "isExecuted": policyItemResult.isExecuted,
                    "ruleGroupResult": policyItemResult.isExecuted ? [
                        "effect": policyItemResult.effect.rawValue,
                        "actions": policyItemResult.actions,
                        "combineAlgorithm": policyItemResult.policy.combineAlgorithm.rawValue
                    ] as [String: Any] : [:]
                ]
            )
        }

        let tenantID: Int64 = contextParam["TENANT_ID"] as? Int64 ?? -1

        let logParam: [String: Any] = [
            "tenantID": String(tenantID),
            "enablePolicies": enablePolicies,
            "contextParam": ((contextParam as NSDictionary).btd_jsonStringEncoded()) ?? "",
            "evaluateTime": "\(Int(Date().timeIntervalSince1970 * 1000))",
            "logid": validateRequest.uuid,
            "policyType": policyType.rawValue,
            "effect": runnerResult.combinedEffect.rawValue,
            "actions": runnerResult.combinedActions,
            "advice": "MIDDLE",
            "extra": ["terminal": "ios"]
        ]
        
        let isPreEvaluate = (validateRequest.entityJSONObject as NSDictionary).value(forKeyPath: "base.GUARDIAN_EVALUATOR_OPTION.IS_PRE_EVALUATE") as? Bool ?? false

        request.data = [
            "policyLog": logParam,
            "isPreEvaluate": isPreEvaluate
        ]
        service.client?.request(request, completion: { [weak self] result in
            switch result {
            case .success:
                self?.service.logger?.info("success upload local validate log.")
            case .failure(let err):
                self?.service.logger?.error("fail upload local validate log, error: \(err)")
            }
        })
    }
}
