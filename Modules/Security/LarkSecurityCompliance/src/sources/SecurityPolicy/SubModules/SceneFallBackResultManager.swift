//
//  SceneFallbackResultManager.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/12/22.
//

import Foundation
import LarkContainer
import LarkAccountInterface

protocol SceneFallbackResultProtocol {
    subscript(index: Int64) -> Bool { get }
    func merge(_ newValue: [Int64: Bool])
}

final class SceneFallbackResultManager: SceneFallbackResultProtocol {
    private var memoryCache: [Int64: Bool]
    private var localCache: LocalCache

    init(userResolver: UserResolver) {
        let service = try? userResolver.resolve(assert: PassportUserService.self)
        localCache = LocalCache(cacheKey: SecurityPolicyConstKey.sceneFallbackResult,
                                userID: service?.user.userID ?? "")
        memoryCache = localCache.readCache() ?? [:]
    }

    subscript(index: Int64) -> Bool {
        let result = memoryCache[index] ?? true
        SPLogger.info("security policy: scene fallback result manager: tenant id \(index), get fallback result \(result)")
        return result
    }

    func merge(_ newValue: [Int64: Bool]) {
        self.memoryCache.merge(newValue) { current, newValue in return (current && newValue) }
        self.writeLocalCache()

    }

    private func writeLocalCache() {
        localCache.writeCache(value: memoryCache)
    }
}
