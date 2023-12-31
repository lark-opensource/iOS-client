//
//  TenantPolicyData.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/9/26.
//

import Foundation

struct TenantPolicyData: Codable {
    var policyMap: PolicyMap
}

extension TenantPolicyData: PolicyPriorityExcutor {}
