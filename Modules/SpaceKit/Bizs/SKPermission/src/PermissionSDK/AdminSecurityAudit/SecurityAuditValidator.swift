//
//  SecurityAuditValidator.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/19.
//

import Foundation
import LarkSecurityAudit
import SKFoundation
import SpaceInterface

// 为单测替换实现提供封装
protocol SecurityAuditProvider {
    func validate(permissionType: PermissionType, entity: Entity) -> AuthResult
}

/// 依赖 LarkSecurityAudit 提供鉴权
final class AdminSecurityAuditProvider: SecurityAuditProvider {
    func validate(permissionType: PermissionType, entity: Entity) -> AuthResult {
        let audit = SecurityAudit()
        return audit.checkAuth(permType: permissionType, object: entity)
    }
}

/// Admin 精细化管控逻辑
class SecurityAuditValidator: PermissionValidator {

    var name: String { "SecurityAuditValidator" }

    private let auditProvider: SecurityAuditProvider

    init(auditProvider: SecurityAuditProvider = AdminSecurityAuditProvider()) {
        self.auditProvider = auditProvider
    }

    func shouldInvoke(rules: PermissionExemptRules) -> Bool {
        rules.shouldCheckSecurityAudit
    }

    func validate(request: PermissionRequest) -> PermissionValidatorResponse {
        Logger.verbose("SecurityAudit - start validate request", traceID: request.traceID)
        guard let permissionType = SecurityAuditConverter.convertLegacyPermissionType(operation: request.operation) else {
            // 转换 permissionType 失败表示此操作不受精细化管控，跳过管控
            Logger.info("SecurityAudit - skipped, failed to convert operation to admin permission type",
                        extraInfo: [
                            "operation": request.operation
                        ],
                        traceID: request.traceID)
            return .pass
        }
        let entity = SecurityAuditConverter.convertEntity(entity: request.entity)
        let result = auditProvider.validate(permissionType: permissionType, entity: entity)
        Logger.info("SecurityAudit - finish with result: \(result)",
                    traceID: request.traceID)
        return convertResponse(operation: request.operation, result: result, traceID: request.traceID)
    }

    /// 精细化管控不区分同步异步，复用同步鉴权逻辑
    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionValidatorResponse) -> Void) {
        Logger.verbose("SecurityAudit - async validate not impl, fallback to sync validate request", traceID: request.traceID)
        let response = validate(request: request)
        completion(response)
    }

    private func convertResponse(operation: PermissionRequest.Operation,
                                 result: AuthResult,
                                 traceID: String) -> PermissionValidatorResponse {
        switch result {
        case .unknown, .allow, .null:
            Logger.info("SecurityAudit - return allow response for result: \(result)", traceID: traceID)
            return .pass
        case .deny, .error:
            Logger.warning("SecurityAudit - return forbidden response for result: \(result)", traceID: traceID)
            let toastMessage = SecurityAuditConverter.toastMessage(operation: operation)
            return .forbidden(denyType: .blockBySecurityAudit,
                              defaultUIBehaviorType: .error(text: toastMessage, allowOverrideMessage: false))
        @unknown default:
            Logger.warning("SecurityAudit - return allow response for unknown result: \(result)", traceID: traceID)
            return .pass
        }
    }
}
