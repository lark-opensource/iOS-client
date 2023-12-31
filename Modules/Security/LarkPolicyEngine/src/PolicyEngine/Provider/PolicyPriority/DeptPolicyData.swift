//
//  DeptPolicyData.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/9/26.
//

import Foundation

/// dept
struct DeptPolicyData: Codable {
    /// 用户所属部门ID
    let userDeptIdsWithParent: [Int64]
    /// 用户所属部门树
    let userDeptIDPaths: [[Int64]]
    let rootNode: DeptNode
    let policyMap: PolicyMap
    
    init(userDeptIdsWithParent: [Int64] = [],
         userDeptIDPaths: [[Int64]] = [[]],
         rootNode: DeptNode = DeptNode(deptId: FACTOR_DEFAULT_VALUE),
         policyMap: PolicyMap = [:]) {
        self.userDeptIdsWithParent = userDeptIdsWithParent
        self.userDeptIDPaths = userDeptIDPaths
        self.rootNode = rootNode
        self.policyMap = policyMap
    }
}

/// 部门节点
class DeptNode: Codable {
    let deptId: Int64
    var children: [Int64: DeptNode]
    var policyMap: PolicyMap
    
    init(deptId: Int64) {
        self.deptId = deptId
        self.children = [:]
        self.policyMap = [:]
    }
}

extension DeptPolicyData: PolicyPriorityExcutor {
    func excute(context: RunnerContext) throws -> RunnerResult {
        return try rootNode.excute(context: context)
    }
}

extension DeptNode: PolicyPriorityExcutor {
    func excute(context: RunnerContext) throws -> RunnerResult {
        var indeterminate: RunnerResult?
        var permit: RunnerResult?
        for node in self.children.values {
            let ret = try node.excute(context: context)
            switch ret.combinedEffect {
            case .deny: return ret
            case .indeterminate: indeterminate = ret
            case .permit:
                if var prePermit = permit {
                    // merge action
                    ret.combinedActions.forEach { action in
                        if !prePermit.combinedActions.contains(action) {
                            prePermit.combinedActions.append(action)
                        }
                    }
                    permit = prePermit
                } else {
                    permit = ret
                }
            case .notApplicable: break
            }
        }
        if let indeterminate = indeterminate {
            return indeterminate
        }
        if let permit = permit {
            return permit
        }
        return try commonExcute(context: context)
    }
}
