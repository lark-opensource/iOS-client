//
//  FallbackResultManager.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/12/22.
//

import Foundation
import LarkContainer
import LarkPolicyEngine
import LarkAccountInterface
import LarkSecurityComplianceInfra
import LarkSecurityComplianceInterface

protocol FallbackResultProtocol: StrategyEngineCallerObserver {
    func getClientFallBackResult(policyModel: PolicyModel) -> ValidateResult
}

extension SecurityPolicyV2 {
    final class FallbackResultManager: FallbackResultProtocol {
        private let settings: SCSettingService
        private let fg: SCFGService
        @SafeWrapper private var memoryCache: [Int64: Bool]
        private var localCache: LocalCache
        private let fallbackResultType: ValidateResultType
        private let userResolver: UserResolver

        init(userResolver: UserResolver) throws {
            self.userResolver = userResolver
            let service = try userResolver.resolve(assert: PassportUserService.self)
            settings = try userResolver.resolve(assert: SCSettingService.self)
            fg = try userResolver.resolve(assert: SCFGService.self)
            fallbackResultType = settings.bool(.fileStrategyFallbackResult) ? .allow : .deny
            localCache = LocalCache(cacheKey: SecurityPolicyConstKey.sceneFallbackResult,
                                                     userID: service.user.userID)
            memoryCache = localCache.readCache() ?? [:]
        }

        func getClientFallBackResult(policyModel: PolicyModel) -> ValidateResult {
            let action = Action(name: "UNIVERSAL_FALLBACK_COMMON")
            let extra = ValidateExtraInfo(resultSource: .unknown,
                                          errorReason: nil,
                                          resultMethod: .fallback,
                                          isCredible: false,
                                          logInfos: [],
                                          rawActions: action.rustActionModel.rawActionModelString)
            guard policyModel.pointKey == .imFileRead,
                  let imFileEntity = policyModel.entity as? IMFileEntity,
                  let senderTenantID = imFileEntity.senderTenantId,
                  !fg.realtimeValue(.enableSecuritySDK) else {
                return ValidateResult(userResolver: userResolver, result: fallbackResultType, extra: extra)
            }
            let result = (self[senderTenantID]) ? ValidateResultType.allow : ValidateResultType.deny
            return ValidateResult(userResolver: userResolver, result: result, extra: extra)
        }

        private subscript(index: Int64) -> Bool {
            let result = memoryCache[index] ?? true
            SecurityPolicy.logger.info("security policy: scene fallback result manager: tenant id \(index), get fallback result \(result)")
            return result
        }

        func notify(validateResult: StrategyEngineCallerObserverParam) {
            validateResult.policyModels.forEach { policyModel in
                if policyModel.pointKey == .imFileRead,
                   let validateResp = validateResult.policyResponseMap[policyModel.taskID],
                   validateResp.type != .downgrade,
                   let imFileEntity = policyModel.entity as? IMFileEntity,
                   let senderTenantId = imFileEntity.senderTenantId {
                    merge([senderTenantId: validateResp.allow])
                }
            }
        }

        private func merge(_ newValue: [Int64: Bool]) {
            self.memoryCache.merge(newValue) { current, newValue in return (current && newValue) }
            self.writeLocalCache()
        }

        private func writeLocalCache() {
            localCache.writeCache(value: memoryCache)
        }
    }
}
