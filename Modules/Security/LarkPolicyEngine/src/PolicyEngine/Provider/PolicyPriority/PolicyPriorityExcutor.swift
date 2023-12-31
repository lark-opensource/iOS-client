//
//  PolicyPriorityExcutor.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/9/26.
//

import Foundation

protocol PolicyPriorityExcutor {
    var policyMap: PolicyMap { get }
    func excute(context: RunnerContext) throws -> RunnerResult
}

extension PolicyPriorityExcutor {
    func excute(context: RunnerContext) throws -> RunnerResult {
        return try commonExcute(context: context)
    }
    
    func commonExcute(context: RunnerContext) throws -> RunnerResult {
        let policies = context.policies.filter { element in
            policyMap.keys.contains(element.key)
        }
        let execContext = RunnerContext(uuid: context.uuid, contextParams: context.contextParams, policies: policies, combineAlgorithm: context.combineAlgorithm, service: context.service)
        let runner = PolicyRunner(context: execContext)
        return try runner.runPolicy()
    }
}
