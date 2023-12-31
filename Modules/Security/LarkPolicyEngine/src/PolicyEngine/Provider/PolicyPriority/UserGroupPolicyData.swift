//
//  UserGroupPolicyData.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/9/26.
//

import Foundation

/// user group
struct UserGroupPolicyData: Codable {
    let groupIdList: [Int64]
    var policyMap: PolicyMap
}

extension UserGroupPolicyData: PolicyPriorityExcutor {}
