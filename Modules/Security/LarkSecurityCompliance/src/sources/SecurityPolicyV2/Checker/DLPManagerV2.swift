//
//  DLPManager.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/7.
//

import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkContainer
import RxSwift
import LarkPolicyEngine
import RxCocoa

protocol DLPValidateService: SecurityPolicyChecker {
    
    /// DLP批量更新
    /// - Parameters:
    ///   - policyModels: 校验模型
    ///   - completed: 异步校验回调， 回调中的结果类型为ValidateResponse
    func preValidateDLP(policyModels: [PolicyModel], completed: @escaping(([String: ValidateResponse]) -> Void))
}

fileprivate enum Trigger: String {
    case noCacheRetry = "NoCacheRetry"
    case businessCheck = "BusinessCheck"
    case docScene = "DocScene"
    case cacheInvalid = "CacheInvalid"
}

fileprivate extension PointKey {
    var associatedDynamicPointKey: PointKey? {
        switch self {
        case .ccmCopy: return .ccmCopyObject
        case .ccmExport: return .ccmExportObject
        case .ccmFileDownload: return .ccmFileDownloadObject
        case .ccmAttachmentDownload: return .ccmAttachmentDownloadObject
        case .ccmOpenExternalAccess: return .ccmOpenExternalAccessObject
        default: return nil
        }
    }
}

extension SecurityPolicyV2 {
    class DLPManager: DLPValidateService {
        let api: DLPManagerApi
        let cache: SecurityPolicyCacheService
        let userResolver: UserResolver
        let dlpPeriodOfValidity: Int
        let enableCcmDlp: Bool
        private let disposeBag: DisposeBag = DisposeBag()

        static var downgradeResponse: ValidateResponse {
            return ValidateResponse(effect: .notApplicable, actions: [], uuid: UUID().uuidString, type: .downgrade)
        }

        static var fastPassResponse: ValidateResponse {
            return ValidateResponse(effect: .permit, actions: [], uuid: UUID().uuidString, type: .fastPass)
        }

        var identifier: String {
            "DLPManager"
        }

        init(resolver: UserResolver) throws {
            userResolver = resolver
            api = try DLPManagerApi(resolver: resolver)
            cache = try resolver.resolve(assert: SecurityPolicyCacheService.self)
            let settings = try resolver.resolve(assert: SCSettingService.self)
            dlpPeriodOfValidity = settings.int(SCSettingKey.dlpPeriodOfValidity)
            let fgService = try resolver.resolve(assert: SCFGService.self)
            enableCcmDlp = fgService.realtimeValue(SCFGKey.enableCcmDlp)
        }

        func checkCacheAuth(policyModel: PolicyModel, config: ValidateConfig) -> ValidateResultProtocol? {
            guard let policyModel = associatePolicyModel(policyModel: policyModel) else {
                return nil
            }
            if let cacheResult = cache.value(policyModel: policyModel) {
                if !cacheResult.isCredible {
                    trackInvalidResultIfNeed(policyModel: policyModel, result: cacheResult)
                    validateAndCacheDLP(trigger: .cacheInvalid, policyModels: [policyModel]) { _ in }
                }
                return cacheResult
            }
            // 本地无缓存,触发一次服务端决策做缓存，但本次仍返回降级结果
            validateAndCacheDLP(trigger: .noCacheRetry, policyModels: [policyModel]) { _ in
                SecurityPolicy.logger.info("DLPManager cache result is nil, trigger async finished", additionalData: config)
            }
            return Self.downgradeResponse
        }

        func checkAsyncAuth(policyModel: PolicyModel, config: ValidateConfig, complete: @escaping (ValidateResultProtocol?) -> Void) {
            guard let policyModel = associatePolicyModel(policyModel: policyModel) else {
                complete(nil)
                return
            }
            // 有缓存结果，返回缓存结果
            let cacheResult = cache.value(policyModel: policyModel)
            if let cacheResult = cacheResult, cacheResult.isCredible {
                complete(cacheResult)
                return
            }
            // 无缓存结果，异步请求最新结果
            validateAndCacheDLP(trigger: .businessCheck, policyModels: [policyModel]) { [weak self] results in
                guard let validateReponse = results.first(where: {(taskid, _) in
                    taskid == policyModel.taskID
                })?.value, validateReponse.isCredible else {
                    // 异步无结果时，有缓存返回缓存，否侧返回降级
                    let result = self?.getResultIfAsyncFailed(policyModel: policyModel) ?? Self.downgradeResponse
                    complete(result)
                    return
                }
                complete(validateReponse)
            }
        }

        func preValidateDLP(policyModels: [PolicyModel], completed: @escaping(([String: ValidateResponse]) -> Void)) {
            let associatePolicyModels = associatePolicyModels(policyModels: policyModels)
            guard !associatePolicyModels.isEmpty else { return }
            SecurityPolicy.logger.info("DLPManager pre validate begin")
            validateAndCacheDLP(trigger: .docScene, policyModels: associatePolicyModels) { results in
                completed(results)
            }
        }

        private func validateAndCacheDLP(trigger: Trigger, policyModels: [PolicyModel], completed: @escaping(([String: ValidateResponse]) -> Void)) {
            let startTime = CACurrentMediaTime()
            let status = api.getDlpStatus(policyModels: policyModels)
                .catchError({ error in
                    SecurityPolicy.logger.info("DLP policyStatus request fail", additionalData: ["error": "\(error)"])
                    return .just(true)
                })
                .flatMapLatest { [weak self] res -> Observable<[String: ValidateResponse]> in
                    guard let self else { return .just([:]) }
                    guard res else {
                        // 剪枝通过
                        SecurityPolicy.logger.info("Dlp validate fast pass: \(policyModels.map({ $0.pointKey }))")
                        var results: [String: ValidateResponse] = [:]
                        for item in policyModels {
                            results[item.taskID] = Self.fastPassResponse
                        }
                        return .just(results)
                    }
                    return self.api.getDlpResult(policyModels, downgrade: Self.downgradeResponse)
                }
            status.subscribe { [weak self] results in
                self?.cacheResults(results)
                completed(results)
                SecurityPolicyEventTrack.dlpEngineFetch(trigger: trigger.rawValue, duration: 1000 * (CACurrentMediaTime() - startTime))
            }.disposed(by: self.disposeBag)
        }

        private func cacheResults(_ results: [String: ValidateResponse]) {
            let cacheResults = results.filter { result in
                result.value.type != .downgrade
            }
            SecurityPolicy.logger.info("cache dlp result", additionalData: ["count": "\(cacheResults.count)"])
            let expirationTime = CACurrentMediaTime() + Double(dlpPeriodOfValidity)
            let map = cacheResults.transform(expirationTime: expirationTime)
            self.cache.add(map)
        }

        private func getResultIfAsyncFailed(policyModel: PolicyModel) -> ValidateResultProtocol {
            let cacheResult = self.cache.value(policyModel: policyModel)
            guard let cacheResult else {
                return Self.downgradeResponse
            }
            trackInvalidResultIfNeed(policyModel: policyModel, result: cacheResult)
            return cacheResult
        }

        private func trackInvalidResultIfNeed(policyModel: PolicyModel, result: SecurityPolicyValidateResultCache) {
            guard result.isCredible else { return }
            let currentTime = CACurrentMediaTime()
            SecurityPolicyEventTrack.hitInvalidCache(policyModel: policyModel, checkerType: identifier, duration: currentTime - (result.expirationTime ?? currentTime))
        }
    }
}

extension SecurityPolicyV2.DLPManager {
    func associatePolicyModels(policyModels: [PolicyModel]) -> [PolicyModel] {
        policyModels.compactMap { model in
            self.associatePolicyModel(policyModel: model)
        }
    }
    
    func associatePolicyModel(policyModel: PolicyModel) -> PolicyModel? {
        guard let associatePointKey = policyModel.pointKey.associatedDynamicPointKey else {
            return nil
        }
        switch policyModel.pointKey {
        case .ccmExport, .ccmFileDownload, .ccmAttachmentDownload, .ccmCopy, .ccmOpenExternalAccess, .ccmCreateCopy:
            guard enableCcmDlp else { return nil }
            if let entity = policyModel.entity as? CCMEntity, let tokenEntityType = entity.tokenEntityType {
                return PolicyModel(associatePointKey, CCMEntity(entityType: tokenEntityType,
                                                                entityDomain: entity.entityDomain,
                                                                entityOperate: entity.entityOperate,
                                                                operatorTenantId: entity.operatorTenantId,
                                                                operatorUid: entity.operatorUid,
                                                                fileBizDomain: .ccm,
                                                                token: entity.token,
                                                                ownerTenantId: entity.ownerTenantId,
                                                                ownerUserId: entity.ownerUserId))
            } else if let entity = policyModel.entity as? CalendarEntity, let tokenEntityType = entity.tokenEntityType {
                return PolicyModel(associatePointKey, CCMEntity(entityType: tokenEntityType,
                                                                entityDomain: entity.entityDomain,
                                                                entityOperate: entity.entityOperate,
                                                                operatorTenantId: entity.operatorTenantId,
                                                                operatorUid: entity.operatorUid,
                                                                fileBizDomain: .calendar,
                                                                token: entity.token,
                                                                ownerTenantId: entity.ownerTenantId,
                                                                ownerUserId: entity.ownerUserId))
            }
            return PolicyModel(associatePointKey, policyModel.entity)
        default: return nil
        }
    }
}

fileprivate extension Dictionary where Key == String, Value == ValidateResponse {
    func transform(expirationTime: TimeInterval?) -> [String: SecurityPolicyValidateResultCache] {
        var map: [String: SecurityPolicyValidateResultCache] = [:]
        self.forEach {
            let result = SecurityPolicyValidateResultCache(taskID: $0.key, validateResponse: $0.value, expirationTime: expirationTime)
            map.updateValue(result, forKey: $0.key)
        }
        return map
    }
}
