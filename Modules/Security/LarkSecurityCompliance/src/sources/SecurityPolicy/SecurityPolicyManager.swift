//
//  SecurityPolicyManager.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/12/13.
//

import Foundation
import ServerPB
import LarkContainer
import LarkPolicyEngine
import LarkAccountInterface
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import LarkFeatureGating
import Dispatch

final class SecurityPolicyManager: UserResolverWrapper {
    @ScopedProvider private var settings: Settings?

    private let securityAudit: SecurityAuditCaller
    private let policyAuth: PolicyAuthManager
    private let checkers: [SecurityPolicyCheckerProtocol]
    private let resultAggregator: SecurityPolicy.ResultAggregator
    private var defaultResult: ValidateResult {
        ValidateResult(userResolver: self.userResolver, result: .allow, extra: ValidateExtraInfo(resultSource: .unknown, errorReason: nil, logInfos: [])
        )
    }

    let userResolver: UserResolver

    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        resultAggregator = try SecurityPolicy.ResultAggregator(resolver: resolver)
        policyAuth = try PolicyAuthManager(userResolver: resolver)
        securityAudit = SecurityAuditCaller(userResolver: userResolver)
        let dlpManager = try userResolver.resolve(assert: DLPManagerProtocol.self)
        let service = try userResolver.resolve(assert: SCFGService.self)
        let enableDlp = service.realtimeValue(SCFGKey.enableDlp)
        if enableDlp {
            checkers = [policyAuth, dlpManager]
        } else {
            checkers = [policyAuth]
        }
    }

    func checkSecurityPolicy(policyModel: PolicyModel,
                                    authEntity: AuthEntity?,
                                    config: ValidateConfig = ValidateConfig(),
                                    complete: @escaping (ValidateResult) -> Void) {
        let additional: [String: String] = [
            "cid": UUID().uuidString,
            "check_type": "async",
            "operate": "\(policyModel.entity.entityOperate)"
        ]
        SPLogger.info("security policy async check begins", additionalData: additional)
        let securityAuditBlock = { (strategyResult: ValidateResult) -> Void in
            guard let authEntity else {
                complete(strategyResult)
                return
            }
            let securityAuthResult = self.securityAudit.checkAuth(params: authEntity)
            complete(securityAuthResult)
        }

        if (settings?.disableFileOperate).isTrue {
            SPLogger.info("security policy: settings disable file operate is open", additionalData: additional)
            complete(defaultResult)
            return
        }

        if (settings?.disableFileStrategy).isTrue {
            SPLogger.info("security policy: settings disable file strategy is open", additionalData: additional)
            securityAuditBlock(defaultResult)
            return
        }
        if policyModel.pointKey == .imFileRead,
           (settings?.disableFileStrategyShare).isTrue {
            SPLogger.info("security policy: settings disable file strategy share is open", additionalData: additional)
            securityAuditBlock(defaultResult)
            return
        }
        // security policy temporarily exempt VC until VC access
        if let vcEntity = policyModel.entity as? VCFileEntity,
           vcEntity.fileBizDomain == .vc {
            securityAuditBlock(defaultResult)
            return
        }
        @SafeWrapper var results: [ValidateResultProtocol] = []
        let group = DispatchGroup()
        checkers.forEach { checker in
            group.enter()
            SPLogger.info("security policy \(checker.identifier) begin check", additionalData: additional)
            checker.checkAsyncAuth(policyModel: policyModel, config: config) { result in
                defer {
                    group.leave()
                }
                guard let result = result else {
                    SPLogger.info("security policy \(checker.identifier) check finished, result is nil", additionalData: additional)
                    return
                }
                var tempAdditional = additional
                tempAdditional["result"] = "\(result)"
                SPLogger.info("security policy \(checker.identifier) check finished", additionalData: tempAdditional)
                results.append(result)
            }
        }
        
        var completeBlock: (([ValidateResultProtocol]) -> Void)? = { [weak self] results -> Void in
            guard let self else { return }
            // 结果聚合
            let policyResult = self.resultAggregator.merge(policyModel: policyModel, results: results) { resp in
                self.interceptDialogFilterResult(policyModel: policyModel, config: config, result: resp)
            }
            self.reportIfNeed(policyResult, config: config)
            SecurityPolicyEventTrack.larkSCSFileStrategyResult(resultGroups: [policyModel: policyResult], function: .asyncValidate, additional: additional)
            switch policyResult.result {
            case .deny:
                complete(policyResult)
                return
            default:
                securityAuditBlock(policyResult)
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completeBlock?(results)
            completeBlock = nil
        }
        
        let timeout = DispatchTime.now() + .seconds(60)
        DispatchQueue.main.asyncAfter(deadline: timeout) {
            if group.wait(timeout: .now()) == .timedOut {
                SPLogger.info("security policy async check timeout", additionalData: additional)
                completeBlock?(results)
                completeBlock = nil
            }
        }
    }

    func checkSecurityPolicy(policyModel: PolicyModel,
                             authEntity: AuthEntity? = nil,
                             config: ValidateConfig = ValidateConfig()) -> ValidateResult {
        let additional: [String: String] = [
            "cid": config.cid,
            "check_type": "cache",
            "operate": "\(policyModel.entity.entityOperate)"
        ]
        SPLogger.info("security policy cache check begins", additionalData: additional)
        if (settings?.disableFileOperate).isTrue {
            SPLogger.info("security policy: settings disable file operate is open", additionalData: additional)
            return defaultResult
        }
        if (settings?.disableFileStrategy).isTrue {
            SPLogger.info("security policy: settings disable file strategy is open", additionalData: additional)
            guard let authEntity else { return defaultResult }
            return securityAudit.checkAuth(params: authEntity)
        }
        if policyModel.pointKey == .imFileRead,
           (settings?.disableFileStrategyShare).isTrue {
            SPLogger.info("security policy: settings disable file strategy share is open", additionalData: additional)
            guard let authEntity else { return defaultResult }
            return securityAudit.checkAuth(params: authEntity)
        }
        // security policy temporarily exempt VC until VC access
        if let vcEntity = policyModel.entity as? VCFileEntity,
           vcEntity.fileBizDomain == .vc {
            guard let authEntity else { return defaultResult }
            return securityAudit.checkAuth(params: authEntity)
        }
        // 校验器逐个校验，获取结果
        let results: [ValidateResultProtocol] = checkers.compactMap({ checker in
            guard let result = checker.checkCacheAuth(policyModel: policyModel, config: config) else {
                SPLogger.info("security policy: \(checker.identifier) check finished, reult is nil", additionalData: additional)
                return nil
            }
            var tempAdditional = additional
            tempAdditional["result"] = "\(result)"
            SPLogger.info("security policy: \(checker.identifier) check", additionalData: tempAdditional)
            return result
        })
        // 结果聚合
        let policyResult = resultAggregator.merge(policyModel: policyModel, results: results) { resp in
            interceptDialogFilterResult(policyModel: policyModel, config: config, result: resp)
        }
        reportIfNeed(policyResult, config: config)
        SecurityPolicyEventTrack.larkSCSFileStrategyResult(resultGroups: [policyModel: policyResult],
                                                           function: .cacheValidate,
                                                           additional: additional)
        switch policyResult.result {
        case .deny:
            return policyResult
        default:
            guard let authEntity else { return policyResult }
            return securityAudit.checkAuth(params: authEntity)
        }
    }

    func checkSecurityPolicy(policyModels: [PolicyModel],
                              config: ValidateConfig = ValidateConfig(),
                             complete: @escaping ([String: ValidateResult]) -> Void) {
        let additional: [String: String] = [
            "cid": config.cid,
            "check_type": "batch"
        ]
        if SecurityPolicyConstKey.disableFileOperateOrStrategy {
            SPLogger.info("security policy: settings disable file operate or strategy is open", additionalData: additional)
            var resultMap = [String: ValidateResult]()
            policyModels.forEach {
                resultMap.updateValue(defaultResult, forKey: $0.taskID)
            }
            complete(resultMap)
            return
        }
        if policyModels.first?.pointKey == .imFileRead,
           (settings?.disableFileStrategyShare).isTrue {
            SPLogger.info("security policy: settings disable file strategy share is open", additionalData: additional)
            var tempResults: [String: ValidateResult] = [:]
            policyModels.forEach {
                tempResults[$0.taskID] = defaultResult
            }
            complete(tempResults)
            return
        }
        let assertList = policyModels.filter { !$0.isScene }
        assert(assertList.isEmpty, "file operate batch api receive static policy model")
        policyAuth.checkAuth(policyModels: policyModels, config: config) { validateMap in
            var resultGroup = [PolicyModel: ValidateResult]()
            policyModels.forEach {
                let taskID = $0.taskID
                if let result = validateMap[taskID] {
                    resultGroup.updateValue(result, forKey: $0)
                }
            }
            SecurityPolicyEventTrack.larkSCSFileStrategyResult(resultGroups: resultGroup,
                                                               function: .batchAsyncValidate,
                                                               additional: additional)
            complete(validateMap)
        }
    }
    
    private func reportIfNeed(_ result: ValidateResult, config: ValidateConfig) {
        guard !config.ignoreReport else {
            SPLogger.info("security policy: report ignore", additionalData: config.description)
            return
        }
        let service = try? userResolver.resolve(assert: LogReportService.self)
        service?.report(result.extra.logInfos)
    }
    
    func interceptDialogFilterResult(policyModel: PolicyModel,
                                     config: ValidateConfig,
                                     result: ValidateResultProtocol) {
        if config.ignoreSecurityOperate {
            SPLogger.info("\(policyModel.pointKey) ignore security operate", additionalData: config.description)
            return
        }
        guard !result.isAllow else {
            SPLogger.info("result is allow, stop security operation", additionalData: config.description)
            return
        }
        if let action = result.actions.first,
           let decision = try? userResolver.resolve(assert: NoPermissionRustActionDecision.self) {
            let actionModel = action.rustActionModel
            DispatchQueue.runOnMainQueue {
                decision.handleAction(actionModel)
                var additional = config.description
                additional["action"] = action.name
                SPLogger.info("security policy: handle action", additionalData: additional)
            }
            SecurityPolicyEventTrack.larkSCSHandleAction(actionSource: .sdkInternal,
                                                         actionName: actionModel.model?.name ?? "NO_ACTION")
        } else {
            SPLogger.error("security policy: wrong action, cant process security operation", additionalData: config.description)
        }
    }

    func showInterceptDialog(policyModel: PolicyModel) {
        let decision = try? userResolver.resolve(assert: NoPermissionRustActionDecision.self)
        let actionModel = policyModel.entity.rustActionModel
        decision?.handleAction(policyModel.entity.rustActionModel)
        SecurityPolicyEventTrack.larkSCSHandleAction(actionSource: .sdkInternal,
                                                     actionName: actionModel.model?.name ?? "NO_ACTION")
    }

    func isEnableFastPass(policyModel: PolicyModel) -> Bool {
        if SecurityPolicyConstKey.disableFileOperateOrStrategy { return true }
        return policyAuth.isEnableFastPass(policyModel: policyModel)
    }

    func clearFileStrategyCache() {
        policyAuth.clearCache()
    }

    func getStaticCache() -> [String: ValidateResponse] {
        policyAuth.getStaticCache()
    }

    func getSceneCache() -> [SceneLocalCache] {
        policyAuth.getSceneCache()
    }

    func getRetryList() -> String {
        policyAuth.getRetryList()
    }

    func getIPList() -> String {
        policyAuth.getIPList()
    }

    func clearSceneAuthCache() {
        policyAuth.clearSceneAuthCache()
    }

    func markSceneCacheDeletable() {
        policyAuth.markSceneCacheDeletable()
    }

    func getSceneCacheSize() -> Int {
        policyAuth.getSceneCacheSize()
    }

    func getSceneCacheHeadAndTail() -> String? {
        policyAuth.getSceneCacheHeadAndTail()
    }
}
