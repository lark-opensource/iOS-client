//
//  ValidateContext.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/10/27.
//

import Foundation

struct ValidateContext {
    let policyProvider: PolicyProvider
    let pointCutProvider: PointCutProvider
    let priorityProvider: PolicyPriorityProvider
    let factors: [String: Any]
    let baseParam: [String: Parameter]
}
