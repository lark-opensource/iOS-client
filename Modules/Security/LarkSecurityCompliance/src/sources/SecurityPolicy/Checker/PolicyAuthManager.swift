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

final class PolicyAuthManager: SecurityPolicyCheckerProtocol {
    private let settings: Settings?
    private let netWorkMonitor: NetworkMonitor
    private let strategyObserver = StrategyObserver()
    private let strategyEngineCaller = StrategyEngineCaller()
    // 缓存
    private let staticCache: StrategyEngineStaticCache
    private let sceneCache: SecurityPolicyCacheProtocol
    private let cacheUpdateDebouncer: UpdateFrequencyManager
    private let retryManager: SecurityPolicyRetryManager
    private let delayClearCacheManager: DelayClearCacheManager
    private var sceneFallBackResultManager: SceneFallbackResultProtocol
    let userResolver: UserResolver
    private var isInitial = false
    
    var fasstPassResponse: ValidateResponse {
        return ValidateResponse(effect: .notApplicable, actions: [], uuid: UUID().uuidString, type: .fastPass)
    }
    
    var identifier: String {
        "PolicyAuthManager"
    }

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.settings = try? userResolver.resolve(assert: Settings.self)
        self.netWorkMonitor = NetworkMonitor(userResolver: userResolver)
        self.retryManager = SecurityPolicyRetryManager(userResolver: userResolver)
        self.staticCache = StrategyEngineStaticCache(userResolver: userResolver)
        self.sceneFallBackResultManager = try userResolver.resolve(assert: SceneFallbackResultProtocol.self)
        self.delayClearCacheManager = DelayClearCacheManager(userResolver: userResolver)
        self.sceneCache = try userResolver.resolve(assert: SecurityPolicyCacheProtocol.self)
        self.cacheUpdateDebouncer = UpdateFrequencyManager(userResolver: userResolver)
        setBasicSubmodules()
        setControlledByFgSubmodulesIfNeed()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        strategyEngineCaller.remove(observer: strategyObserver)
        netWorkMonitor.stop()
    }

    private func setControledByFgSubmodules() {
        // 延迟清理
        delayClearCacheManager.clearCacheBlock = { [weak self] taskIDList in
            self?.staticCache.clearByTaskID(needClear: taskIDList)
#if DEBUG || ALPHA
            let policyModels = taskIDList.map { PolicyModel.policyModel(taskID: $0) }
            let modelDebugDescriptions = policyModels.map { $0?.description }
            SPLogger.info("security policy: delay clear cache manager: delay clear cache,clear policy models \(modelDebugDescriptions)")
#else
            SPLogger.info("security policy: delay clear cache manager: delay clear cache,clear policy models \(taskIDList)")
#endif
        }

        strategyEngineCaller.registerAuth { [weak self] in
            guard let self else { return }
            let policyModels = $0.policyModels
            let policyResponseMap = $0.policyResponseMap
            let (succeussAuhtPolicyModel, _) = self.validateMapSlipByisSuccess(policyModels: policyModels,
                                                                               validateMap: policyResponseMap)
            self.delayClearCacheManager.removeSuccessUpdatedPolicyModel(successPolicyModel: succeussAuhtPolicyModel)
        }

        // 更新
        cacheUpdateDebouncer.callback = { [weak self] isFullUpdate, trigger, complete in
            guard let self else { return }
            SPLogger.info("security policy: security_policy_manager: strat update static cache")
            let staticPolicyModels = SecurityPolicyConstKey.staticPolicyModel
            let updatePolicyModels = isFullUpdate ? staticPolicyModels : self.delayClearCacheManager.ipPolicyList
            self.delayClearCacheManager.checkPointcutIsControlledByFactors(policyModels: staticPolicyModels, factor: ["SOURCE_IP_V4"])
            self.retryManager.clearRetryTask()
            self.strategyEngineCaller.checkAuth(policyModels: updatePolicyModels, callTrigger: trigger) { validateMap in
                let validateResponses = validateMap.map { $0.value }
                complete?(validateResponses)
                SPLogger.info("security policy: security_policy_manager: successfuly update static cache")
            }
        }

        setUpObserver()
        updateResultCache(updateTrigger: .constructor)
    }

    private func setBasicSubmodules() {
        // 重试
        retryManager.retryBlock = { [weak self] in
            guard let self else { return }
            let policyModels = self.retryManager.retryList.keys.map { $0 }
            self.strategyEngineCaller.checkAuth(policyModels: policyModels,
                                                callTrigger: .retry,
                                                complete: nil)
#if DEBUG || ALPHA
            SPLogger.info("security policy: security policy retry manager: begin retry, call strategy engine with policy models \(policyModels.map { $0.debugDescription })")
#else
            SPLogger.info("security policy: security policy retry manager: begin retry, call strategy engine with policy models \(policyModels.map { $0.taskID })")
#endif
        }

        strategyEngineCaller.registerAuth { [weak self] in
            guard let self else { return }
            let policyModels = $0.policyModels
            let policyResponseMap = $0.policyResponseMap
            let trigger = $0.trigger
            let (succeussAuhtPolicyModel, failAuthPolicyModel) = self.validateMapSlipByisSuccess(policyModels: policyModels,
                                                                                                 validateMap: policyResponseMap)
            self.retryManager.updateRetryList(successList: succeussAuhtPolicyModel)
            self.retryManager.retryAuthPolicyModels(failList: failAuthPolicyModel, trigger: trigger)
        }
        // 缓存
        strategyEngineCaller.registerAuth { [weak self] in
            let policyResponseMap = $0.policyResponseMap
            var cacheValidateResults: [String: ValidateResponse] = [:]
            policyResponseMap.forEach { element in
                switch element.value.type {
                case .downgrade:
                    break
                default:
                    cacheValidateResults.updateValue(element.value, forKey: element.key)
                }
            }
            self?.cacheResult(newValue: cacheValidateResults)
        }
        // 动态点位兜底
        strategyEngineCaller.registerAuth { [weak self] in
            let policyModels = $0.policyModels
            let policyResponseMap = $0.policyResponseMap
            policyModels.forEach { policyModel in
                if let validateResp = policyResponseMap[policyModel.taskID],
                   policyModel.pointKey == .imFileRead,
                   validateResp.type != .downgrade,
                   let imFileEntity = policyModel.entity as? IMFileEntity,
                   let senderTenantId = imFileEntity.senderTenantId {
                    self?.sceneFallBackResultManager.merge([senderTenantId: validateResp.allow])
                }
            }
        }
    }
    private func validateMapSlipByisSuccess(policyModels: [PolicyModel],
                                            validateMap: [String: ValidateResponse]) -> ([PolicyModel], [PolicyModel]) {
        var failModel: [PolicyModel] = []
        let successModel = policyModels.filter { policyModel in
            guard let validateResponse = validateMap[policyModel.taskID] else { return false }
            switch validateResponse.type {
            case .downgrade:
                failModel.append(policyModel)
                return false
            default:
                return true
            }
        }

        return (successModel, failModel)
    }

    private func setUpObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        strategyObserver.updateHandler = { [weak self] in
            self?.updateResultCache(updateTrigger: .strategyEngine)
        }
        strategyEngineCaller.register(observer: strategyObserver)

        netWorkMonitor.handler = { [weak self] _ in
            self?.updateResultCache(updateTrigger: .networkChange)
            let engine = try? self?.userResolver.resolve(assert: PolicyEngineService.self)
            engine?.postEvent(event: .networkChanged)
        }
        netWorkMonitor.start()
    }

    func interceptDialogFilterResult(policyModel: PolicyModel,
                                     config: ValidateConfig?,
                                     result: ValidateResponse) {
        let config = config ?? ValidateConfig()
        if config.ignoreSecurityOperate {
            SPLogger.info("\(policyModel.pointKey) ignore security operate")
            return
        }
        if !result.allow {
            var decision: NoPermissionRustActionDecision?
            if let fgService = try? userResolver.resolve(assert: SCFGService.self),
               fgService.realtimeValue(.enableSecurityUserContainerOpt) {
                decision = try? userResolver.resolve(assert: NoPermissionRustActionDecision.self)
            } else {
                decision = userResolver.resolve(NoPermissionRustActionDecision.self)  // global
            }
            
            if let action = result.actions.first, let decision {
                let actionModel = action.rustActionModel
                DispatchQueue.runOnMainQueue {
                    decision.handleAction(actionModel)
                }
                SecurityPolicyEventTrack.larkSCSHandleAction(actionSource: .sdkInternal,
                                                             actionName: actionModel.model?.name ?? "NO_ACTION")
            } else {
                SPLogger.error("security policy: wrong action, cant process security operation")
            }
        }
    }
    
    func checkCacheAuth(policyModel: PolicyModel, config: ValidateConfig) -> ValidateResultProtocol? {
        setControlledByFgSubmodulesIfNeed()
        var additional = ["cid": config.cid]
        additional["pointKey"] = policyModel.pointKey.rawValue
        additional["entityOperate"] = policyModel.entity.entityOperate.rawValue
        guard SecurityPolicyConstKey.enableFGorIsScene(resolver: self.userResolver, isScene: policyModel.isScene) else {
            SPLogger.info("security policy: fg enable file strategy is close", additionalData: additional)
            return nil
        }
        guard let policyModel = associatePolicyModel(policyModel: policyModel) else {
            SCLogger.info("security policy: no associate static model", additionalData: additional)
            return nil
        }
        // 如果 PolicyModel 为 CCM 点位，则暂时将文件类型修改成 doc 以减少 enforce 接口压力
        policyModel.entity.temporaryIntegrateToDoc()
        if let cacheResponse = strategyCacheAuth(policyModel: policyModel) {
            if !cacheResponse.isCredible {
                DispatchQueue.main.async {
                    self.strategyEngineCaller.checkAuth(policyModels: [policyModel], callTrigger: .noCacheRetry, complete: nil)
                }
            }
            SCLogger.info("security policy: get cache response succeeded", additionalData: additional)
            return cacheResponse
        }
        DispatchQueue.main.async {
            self.strategyEngineCaller.checkAuth(policyModels: [policyModel], callTrigger: .noCacheRetry, complete: nil)
        }
        return strategyEngineCaller.downgradeDecision(policyModel: policyModel)
    }
    
    func checkAsyncAuth(policyModel: PolicyModel, config: ValidateConfig, complete: @escaping (ValidateResultProtocol?) -> Void) {
        var additional = ["cid": config.cid]
        additional["pointKey"] = policyModel.pointKey.rawValue
        additional["entityOperate"] = policyModel.entity.entityOperate.rawValue
        guard SecurityPolicyConstKey.enableFGorIsScene(resolver: self.userResolver, isScene: policyModel.isScene) else {
            SPLogger.info("security policy: fg enable file strategy is close", additionalData: additional)
            complete(nil)
            return
        }
        setControlledByFgSubmodulesIfNeed()
        guard let policyModel = associatePolicyModel(policyModel: policyModel) else {
            SCLogger.info("security policy: no associate static model", additionalData: additional)
            complete(nil)
            return
        }
        // 如果 PolicyModel 为 CCM 点位，则暂时将文件类型修改成 doc 以减少 enforce 接口压力
        policyModel.entity.temporaryIntegrateToDoc()
        if let cacheResponse = strategyCacheAuth(policyModel: policyModel),
           cacheResponse.isCredible {
            SCLogger.info("security policy: get cache response succeeded", additionalData: additional)
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
                    SCLogger.info("security policy: async failed, get cache response succeeded", additionalData: additional)
                    complete(cacheResponse)
                    return
                }
                SCLogger.info("security policy: get async response succeeded", additionalData: additional)
                complete(validateResponse)
                return
            }
            let downgradeResp = self.strategyEngineCaller.downgradeDecision(policyModel: policyModel)
            complete(downgradeResp)
        }
    }

    func checkAuth(policyModels: [PolicyModel],
                   config: ValidateConfig?,
                   complete: @escaping(([String: ValidateResult]) -> Void)) {
        setControlledByFgSubmodulesIfNeed()
        // 如果 PolicyModel 为 CCM 点位，则暂时将文件类型修改成 doc 以减少 enforce 接口压力
        let normalizePolicyModels = temporaryIntegrateToDoc(policyModels)
        var validateResults: [String: ValidateResult] = [:]
        let strategyModels = normalizePolicyModels.compactMap { policyModel -> PolicyModel? in
            if let cacheResponse = strategyCacheAuth(policyModel: policyModel),
               checkRespIsCredible(policyModel: policyModel, resp: cacheResponse.validateResponse) {
                let cacheResult = wrapCacheResponse(policyModel: policyModel, cacheReponse: cacheResponse.validateResponse, config: config)
                validateResults[policyModel.taskID] = cacheResult
                if cacheResult.extra.isCredible { return nil }
            }
            return policyModel
        }
        strategyEngineCaller.checkAuth(policyModels: strategyModels,
                                       callTrigger: .businessCheck) { [weak self] validateResponses in
            guard let self else { return }
            validateResponses.forEach { validateResponsePair in
                let taskID = validateResponsePair.key
                let enginResponse = validateResponsePair.value
                guard let policyModel = strategyModels.first(where: { $0.taskID == taskID }) else {
                    SPLogger.info("security policy: did not get response of policyModel: \(taskID)")
                    return
                }
                if !self.checkRespIsCredible(policyModel: policyModel, resp: enginResponse),
                   let cacheResponse = self.strategyCacheAuth(policyModel: policyModel) {
                    let cacheResult = self.wrapCacheResponse(policyModel: policyModel, cacheReponse: cacheResponse.validateResponse, config: config)
                    validateResults[taskID] = cacheResult
                    return
                }
                let engineResult = self.wrapEngineResponse(policyModel: policyModel, engineResponse: enginResponse, config: config)
                validateResults[taskID] = engineResult
            }
            complete(validateResults)
        }
    }

    func checkRespIsCredible(policyModel: PolicyModel, resp: ValidateResponse) -> Bool {
        let method = resp.type.validateResultMethod
        let isNeedDelete = sceneCache.isNeedDelete(policyModel: policyModel)
        let isNotCredible = (isNeedDelete ||
                             method == .downgrade ||
                             method == .fallback)
        return !isNotCredible
    }

    private func setControlledByFgSubmodulesIfNeed() {
        DispatchQueue.runOnMainQueue {
            if !self.isInitial, SecurityPolicyConstKey.enableFileProtectionClient(resolver: self.userResolver) {
                self.isInitial = true
                self.setControledByFgSubmodules()
            }
        }
    }

    private func getClientFallBackResult(policyModel: PolicyModel) -> ValidateResult {
        guard policyModel.pointKey == .imFileRead,
              let imFileEntity = policyModel.entity as? IMFileEntity,
              let senderTenantID = imFileEntity.senderTenantId,
              !SecurityPolicyConstKey.enableFileProtectionClientFG(resolver: self.userResolver) else {
            let result = settings?.fileStrategyFallbackResult == true ? ValidateResultType.allow : ValidateResultType.deny
            let extra = ValidateExtraInfo(resultSource: .unknown, errorReason: nil, resultMethod: .fallback, isCredible: false, logInfos: [])
            return ValidateResult(userResolver: userResolver, result: result, extra: extra)
        }
        let result = (sceneFallBackResultManager[senderTenantID]) ? ValidateResultType.allow : ValidateResultType.deny
        let extra = ValidateExtraInfo(resultSource: .unknown, errorReason: nil, resultMethod: .fallback, isCredible: false, logInfos: [])
        return ValidateResult(userResolver: userResolver, result: result, extra: extra)
    }

    private func wrapEngineResponse(policyModel: PolicyModel,
                                    engineResponse: ValidateResponse,
                                    config: ValidateConfig?) -> ValidateResult {
        // 客户端兜底
        if engineResponse.errorMsg != nil {
            let defaultResult = getClientFallBackResult(policyModel: policyModel)
            let defaultAction = Action(name: "UNIVERSAL_FALLBACK_COMMON")
            let correctValidateResp = ValidateResponse(effect: defaultResult.result == .deny ? .deny : .permit,
                                                       actions: [defaultAction],
                                                       uuid: engineResponse.uuid,
                                                       type: engineResponse.type)
            interceptDialogFilterResult(policyModel: policyModel, config: config, result: correctValidateResp)
            return defaultResult
        }
        // 降级 or 普通点位
        interceptDialogFilterResult(policyModel: policyModel, config: config, result: engineResponse)
        let result = engineResponse.allow ? ValidateResultType.allow : ValidateResultType.deny
        let source: ValidateSource = engineResponse.actions.first?.validateResource ?? .unknown
        let isCredible = checkRespIsCredible(policyModel: policyModel, resp: engineResponse)
        let extra = ValidateExtraInfo(resultSource: source,
                                      errorReason: nil,
                                      resultMethod: engineResponse.type.validateResultMethod,
                                      isCredible: isCredible,
        logInfos: [])
        return ValidateResult(userResolver: userResolver, result: result, extra: extra)
    }

    private func wrapCacheResponse(policyModel: PolicyModel,
                                   cacheReponse: ValidateResponse,
                                   config: ValidateConfig?) -> ValidateResult {
        interceptDialogFilterResult(policyModel: policyModel, config: config, result: cacheReponse)
        let result = cacheReponse.allow ? ValidateResultType.allow : ValidateResultType.deny
        let isCredible = checkRespIsCredible(policyModel: policyModel, resp: cacheReponse)
        let extra = ValidateExtraInfo(resultSource: .fileStrategy,
                                      errorReason: nil,
                                      resultMethod: .cache,
                                      isCredible: isCredible,
                                      logInfos: [])
        return ValidateResult(userResolver: userResolver, result: result, extra: extra)
    }

    private func updateResultCache(updateTrigger: SecurityPolicyUpdateTrigger) {
        SPLogger.info("security policy: security_policy_manager: get update cache signal from trigger:\(updateTrigger)")
        let isFullUpdate: Bool
        switch updateTrigger {
        case .networkChange:
            delayClearCacheManager.updatePolicyTimeStamp()
            isFullUpdate = false
        case .becomeActive, .constructor:
            delayClearCacheManager.updatePolicyTimeStamp()
            isFullUpdate = true
        case .strategyEngine:
            isFullUpdate = true
        }
        cacheUpdateDebouncer.call(trigger: updateTrigger, isFullUpdate: isFullUpdate)
    }

    private func strategyCacheAuth(policyModel: PolicyModel) -> SceneLocalCache? {
        var result: SceneLocalCache?
        if (settings?.disableFileStrategyShareCache).isTrue,
           policyModel.pointKey == .imFileRead {
            result = nil
        } else if policyModel.isScene {
            result = sceneCache.read(policyModel: policyModel)
        } else if let response = staticCache[policyModel.taskID] {
            // TODO: Wangxijing 最小化改动，临时创建一个SceneLocalCache,在安全SDK优化中将静态点位缓存收敛到SecurityPolicyCacheProtocol中
            result = SceneLocalCache(taskID: policyModel.taskID, validateResponse: response, needDelete: false)
        }
        // map中存储的值也可能为nil
        if let delayTime = delayClearCacheManager.ipPolicyModelMap[policyModel.taskID] as? TimeInterval {
            let duration = DelayClearCacheManager.ntpTime - delayTime
            SecurityPolicyEventTrack.scsSecurityPolicyHitDelayClearCache(policyModel: policyModel,
                                                                         duration: duration)
        }
        return result
    }

    private func cacheResult(newValue: [String: ValidateResponse]) {
        var sceneResponse = newValue
        var staticResponse: [String: ValidateResponse] = [:]
        newValue.forEach { validatePair in
            guard SecurityPolicyConstKey.scenePointKey.first(where: { pointKey in validatePair.key.contains(pointKey.rawValue) }) != nil else {
                sceneResponse.removeValue(forKey: validatePair.key)
                staticResponse[validatePair.key] = validatePair.value
                return
            }
        }
        staticCache.merge(staticResponse)
        sceneCache.merge(sceneResponse, expirationTime: nil)
    }

    func isEnableFastPass(policyModel: PolicyModel) -> Bool {
        return strategyEngineCaller.isEnableFastPass(policyModel: policyModel)
    }

    @objc
    func onDidBecomeActive() {
        self.updateResultCache(updateTrigger: .becomeActive)
        let engine = try? userResolver.resolve(assert: PolicyEngineService.self)
        engine?.postEvent(event: .becomeActive)
    }

    func clearCache() {
        staticCache.clear()
        sceneCache.clear()
        Logger.info("security policy:security_policy_manager: cache clear")
    }

    func clearSceneAuthCache() {
        sceneCache.clear()
    }

    func markSceneCacheDeletable() {
        sceneCache.markInvalid()
    }

    func getStaticCache() -> [String: ValidateResponse] {
        staticCache.getAllCache()
    }

    func getSceneCache() -> [SceneLocalCache] {
        return sceneCache.getAllCache()
    }

    private func temporaryIntegrateToDoc(_ policyModels: [PolicyModel]) -> [PolicyModel] {
        return policyModels.map { policyModel in
            policyModel.entity.temporaryIntegrateToDoc()
            return policyModel
        }
    }

    func getRetryList() -> String {
        let strList = retryManager.retryList.map { retryPair in
            let entity = retryPair.key.entity
            var prefix = entity.entityOperate.rawValue + "+"
            prefix += (entity.entityType.rawValue)

            let surfix = retryPair.value
            return prefix + "\n" + "\(surfix)"
        }
        return strList.reduce("", { $0 + "\n\n" + $1 })
    }

    func getIPList() -> String {
        let strList = delayClearCacheManager.ipPolicyModelMap.map { return $0.key + "\n" + "\($0.value ?? 0)" }
        return strList.reduce("", { $0 + "\n\n" + $1 })
    }

    func getSceneCacheSize() -> Int {
        sceneCache.getSceneCacheSize()
    }

    func getSceneCacheHeadAndTail() -> String? {
        sceneCache.getSceneCacheHeadAndTail()
    }
}

extension PolicyAuthManager {
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

// 策略引擎观察
final class StrategyObserver: LarkPolicyEngine.Observer {
    var updateHandler: (() -> Void)?
    func notify(event: LarkPolicyEngine.Event) {
        switch event {
        case .decisionContextChanged:
            updateHandler?()
        default:
            return
        }
    }
}
