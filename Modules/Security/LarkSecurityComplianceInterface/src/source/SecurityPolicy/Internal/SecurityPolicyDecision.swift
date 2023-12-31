//
//  SecurityPolicyDecision.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2023/9/5.
//

import Foundation
public protocol SecurityPolicyActionDecision {
    func handleAction(_ action: SecurityActionProtocol)
    func handleNoPermissionAction(_ action: SecurityActionProtocol)
}
