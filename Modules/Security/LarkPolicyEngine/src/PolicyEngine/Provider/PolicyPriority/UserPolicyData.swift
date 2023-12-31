//
//  UserPolicyData.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/9/26.
//

import Foundation

/// single user
struct UserPolicyData: Codable {
    var policyMap: PolicyMap
}

extension UserPolicyData: PolicyPriorityExcutor {}
