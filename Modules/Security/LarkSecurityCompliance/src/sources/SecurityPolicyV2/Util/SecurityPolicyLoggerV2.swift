//
//  SecurityPolicyLogger.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/16.
//

import Foundation
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface
import LKCommonsLogging
import RustSDK
import LarkContainer

extension SecurityPolicy {
    static let logger = SCLogger(tag: "security_policy")
}
