//
//  SecurityPolicyCleanTaskV2.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/11/1.
//

import Foundation
import LarkCache
import LarkContainer

extension SecurityPolicyV2 {
    final class SecurityPolicyCleanTask: CleanTask {
        var name = "SecurityPolicyCleanTask"
        let resolver: UserResolver

        init(resolver: UserResolver) {
            self.resolver = resolver
        }

        func clean(config: LarkCache.CleanConfig, completion: @escaping Completion) {
            DispatchQueue.runOnMainQueue {
                if config.isUserTriggered {
                    let cacheManager = try? self.resolver.resolve(assert: SecurityPolicyCacheService.self) as? SecurityPolicyCacheManager
                    cacheManager?.markInvalid()
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
}
