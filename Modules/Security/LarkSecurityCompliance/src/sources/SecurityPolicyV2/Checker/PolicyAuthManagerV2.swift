//
//  PolicyAuthManager.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/16.
//

import Foundation
import LarkAccountInterface
import LarkContainer
import LarkPolicyEngine
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import ThreadSafeDataStructure
import LarkFeatureGating
import AppContainer
import RxSwift

extension SecurityPolicyV2 {
    final class PolicyAuthManager: SecurityPolicyChecker {
        // FG 开启启动的子模块
        private var securityStaticUpdator: SecurityStaticUpdator?
        private(set) var delayClearCacheManager: DelayClearCacheManager?
        // FG 无需开启即启动的子模块
        let retryManager: SecurityPolicyRetryManager
        private let cacheManager: SecurityPolicyCacheService
        private let strategyEngineCaller: StrategyEngineCaller
        private let fallBackResultManager: FallbackResultProtocol
        // 基础服务
        let userResolver: UserResolver
        let disposedBag = DisposeBag()
        private let fg: SCFGService
        private var isSubModuleInit = false

        var identifier: String {
            "PolicyAuthManager"
        }

        init(userResolver: UserResolver) throws {
            self.userResolver = userResolver
            fg = try userResolver.resolve(assert: SCFGService.self)
            strategyEngineCaller = try StrategyEngineCaller(userResolver: userResolver)
            retryManager = try SecurityPolicyRetryManager(userResolver: userResolver)
            fallBackResultManager = try userResolver.resolve(assert: FallbackResultProtocol.self)
            cacheManager = try userResolver.resolve(assert: SecurityPolicyCacheService.self)
            setBasicSubmodules()
            guard fg.realtimeValue(.enableSecuritySDK) else {
                let ob = fg.observe(.enableSecuritySDK)
                ob.observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] isOpen in
                        guard let self else { return }
                        if !self.isSubModuleInit, isOpen {
                            self.setControledByFgSubmodules()
                        }
                    }).disposed(by: disposedBag)
                return
            }
            self.setControledByFgSubmodules()
        }

        private func setControledByFgSubmodules() {
            isSubModuleInit = true
            // 延迟清理
            if let delayClearCacheManager = try? DelayClearCacheManager(userResolver: userResolver) {
                delayClearCacheManager.clearCacheBlock = { [weak self] taskIDList in
                    self?.cacheManager.removeValue(taskIDList)
                    SecurityPolicy.logger.info("security policy: delay clear cache manager: delay clear cache, clear policy models \(taskIDList)")
                }
                self.delayClearCacheManager = delayClearCacheManager
                strategyEngineCaller.registObserver(observer: delayClearCacheManager)
            }

            // 更新
            if let securityStaticUpdator = try? SecurityStaticUpdator(userResolver: userResolver) {
                securityStaticUpdator.updateStaticPolicyModel = { [weak self] in
                    self?.retryManager.clearRetryTask() // 理论上应该放在 retryManager 中，下次优化
                    self?.strategyEngineCaller.checkAuth(policyModels: $0, callTrigger: $1.callTrigger) { _ in
                        SecurityPolicy.logger.info("security policy: security_policy_manager: successfuly update static cache")
                    }
                }
                self.securityStaticUpdator = securityStaticUpdator
            }
        }

        private func setBasicSubmodules() {
            // 重试
            retryManager.retryBlock = { [weak self] in
                guard let self else { return }
                let policyModels = self.retryManager.retryList.keys.map { $0 }
                self.strategyEngineCaller.checkAuth(policyModels: policyModels,
                                                    callTrigger: .retry,
                                                    complete: nil)
                SecurityPolicy.logger.info("security policy: security policy retry manager: begin retry, call strategy engine with policy models \(policyModels.map { $0.taskID })")
            }
            strategyEngineCaller.registObserver(observer: retryManager)
            // 缓存
            strategyEngineCaller.registObserver(observer: cacheManager)
            // 动态点位兜底
            strategyEngineCaller.registObserver(observer: fallBackResultManager)
        }

        func checkCacheAuth(policyModel: PolicyModel, config: ValidateConfig) -> ValidateResultProtocol? {
            guard fg.realtimeValue(.enableSecuritySDK) || policyModel.pointKey.isScene else {
                SecurityPolicy.logger.info("security policy: fg enable file strategy is close", additionalData: config, policyModel)
                return nil
            }
            guard let policyModel = associatePolicyModel(policyModel: policyModel) else {
                SecurityPolicy.logger.info("security policy: no associate static model", additionalData: config, policyModel)
                return nil
            }
            // 如果 PolicyModel 为 CCM 点位，则暂时将文件类型修改成 doc 以减少 enforce 接口压力
            policyModel.entity.temporaryIntegrateToDoc()
            if let cacheResponse = strategyCacheAuth(policyModel: policyModel) {
                if !cacheResponse.isCredible {
                    self.strategyEngineCaller.checkAuth(policyModels: [policyModel], callTrigger: .noCacheRetry, complete: nil)
                }
                SecurityPolicy.logger.info("security policy: get cache response succeeded", additionalData: config, policyModel)
                return cacheResponse
            }
            self.strategyEngineCaller.checkAuth(policyModels: [policyModel], callTrigger: .noCacheRetry, complete: nil)
            return strategyEngineCaller.downgradeDecision(policyModel: policyModel)
        }

        func checkAsyncAuth(policyModel: PolicyModel, config: ValidateConfig, complete: @escaping (ValidateResultProtocol?) -> Void) {
            guard fg.realtimeValue(.enableSecuritySDK) || policyModel.pointKey.isScene else {
                SecurityPolicy.logger.info("security policy: fg enable file strategy is close", additionalData: config, policyModel)
                complete(nil)
                return
            }
            guard let policyModel = associatePolicyModel(policyModel: policyModel) else {
                SecurityPolicy.logger.info("security policy: no associate static model", additionalData: config, policyModel)
                complete(nil)
                return
            }
            // 如果 PolicyModel 为 CCM 点位，则暂时将文件类型修改成 doc 以减少 enforce 接口压力
            policyModel.entity.temporaryIntegrateToDoc()
            if let cacheResponse = strategyCacheAuth(policyModel: policyModel),
               cacheResponse.isCredible {
                SecurityPolicy.logger.info("security policy: get cache response succeeded", additionalData: config, policyModel)
                complete(cacheResponse)
                return
            }
            strategyEngineCaller.checkAuth(policyModels: [policyModel], callTrigger: .businessCheck) { [weak self] validateResults in
                guard let self else {
                    complete(nil)
                    return
                }
                if let validateResponse = validateResults.first?.value {
                    if !validateResponse.isCredible,
                       let cacheResponse = self.strategyCacheAuth(policyModel: policyModel) {
                        SecurityPolicy.logger.info("security policy: async failed, get cache response succeeded", additionalData: config, policyModel)
                        complete(cacheResponse)
                        return
                    }
                    SecurityPolicy.logger.info("security policy: get async response succeeded", additionalData: config, policyModel)
                    complete(validateResponse)
                    return
                }
                let downgradeResp = self.strategyEngineCaller.downgradeDecision(policyModel: policyModel)
                complete(downgradeResp)
            }
        }

        func checkAuth(policyModels: [PolicyModel],
                       config: ValidateConfig?,
                       complete: @escaping(([String: ValidateResultProtocol]) -> Void)) {
            // 如果 PolicyModel 为 CCM 点位，则暂时将文件类型修改成 doc 以减少 enforce 接口压力
            let normalizePolicyModels = temporaryIntegrateToDoc(policyModels)
            var validateResults: [String: ValidateResultProtocol] = [:]
            let strategyModels = normalizePolicyModels.compactMap { policyModel -> PolicyModel? in
                if let cacheResponse = strategyCacheAuth(policyModel: policyModel),
                   cacheResponse.isCredible {
                    validateResults[policyModel.taskID] = cacheResponse
                    return nil
                }
                return policyModel
            }
            strategyEngineCaller.checkAuth(policyModels: strategyModels,
                                           callTrigger: .businessCheck) { [weak self] validateResponses in
                guard let self else {
                    complete([:])
                    return
                }
                validateResponses.forEach { validateResponsePair in
                    let taskID = validateResponsePair.key
                    let engineResponse = validateResponsePair.value
                    guard let policyModel = strategyModels.first(where: { $0.taskID == taskID }) else {
                        SecurityPolicy.logger.info("security policy: did not get response of policyModel: \(taskID)", additionalData: config)
                        return
                    }
                    if !engineResponse.isCredible,
                       let cacheResponse = self.strategyCacheAuth(policyModel: policyModel) {
                        validateResults[taskID] = cacheResponse
                        return
                    }
                    validateResults[taskID] = engineResponse
                }
                complete(validateResults)
            }
        }

        private func temporaryIntegrateToDoc(_ policyModels: [PolicyModel]) -> [PolicyModel] {
            return policyModels.map { policyModel in
                policyModel.entity.temporaryIntegrateToDoc()
                return policyModel
            }
        }

        private func strategyCacheAuth(policyModel: PolicyModel) -> SecurityPolicyValidateResultCache? {
            let result = cacheManager.value(policyModel: policyModel)
            // map中存储的值也可能为nil
            if let delayTime = delayClearCacheManager?.ipPolicyModelMap[policyModel.taskID],
               let delayTime {
                let duration = DelayClearCacheManager.ntpTime - delayTime
                SecurityPolicyEventTrack.scsSecurityPolicyHitDelayClearCache(policyModel: policyModel,
                                                                             duration: duration)
            }
            return result
        }

        func isEnableFastPass(policyModel: PolicyModel) -> Bool {
            return strategyEngineCaller.isEnableFastPass(policyModel: policyModel)
        }
    }
}

extension SecurityPolicyV2.PolicyAuthManager {
    func associatePolicyModels(policyModels: [PolicyModel]) -> [PolicyModel] {
        policyModels.compactMap { model in
            self.associatePolicyModel(policyModel: model)
        }
    }
    
    func associatePolicyModel(policyModel: PolicyModel) -> PolicyModel? {
        switch policyModel.pointKey {
        case .ccmExport, .ccmFileDownload, .ccmAttachmentDownload, .ccmCopy, .ccmCreateCopy:
            if let entity = policyModel.entity as? CCMEntity {
                return PolicyModel(policyModel.pointKey, CCMEntity(entityType: entity.entityType,
                                                            entityDomain: entity.entityDomain,
                                                            entityOperate: entity.entityOperate,
                                                            operatorTenantId: entity.operatorTenantId,
                                                            operatorUid: entity.operatorUid,
                                                            fileBizDomain: .ccm))
            } else if let entity = policyModel.entity as? CalendarEntity {
                return PolicyModel(policyModel.pointKey, CalendarEntity(entityType: entity.entityType,
                                                            entityDomain: entity.entityDomain,
                                                            entityOperate: entity.entityOperate,
                                                            operatorTenantId: entity.operatorTenantId,
                                                            operatorUid: entity.operatorUid,
                                                            fileBizDomain: .calendar))
            }
            return nil
        case .ccmOpenExternalAccess: return nil
        default: return policyModel
        }
    }
}
