//
//  PolicyPriorityData.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/9/27.
//

import Foundation

public struct PolicyPriorityData: Codable {
    var user: UserPolicyData
    var userGroup: UserGroupPolicyData
    var department: DeptPolicyData
    var tenant: TenantPolicyData
}

extension PolicyPriorityData {
    func excute(context: RunnerContext) throws -> RunnerResult {
        var cost = RunnerCost()
        let excutors: [PolicyPriorityExcutor] = [user, userGroup, department, tenant]
        for excutor in excutors {
            var ret = try excutor.excute(context: context)
            cost += ret.cost
            ret.cost = cost
            if ret.combinedEffect != .notApplicable {
                return ret
            }
        }
        return RunnerResult(combinedEffect: .notApplicable, cost: cost)
    }
}
