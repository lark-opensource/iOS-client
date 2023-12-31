//
//  PermissionSDKImpl.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
import SpaceInterface
import SKFoundation
import SKCommon
import LarkContainer
import LarkSecurityComplianceInterface

// 拓展一些权限内部的方法
protocol PermissionSDKInterface: PermissionSDK {
    
}

// 考虑到用户态改造，这里不用单例形式提供能力
class PermissionSDKImpl: PermissionSDKInterface {
    // 当前用户 ID
    private let userID: String
    // 当前租户 ID
    private let tenantID: String
    // 注意顺序会影响检测的优先级
    private let globalValidators: [PermissionValidator]
    // 等用户态改造时，传入 userResolver
    convenience init(userID: String, tenantID: String) {
        var validators: [PermissionValidator] = []
        @Provider var securityPolicyService: SecurityPolicyService
        let userIDValue = Int64(userID) ?? -1
        let tenantIDValue = Int64(tenantID) ?? -1
        Logger.info("SDK - init SecurityPolicyValidator",
                    extraInfo: [
                        "userID": userIDValue,
                        "tenantID": tenantIDValue
                    ])
        let securityPolicyValidator = SecurityPolicyValidator(userID: Int64(userID) ?? -1, // 对齐安卓
                                                              tenantID: Int64(tenantID) ?? -1,
                                                              service: securityPolicyService,
                                                              legacyFileProtectConvertionEnable: UserScopeNoChangeFG.GQP.legacyFileProtectCloudDocDownload)
        validators.append(securityPolicyValidator)

        let securityAuditValidator = SecurityAuditValidator()
        validators.append(securityAuditValidator)

        self.init(userID: userID, tenantID: tenantID, validators: validators)
    }

    init(userID: String, tenantID: String, validators: [PermissionValidator]) {
        self.userID = userID
        self.tenantID = tenantID
        self.globalValidators = validators
        Logger.info("SDK - init complete",
                    extraInfo: [
                        "userID": userID,
                        "validators": validators.map(\.name)
                    ])
    }

    func validate(request: PermissionRequest) -> PermissionResponse {
        Logger.info("SDK - start validate request",
                    extraInfo: [
                        "entity": request.entity.desensitizeDescription,
                        "operation": request.operation,
                        "bizDomain": request.bizDomain.desensitizeDescription
                    ],
                    traceID: request.traceID)
        var validatorResponses: [PermissionValidatorResponse] = []
        for validator in globalValidators {
            guard validator.shouldInvoke(rules: request.exemptRules) else {
                Logger.info("SDK - skip exempted validator: \(validator.name)", traceID: request.traceID)
                continue
            }
            let response = validator.validate(request: request)
            guard response.allow else {
                // 返回第一个 forbidden 的结果
                Logger.warning("SDK - validate complete, request block by validator: \(validator.name)", extraInfo: ["response": response.desensitizeDescription], traceID: request.traceID)
                // 提前 return 跳过后面的其他 validator
                return response.finalResponse(traceID: request.traceID)
            }
            validatorResponses.append(response)
        }
        // 全通过了
        Logger.info("SDK - validate complete, request pass by all validators", traceID: request.traceID)
        return .merge(validatorResponses: validatorResponses, traceID: request.traceID)
    }

    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionResponse) -> Void) {
        Logger.info("SDK - start async validate request",
                    extraInfo: [
                        "entity": request.entity.desensitizeDescription,
                        "operation": request.operation,
                        "bizDomain": request.bizDomain.desensitizeDescription
                    ],
                    traceID: request.traceID)
        let requestGroup = DispatchGroup()
        var responses: [PermissionValidatorResponse] = []
        globalValidators.forEach { validator in
            let name = validator.name
            guard validator.shouldInvoke(rules: request.exemptRules) else {
                Logger.info("SDK - skip exempted validator: \(name)", traceID: request.traceID)
                return
            }

            class ClosureOnce {
                var called = false
            }
            let once = ClosureOnce()
            requestGroup.enter()
            validator.asyncValidate(request: request) { response in
                DispatchQueue.main.async {
                    guard !once.called else {
                        Logger.error("SDK - async validation completion called more than once by validator: \(name)",
                                     traceID: request.traceID)
                        spaceAssertionFailure("async vlaidation completion called more than once by validator: \(name), traceID: \(request.traceID)")
                        return
                    }
                    once.called = true
                    if !response.allow {
                        Logger.warning("SDK - request block by validator: \(name)", extraInfo: ["response": response.desensitizeDescription], traceID: request.traceID)
                    }
                    responses.append(response)
                    requestGroup.leave()
                }
            }
        }

        requestGroup.notify(queue: DispatchQueue.main) {
            // 按权重排序后，合并为一个 PermissionResponse，若存在拦截结果，优先级高的排在最前面，优先被返回
            let sortedResponses = responses.sorted(by: Self.sort(lhs:rhs:))
            let finalResponse = PermissionResponse.merge(validatorResponses: sortedResponses,
                                                         traceID: request.traceID)
            Logger.info("SDK - async validate complete, final response isAllow: \(finalResponse.allow)",
                        extraInfo: ["response": finalResponse.desensitizeDescription],
                        traceID: request.traceID)
            completion(finalResponse)
        }
    }

    func getExemptRequest(entity: PermissionRequest.Entity, exemptScene: PermissionExemptScene, extraInfo: PermissionExtraInfo) -> PermissionRequest {
        let request = PermissionRequest(entity: entity, exemptScene: exemptScene, extraInfo: extraInfo)
        Logger.warning("SDK - creating exempt request", extraInfo: [
            "entity": entity.desensitizeDescription,
            "scene": exemptScene,
            "traceID": request.traceID
        ])
        return request
    }

    func userPermissionService(for entity: UserPermissionEntity, withPush: Bool, extraInfo: PermissionExtraInfo?) -> UserPermissionService {
        let sessionID = UUID().uuidString
        let service: UserPermissionService
        switch entity {
        case let .document(token, type, parentMeta):
            let parentInfo: Any
            if let parentMeta {
                parentInfo = [
                    "parentToken": DocsTracker.encrypt(id: parentMeta.objToken),
                    "parentType": parentMeta.objType
                ]
            } else {
                parentInfo = "nil"
            }
            Logger.info("SDK - creating document user permission service", extraInfo: [
                "token": DocsTracker.encrypt(id: token),
                "type": type,
                "parentInfo": parentInfo,
                "sessionID": sessionID
            ])
            let meta = SpaceMeta(objToken: token, objType: type)
            let documentService = DocumentUserPermissionService(meta: meta, parentMeta: parentMeta, permissionSDK: self, sessionID: sessionID, userID: userID, extraInfo: extraInfo)
            let userIDValue = Int64(userID) ?? 0
            let tenantIDValue = Int64(tenantID) ?? 0
            let dlpToken = extraInfo?.overrideDLPMeta?.objToken ?? parentMeta?.objToken ?? token
            let dlpType = extraInfo?.overrideDLPMeta?.objType ?? parentMeta?.objType ?? type
            documentService.dlpContext = DLPSceneContext(token: dlpToken,
                                                         type: dlpType,
                                                         operatorUserID: userIDValue,
                                                         operatorTenantID: tenantIDValue,
                                                         pointKeys: dlpType == .file ? DLPSceneContext.dlpPointKeysForFile : DLPSceneContext.dlpPointKeysForDocument,
                                                         sessionID: sessionID)
            service = documentService
        case let .folder(folderToken):
            Logger.info("SDK - creating folder user permission service", extraInfo: [
                "token": DocsTracker.encrypt(id: folderToken),
                "sessionID": sessionID
            ])
            service = FolderUserPermissionService(folderToken: folderToken, permissionSDK: self, sessionID: sessionID)
        case let .legacyFolder(folderInfo):
            Logger.info("SDK - creating legacy folder user permission service", extraInfo: [
                "token": DocsTracker.encrypt(id: folderInfo.token),
                "folderType": folderInfo.folderType,
                "sessionID": sessionID
            ])
            service = LegacyFolderUserPermissionService(userID: userID, folderInfo: folderInfo, permissionSDK: self, sessionID: sessionID)
        }
        if withPush {
            Logger.info("SDK - creating user permission service wrappred with push service", extraInfo: [
                "entity": entity.desensitizeDescription,
                "sessionID": sessionID
            ])
            let meta = entity.meta
            return UserPermissionServicePushWrapper(backing: service,
                                                    objToken: meta.objToken,
                                                    objType: meta.objType)
        } else {
            return service
        }
    }

    /// DriveSDK 非 CCM 业务域场景使用，帮助业务封装上下文信息
    func driveSDKPermissionService(domain: DriveSDKPermissionDomain,
                                   fileID: String,
                                   bizDomain: PermissionRequest.BizDomain) -> UserPermissionService {
        let sessionID = UUID().uuidString
        Logger.info("SDK - creating DriveSDK user permission service", extraInfo: [
            "fileID": DocsTracker.encrypt(id: fileID),
            "domain": domain,
            "sessionID": sessionID
        ])
        let service = TransparentUserPermissionService(entity: .driveSDK(domain: domain, fileID: fileID),
                                                       bizDomain: bizDomain,
                                                       permissionSDK: self,
                                                       sessionID: sessionID)
        return service
    }

    // 打包使用的 Xcode 14.1 (Swift 5.7.1) 存在 bug，导致 any/some 语法在 iOS 15及以下版本会 crash
    // 在打包机升级到 Xcode 14.2 之前，暂时通过禁用优化绕过此问题
    // https://github.com/apple/swift/issues/61403
    /// 使用非 CCM 标准用户模型的场景使用，如 Drive 第三方附件
    @_optimize(none)
    func driveSDKCustomUserPermissionService<UserPermissionModel>(permissionAPI: any UserPermissionAPI<UserPermissionModel>,
                                                                  validatorType: any UserPermissionValidator<UserPermissionModel>.Type,
                                                                  tokenForDLP: String?,
                                                                  bizDomain: PermissionRequest.BizDomain,
                                                                  sessionID: String) -> UserPermissionService {
        Logger.info("SDK - creating DriveSDK custom user permission service", extraInfo: [
            "entity": permissionAPI.entity.desensitizeDescription,
            "sessionID": sessionID
        ])
        let service = UserPermissionServiceImpl(permissionAPI: permissionAPI, validatorType: validatorType, permissionSDK: self,
                                                defaultBizDomain: bizDomain,
                                                sessionID: sessionID)
        if let tokenForDLP {
            let userIDValue = Int64(userID) ?? 0
            let tenantIDValue = Int64(tenantID) ?? 0
            service.dlpContext = DLPSceneContext(token: tokenForDLP,
                                                 type: .file,
                                                 operatorUserID: userIDValue,
                                                 operatorTenantID: tenantIDValue,
                                                 pointKeys: DLPSceneContext.dlpPointKeysForAttachmentFile,
                                                 sessionID: sessionID)
        }
        return service
    }

    func canHandle(error: Error, context: PermissionCommonErrorContext) -> PermissionResponse.Behavior? {
        let code: Int
        if let docsError = error as? DocsNetworkError {
            code = docsError.errorCode
        } else {
            code = (error as NSError).code
        }
        if let dlpError = DLP.ErrorCode(rawValue: code) {
            Logger.info("SDK - recognize DLP error code: \(dlpError)",
                        extraInfo: ["context": context.desensitizeDescription])
            let behaviorType = DLPCommonErrorHandler.getCommonErrorBehaviorType(token: context.objToken, userID: userID, errorCode: dlpError)
            return PermissionSDKUtils.createDefaultUIBehavior(behaviorType: behaviorType)
        } else if code == SecurityPolicyCommonErrorHandler.commonErrorCode {
            Logger.info("SDK - recognize Security Policy common error code",
                        extraInfo: ["context": context.desensitizeDescription])
            let behaviorType = SecurityPolicyCommonErrorHandler.getCommonErrorBehaviorType()
            return PermissionSDKUtils.createDefaultUIBehavior(behaviorType: behaviorType)
        } else {
            return nil
        }
    }
}


extension PermissionSDKImpl {

    /// 返回 lhs 优先级是否高于 rhs
    private static func sort(lhs: PermissionValidatorResponse,
                             rhs: PermissionValidatorResponse) -> Bool {
        switch (lhs, rhs) {
        case (.allow, _):
            return false
        case (_, .allow):
            return true
        case let (.forbidden(lDenyType, _, _), .forbidden(rDenyType, _, _)):
            // sortByRank 返回的是 rhs > lhs, 这里算的是 lhs > rhs，取个反
            return !PermissionResponse.DenyType.sortByRank(lhs: lDenyType, rhs: rDenyType)
        }
    }
}

extension PermissionRequest {
    var exemptRules: PermissionExemptRules {
        if let exemptConfig {
            guard let rules = exemptConfig as? PermissionExemptRules else {
                // 不允许除 PermissionExemptRules 之外的 exemptConfig 出现
                spaceAssertionFailure("invalid exempt config found: \(exemptConfig)")
                PermissionSDKLogger.error("SDK - invalid exempt rules found in request",
                                          extraInfo: [
                    "entity": entity.desensitizeDescription,
                    "bizDomain": bizDomain.desensitizeDescription,
                    "operation": operation
                ],
                                          traceID: traceID)
                return .default
            }
            return rules
        } else {
            return .default
        }
    }
}

// nolint: magic number
extension PermissionResponse.DenyType {

    // 默认的 UI 样式
    var preferUIStyle: PermissionResponse.PreferUIStyle {
        switch self {
        case .blockByFileStrategy:
            return .disabled
        case .blockBySecurityAudit:
            return .disabled
        case .blockByDLPDetecting:
            return .`default`
        case .blockByDLPSensitive:
            return .`default`
        case .blockByUserPermission:
            return .disabled
        }
    }

    private var sortRank: Double {
        switch self {
        case .blockByFileStrategy:
            return 100
        case .blockBySecurityAudit:
            return 90
        case .blockByDLPSensitive:
            return 80
        case .blockByDLPDetecting:
            return 70
        case let .blockByUserPermission(reason):
            return 60 + reason.sortRank
        }
    }

    /// 简单实现一个排序的规则，rhs 的优先级是否高于 lhs
    static func sortByRank(lhs: PermissionResponse.DenyType, rhs: PermissionResponse.DenyType) -> Bool {
        return lhs.sortRank < rhs.sortRank
    }
}

extension PermissionResponse.DenyType.UserPermissionDenyReason {
    fileprivate var sortRank: Double {
        switch self {
        case .userPermissionNotReady:
            return 5
        case .cacheNotSupport:
            return 4
        case .blockByCAC:
            return 3
        case .blockByAudit:
            return 2
        case .blockByServer:
            return 1
        case .unknown:
            return 0
        }
    }
}
// enable-lint: magic number
