//
//  SecurityPolicyValidator.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/18.
//

import Foundation
import SpaceInterface
import SKFoundation
import LarkSecurityComplianceInterface

class SecurityPolicyValidator: PermissionValidator {

    var name: String { "SecurityPolicyValidator" }

    private let userID: Int64
    private let tenantID: Int64
    private let service: SecurityPolicyService
    // 对应 FG: UserScopeNoChangeFG.GQP.legacyFileProtectCloudDocDownload
    private let legacyFileProtectConvertionEnable: Bool

    init(userID: Int64,
         tenantID: Int64,
         service: SecurityPolicyService,
         legacyFileProtectConvertionEnable: Bool) {
        self.userID = userID
        self.tenantID = tenantID
        self.service = service
        self.legacyFileProtectConvertionEnable = legacyFileProtectConvertionEnable
    }

    func shouldInvoke(rules: PermissionExemptRules) -> Bool {
        rules.shouldCheckFileStrategy || rules.shouldCheckDLP
    }

    func validate(request: PermissionRequest) -> PermissionValidatorResponse {
        Logger.verbose("SecurityPolicy - start validate request", traceID: request.traceID)
        guard let serviceRequest = convert(request: request) else {
            Logger.info("SecurityPolicy - skipped, failed to convert request to policy service request",
                        traceID: request.traceID)
            // 返回 nil 表示不需要进行 CAC 检查
            return .pass
        }
        let result = service.cacheValidate(policyModel: serviceRequest.policyModel,
                                           authEntity: serviceRequest.authEntity,
                                           config: serviceRequest.config)
        return convert(result: result, policyModel: serviceRequest.policyModel, request: request)
    }

    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionValidatorResponse) -> Void) {
        guard let serviceRequest = convert(request: request) else {
            // 返回 nil 表示不需要进行 CAC 检查
            completion(.pass)
            return
        }
        service.asyncValidate(policyModel: serviceRequest.policyModel,
                              authEntity: serviceRequest.authEntity,
                              config: serviceRequest.config) { [weak self] result in
            guard let self else {
                completion(.forbidden(denyType: .blockByFileStrategy) { _, _ in })
                return
            }
            let response = self.convert(result: result, policyModel: serviceRequest.policyModel, request: request)
            completion(response)
        }
    }
}

extension SecurityPolicyValidator {

    private struct SecurityPolicyRequest {
        let policyModel: PolicyModel
        let authEntity: AuthEntity
        let config: ValidateConfig
    }

    private func convert(request: PermissionRequest) -> SecurityPolicyRequest? {
        if request.bizDomain.fileBizDomain == .unknown {
            // domain 为 unknown 的直接放行
            // 目前小程序场景会转换为 unknown
            Logger.warning("SecurityPolicy - unknown fileBizDomain found, skipping security policy check",
                           traceID: request.traceID)
            return nil
        }
        guard let policyModel = SecurityPolicyConverter.convertPolicyModel(request: request, operatorUserID: userID, operatorTenantID: tenantID) else {
            return nil
        }
        let authEntity = SecurityPolicyConverter.convertAuthEntity(request: request,
                                                                   entityOperation: policyModel.entity.entityOperate,
                                                                   needKAConvertion: legacyFileProtectConvertionEnable)
        let config = ValidateConfig(ignoreSecurityOperate: true,
                                    ignoreReport: true,
                                    cid: request.traceID)
        return SecurityPolicyRequest(policyModel: policyModel, authEntity: authEntity, config: config)
    }

    private func convert(result: ValidateResult,
                         policyModel: PolicyModel,
                         request: PermissionRequest) -> PermissionValidatorResponse {
        Logger.verbose("SecurityPolicy - processing ValidateResult",
                       extraInfo: [
                        "resultType": result.result,
                        "resultSource": result.extra.resultSource
                       ],
                       traceID: request.traceID)
        switch result.extra.resultSource {
        case .fileStrategy:
            if result.result == .allow {
                Logger.info("SecurityPolicy - return allow with source: fileStrategy", traceID: request.traceID)
                return .allow {
                    Logger.verbose("SecurityPolicy - default behavior called for fileStrategy allow",
                                traceID: request.traceID)
                    result.report()
                    result.handleAction()
                }
            } else {
                Logger.warning("SecurityPolicy - return forbidden with source: fileStrategy",
                               extraInfo: ["resultType": result.result],
                               traceID: request.traceID)
                return .forbidden(denyType: .blockByFileStrategy) { _, _ in
                    Logger.info("SecurityPolicy - default behavior called for fileStrategy forbidden",
                                traceID: request.traceID)
                    result.report()
                    result.handleAction()
                }
            }
        case .dlpDetecting, .dlpSensitive, .ttBlock:
            if result.result == .allow {
                Logger.info("SecurityPolicy - return allow with source: \(result.extra.resultSource)",
                            traceID: request.traceID)
                return .allow {
                    Logger.verbose("SecurityPolicy - default behavior called for \(result.extra.resultSource) allow",
                                   traceID: request.traceID)
                    result.report()
                    result.handleAction()
                }
            } else {
                let isSameTenant = {
                    // 取不到默认当同租户
                    guard let entityTenantID = request.extraInfo.entityTenantID else { return true }
                    return entityTenantID == String(tenantID)
                }()
                Logger.warning("SecurityPolicy - return forbidden with source: \(result.extra.resultSource)",
                               extraInfo: [
                                "resultType": result.result,
                                "isSameTenant": isSameTenant
                               ],
                               traceID: request.traceID)
                return SecurityPolicyConverter.convertDLPResponse(result: result,
                                                                  request: request,
                                                                  maxCostTime: TimeInterval(service.dlpMaxDetectingTime()),
                                                                  isSameTenant: isSameTenant)
            }
        case .securityAudit:
            if Self.checkIsAllow(validateResultType: result.result) {
                Logger.info("SecurityPolicy - return allow with source: securityAudit",
                            extraInfo: ["resultType": result.result],
                            traceID: request.traceID)
                return .allow {
                    Logger.verbose("SecurityPolicy - default behavior called for securityAudit allow",
                                traceID: request.traceID)
                    result.report()
                    result.handleAction()
                }
            } else {
                Logger.warning("SecurityPolicy - return forbidden with source: securityAudit",
                               extraInfo: ["resultType": result.result],
                               traceID: request.traceID)
                let message = SecurityAuditConverter.toastMessage(operation: request.operation)
                return .forbidden(denyType: .blockBySecurityAudit,
                                  defaultUIBehaviorType: .error(text: message, allowOverrideMessage: false) {
                    Logger.verbose("SecurityPolicy - default behavior called for securityAudit forbidden",
                                traceID: request.traceID)
                    result.report()
                    result.handleAction()
                })
            }
        case .unknown:
            if Self.checkIsAllow(validateResultType: result.result) {
                Logger.warning("SecurityPolicy - return allow with source: unknown",
                               extraInfo: ["resultType": result.result],
                               traceID: request.traceID)
                return .allow {
                    Logger.info("SecurityPolicy - default behavior called for unknown allow",
                                traceID: request.traceID)
                    result.report()
                    result.handleAction()
                }
            } else {
                Logger.warning("SecurityPolicy - return forbidden with source: unknown",
                               extraInfo: ["resultType": result.result],
                               traceID: request.traceID)
                let service = service
                return .forbidden(denyType: .blockByFileStrategy) { _, _ in
                    Logger.info("SecurityPolicy - default behavior called for unknown forbidden",
                                traceID: request.traceID)
                    result.report()
                    result.handleAction()
                }
            }
        }
    }

    private static func checkIsAllow(validateResultType: ValidateResultType) -> Bool {
        switch validateResultType {
        case .unknown, .allow, .null:
            // 默认放行，由后端兜底
            return true
        case .deny, .error:
            DocsLogger.error("Admin control operation:\(validateResultType.rawValue)")
            return false
        @unknown default:
            return true
        }
    }
}

private extension PermissionRequest.BizDomain {
    var fileBizDomain: FileBizDomain {
        switch self {
        case let .customCCM(fileBizDomain):
            return fileBizDomain
        case let .customIM(fileBizDomain, _, _, _, _, _, _):
            return fileBizDomain
        }
    }
}
