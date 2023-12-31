//
//  SecurityPolicyCleanTask.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/11/1.
//

import Foundation
import LarkCache
import LarkContainer
import LarkSecurityComplianceInterface

final class SecurityPolicyCleanTask: CleanTask {
    var name = "SecurityPolicyCleanTask"

    let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    func clean(config: LarkCache.CleanConfig, completion: @escaping Completion) {
        DispatchQueue.runOnMainQueue {
            if config.isUserTriggered {
                let service = try? self.resolver.resolve(assert: SecurityPolicyService.self)
                let securityPolicy = service as? SecurityPolicyIMP
                securityPolicy?.markSceneCacheDeletable()
            }
            completion(TaskResult())
        }
    }
}

final class SecurityPolicyEmptyCleanTask: CleanTask {
    var name = "SecurityPolicyEmptyCleanTask"

    func clean(config: LarkCache.CleanConfig, completion: @escaping Completion) {
        completion(TaskResult())
    }
}
