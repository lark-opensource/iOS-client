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

protocol DLPManagerProtocol: SecurityPolicyCheckerProtocol {
    
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

class DLPManager: DLPManagerProtocol {
    let api: DLPManagerApi
    let cache: SecurityPolicyCacheProtocol
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
        cache = try resolver.resolve(assert: SecurityPolicyCacheProtocol.self)
        let settings = try resolver.resolve(assert: SCSettingService.self)
        dlpPeriodOfValidity = settings.int(SCSettingKey.dlpPeriodOfValidity)
        let fgService = try resolver.resolve(assert: SCFGService.self)
        enableCcmDlp = fgService.realtimeValue(SCFGKey.enableCcmDlp)
    }
    
    func checkCacheAuth(policyModel: PolicyModel, config: ValidateConfig) -> ValidateResultProtocol? {
        guard let policyModel = associatePolicyModel(policyModel: policyModel) else {
            return nil
        }
        let additional = ["cid": config.cid]
        if let cacheResult = cache.read(policyModel: policyModel) {
            trackInvalidResultIfNeed(policyModel: policyModel, result: cacheResult)
            if !cacheResult.isCredible {
                validateAndCacheDLP(trigger: .cacheInvalid, policyModels: [policyModel]) { _ in }
            }
            return cacheResult
        }
        // 本地无缓存,触发一次服务端决策做缓存，但本次仍返回降级结果
        validateAndCacheDLP(trigger: .noCacheRetry, policyModels: [policyModel]) { _ in
            SCLogger.info("DLPManager cache result is nil, trigger async finished", additionalData: additional)
        }
        return Self.downgradeResponse
    }
    
    func checkAsyncAuth(policyModel: PolicyModel, config: ValidateConfig, complete: @escaping (ValidateResultProtocol?) -> Void) {
        guard let policyModel = associatePolicyModel(policyModel: policyModel) else {
            complete(nil)
            return
        }
        // 有缓存结果，返回缓存结果
        let cacheResult = cache.read(policyModel: policyModel)
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
        SCLogger.info("DLPManager pre validate begin")
        validateAndCacheDLP(trigger: .docScene, policyModels: associatePolicyModels) { results in
            completed(results)
        }
    }
    
    private func validateAndCacheDLP(trigger: Trigger, policyModels: [PolicyModel], completed: @escaping(([String: ValidateResponse]) -> Void)) {
        let startTime = CACurrentMediaTime()
        let status = api.getDlpStatus(policyModels: policyModels)
            .catchError({ error in
                SPLogger.info("DLP policyStatus request fail", additionalData: ["error": "\(error)"])
                return .just(true)
            })
            .flatMapLatest { [weak self] res -> Observable<[String: ValidateResponse]> in
                guard let self else { return .just([:]) }
                guard res else {
                    // 剪枝通过
                    SCLogger.info("Dlp validate fast pass: \(policyModels.map({ $0.pointKey }))")
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
        SCLogger.info("cache dlp result", additionalData: ["count": "\(cacheResults.count)"])
        self.cache.merge(cacheResults, expirationTime: CACurrentMediaTime() + Double(dlpPeriodOfValidity))
    }
    
    private func getResultIfAsyncFailed(policyModel: PolicyModel) -> ValidateResultProtocol {
        let cacheResult = self.cache.read(policyModel: policyModel)
        guard let cacheResult else {
            return Self.downgradeResponse
        }
        trackInvalidResultIfNeed(policyModel: policyModel, result: cacheResult)
        return cacheResult
    }
    
    private func trackInvalidResultIfNeed(policyModel: PolicyModel, result: SceneLocalCache) {
        guard result.isCredible else { return }
        let currentTime = CACurrentMediaTime()
        SecurityPolicyEventTrack.hitInvalidCache(policyModel: policyModel, checkerType: identifier, duration: currentTime - (result.expirationTime ?? currentTime))
    }
}

extension DLPManager {
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
