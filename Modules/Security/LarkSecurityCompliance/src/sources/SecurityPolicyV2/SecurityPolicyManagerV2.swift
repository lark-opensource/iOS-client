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

extension SecurityPolicyV2 {
    final class SecurityPolicyManager: UserResolverWrapper {
        let policyAuth: PolicyAuthManager
        private let securityAudit: SecurityAuditCaller
        private let checkers: [SecurityPolicyChecker]
        private let resultAggregator: ResultAggregator
        private let settings: SCSettingService
        private var defaultResult: ValidateResult {
            ValidateResult(userResolver: self.userResolver,
                           result: .allow,
                           extra: ValidateExtraInfo(resultSource: .unknown,
                                                    errorReason: nil,
                                                    logInfos: [])
            )
        }
        private let preProcess: SecurityPolicyPreProcess

        let userResolver: UserResolver

        init(resolver: UserResolver) throws {
            self.userResolver = resolver
            resultAggregator = try ResultAggregator(resolver: resolver)
            policyAuth = try PolicyAuthManager(userResolver: resolver)
            preProcess = try SecurityPolicyPreProcess(userResolver: resolver)
            securityAudit = SecurityAuditCaller(userResolver: userResolver)
            settings = try userResolver.resolve(assert: SCSettingService.self)
            let service = try userResolver.resolve(assert: SCFGService.self)
            let enableDlp = service.realtimeValue(SCFGKey.enableDlp)
            if enableDlp {
                let dlpManager = try userResolver.resolve(assert: DLPValidateService.self)
                checkers = [policyAuth, dlpManager]
            } else {
                checkers = [policyAuth]
            }
        }

        func checkSecurityPolicy(policyModel: PolicyModel,
                                 authEntity: AuthEntity?,
                                 config: ValidateConfig = ValidateConfig(),
                                 complete: @escaping (ValidateResult) -> Void) {
            SecurityPolicy.logger.info("security policy async check begins", additionalData: config, policyModel)

            let aggregatePolicyAndAuthSdk = { (result: ValidateResult) in
                guard let authEntity else {
                    complete(result)
                    return
                }
                complete(self.securityAudit.checkAuth(params: authEntity))
            }

            guard preProcess.check(policyModel: policyModel, config: config) else {
                SecurityPolicy.logger.info("security policy precheck fail",
                                           additionalData: config, policyModel, ["result": "\(defaultResult)"])
                aggregatePolicyAndAuthSdk(defaultResult)
                return
            }

            @SafeWrapper var results: [ValidateResultProtocol] = []
            let group = DispatchGroup()
            checkers.forEach { checker in
                group.enter()
                SecurityPolicy.logger.info("security policy \(checker.identifier) begin check",
                                           additionalData: config, policyModel)
                checker.checkAsyncAuth(policyModel: policyModel, config: config) { result in
                    defer {
                        group.leave()
                    }
                    guard let result else {
                        SecurityPolicy.logger.info("security policy \(checker.identifier) check finished, result is nil",
                                                   additionalData: config, policyModel)
                        return
                    }
                    SecurityPolicy.logger.info("security policy \(checker.identifier) check finished",
                                               additionalData: config, policyModel, ["result": "\(result)"])
                    results.append(result)
                }
            }

            var completeBlock: (([ValidateResultProtocol]) -> Void)? = { [weak self] results -> Void in
                guard let self else { return }
                // 结果聚合
                let policyResult = self.resultAggregator.merge(policyModel: policyModel, results: results)
                policyResult.handleIfNeed(config: config)
                SecurityPolicyEventTrack.larkSCSFileStrategyResult(resultGroups: [policyModel: policyResult],
                                                                   function: .asyncValidate,
                                                                   additional: config.logData)
                switch policyResult.result {
                case .deny:
                    complete(policyResult)
                default:
                    aggregatePolicyAndAuthSdk(policyResult)
                }
            }

            group.notify(queue: DispatchQueue.main) {
                completeBlock?(results)
                completeBlock = nil
            }

            let timeout = DispatchTime.now() + .seconds(60)
            DispatchQueue.main.asyncAfter(deadline: timeout) {
                if group.wait(timeout: .now()) == .timedOut {
                    SecurityPolicy.logger.info("security policy async check timeout",
                                               additionalData: config, policyModel)
                    completeBlock?(results)
                    completeBlock = nil
                }
            }
        }

        func checkSecurityPolicy(policyModel: PolicyModel,
                                 authEntity: AuthEntity? = nil,
                                 config: ValidateConfig) -> ValidateResult {
            SecurityPolicy.logger.info("security policy cache check begins",
                                       additionalData: config, policyModel)
            let aggregatePolicyAndAuthSdk = { (result: ValidateResult) -> ValidateResult in
                guard let authEntity else {
                    return result
                }
                return self.securityAudit.checkAuth(params: authEntity)
            }
            guard preProcess.check(policyModel: policyModel, config: config) else {
                SecurityPolicy.logger.info("security policy precheck fail",
                                           additionalData: config, policyModel, ["result": "\(defaultResult)"])
                return aggregatePolicyAndAuthSdk(defaultResult)
            }
            // 校验器逐个校验，获取结果
            let results: [ValidateResultProtocol] = checkers.compactMap({ checker in
                guard let result = checker.checkCacheAuth(policyModel: policyModel, config: config) else {
                    SecurityPolicy.logger.info("security policy: \(checker.identifier) check finished, reult is nil",
                                               additionalData: config, policyModel)
                    return nil
                }
                SecurityPolicy.logger.info("security policy: \(checker.identifier) check",
                                           additionalData: config, policyModel, ["result": "\(result)"])
                return result
            })
            // 结果聚合
            let policyResult = resultAggregator.merge(policyModel: policyModel, results: results)
            policyResult.handleIfNeed(config: config)
            SecurityPolicyEventTrack.larkSCSFileStrategyResult(resultGroups: [policyModel: policyResult],
                                                               function: .cacheValidate,
                                                               additional: config.logData)
            switch policyResult.result {
            case .deny:
                return policyResult
            default:
                return aggregatePolicyAndAuthSdk(policyResult)
            }
        }

        func checkSecurityPolicy(policyModels: [PolicyModel],
                                 config: ValidateConfig,
                                 complete: @escaping ([String: ValidateResult]) -> Void) {
            let assertList = policyModels.filter { !$0.pointKey.isScene }
            assert(assertList.isEmpty, "file operate batch api receive static policy model")

            guard let policyModel = policyModels.first,
                  preProcess.check(policyModel: policyModel, config: config) else {
                SecurityPolicy.logger.info("security policy precheck fail or policy model is nil",
                                           additionalData: config, policyModels.first, ["result": "\(defaultResult)"])
                let resultMap = policyModels.reduce(into: [String: ValidateResult](), { (result, element) in
                    result[element.taskID] = defaultResult
                })
                complete(resultMap)
                return
            }

            policyAuth.checkAuth(policyModels: policyModels, config: config) { [weak self] validateMap in
                guard let self else { return }
                var resultLogGroup = [PolicyModel: ValidateResult]()
                policyModels.forEach {
                    let taskID = $0.taskID
                    if let response = validateMap[taskID] {
                        let result = self.resultAggregator.merge(policyModel: $0, results: [response])
                        result.handleIfNeed(config: config)
                        resultLogGroup.updateValue(result, forKey: $0)
                    }
                }
                SecurityPolicyEventTrack.larkSCSFileStrategyResult(resultGroups: resultLogGroup,
                                                                   function: .batchAsyncValidate,
                                                                   additional: config.logData)
                SecurityPolicyEventTrack.larkSCSSecuritySDKResult(resultGroups: resultLogGroup,
                                                                  function: .batchAsyncValidate,
                                                                  additional: config.logData)
                let resultGroup = resultLogGroup.reduce(into: [String: ValidateResult](), { (result, element) in
                    result[element.key.taskID] = element.value
                })
                complete(resultGroup)
            }
        }

        func showInterceptDialog(policyModel: PolicyModel) {
            let decision = try? userResolver.resolve(assert: NoPermissionRustActionDecision.self)
            let actionModel = policyModel.entity.rustActionModel
            // TODO：测下IM预览拦截
            decision?.handleAction(actionModel)
            SecurityPolicyEventTrack.larkSCSHandleAction(actionSource: .sdkInternal,
                                                         actionName: actionModel.model?.name ?? "NO_ACTION")
        }

        func isEnableFastPass(policyModel: PolicyModel) -> Bool {
            if settings.bool(.disableFileOperate) || settings.bool(.disableFileStrategy) { return true }
            return policyAuth.isEnableFastPass(policyModel: policyModel)
        }
    }
}

fileprivate extension ValidateResult {
    func handleIfNeed(config: ValidateConfig) {
        if !config.ignoreSecurityOperate {
            handleAction()
        } else {
            SecurityPolicy.logger.info("security policy: operate ignore", additionalData: config)
        }

        if !config.ignoreReport {
            report()
        } else {
            SecurityPolicy.logger.info("security policy: report ignore", additionalData: config)
        }
    }
}
