//
//  AdminPermissionManager.swift
//  SKCommon
//
//  Created by CJ on 2021/1/7.
//

import Foundation
import LarkSecurityAudit
import ServerPB
import SKFoundation
import LarkSecurityComplianceInterface
import LarkSecurityCompliance
import LarkContainer
import UniverseDesignToast
import SpaceInterface

@available(*, deprecated, message: "Use PermissionSDK instead - PermissionSDK")
public final class AdminPermissionManager {
    /// admin是否允许上传（同步）
    public class func adminCanUpload(docType: DocsType? = nil, token: String? = nil) -> Bool {
        let res = checkAuthority(permType: PermissionType.fileUpload, docType: docType, token: token)
        return res
    }

    /// admin是否允许导入（同步）
    public class func adminCanImport(docType: DocsType? = nil, token: String? = nil) -> Bool {
        let res = checkAuthority(permType: PermissionType.fileImport, docType: docType, token: token)
        return res
    }

    /// admin是否允许进行下载（同步）
    public class func adminCanDownload(docType: DocsType? = nil, token: String? = nil) -> Bool {
        let res = checkAuthority(permType: PermissionType.fileDownload, docType: docType, token: token)
        return res
    }

    /// admin是否允许导出（同步）
    public class func adminCanExport(docType: DocsType? = nil, token: String? = nil) -> Bool {
        let res = checkAuthority(permType: PermissionType.fileExport, docType: docType, token: token)
        return res
    }

    /// admin是否允许用其他应用打开（同步）
    public class func adminCanOtherAppOpen(docType: DocsType? = nil, token: String? = nil) -> Bool {
        let res = checkAuthority(permType: PermissionType.fileAppOpen, docType: docType, token: token)
        return res
    }

    /// admin是否允许复制/创建副本（同步）
    public class func adminCanCopy(docType: DocsType? = nil, token: String? = nil) -> Bool {
        let res = checkAuthority(permType: PermissionType.fileCopy, docType: docType, token: token)
        return res
    }

    /// admin是否允许分享到外部（同步）
    public class func adminCanExternalShare(docType: DocsType? = nil, token: String? = nil) -> Bool {
        let res = checkAuthority(permType: PermissionType.fileShare, docType: docType, token: token)
        return res
    }

    /*
     for drive
     admin是否允许操作（同步, 透传）
     */
    public class func adminCheckAuthorityForDriveSdk(permType: PermissionType, object: Entity?) -> ResultType {
        let securityAudit = SecurityAudit()
        let res = securityAudit.checkAuthority(permType: permType, object: object)
        return res
    }

    private class func checkAuthority(permType: PermissionType, docType: DocsType? = nil, token: String? = nil) -> Bool {
        let securityAudit = SecurityAudit()
        var authResult: AuthResult
        if let docType = docType,
           let token = token {
            var entity = Entity()
            entity.entityType = getEntityTypeByDocsType(docType)
            entity.id = token
            authResult = securityAudit.checkAuth(permType: permType, object: entity)
        } else {
            authResult = securityAudit.checkAuth(permType: permType)
        }
        // 默认放行，由后端兜底
        var res: Bool = true
        switch authResult {
        case .unknown, .allow, .null:
            res = true
        case .deny, .error:
            DocsLogger.error("AdminPermissionManager--Admin control operation:\(authResult.rawValue)")
            res = false
        @unknown default:
            res = true
        }
        return res
    }

    // 通过DocsType映射获得SDK需要的ServerPB_Authorization_EntityType
    class func getEntityTypeByDocsType(_ type: DocsType) -> ServerPB_Authorization_EntityType {
        var entityType = ServerPB_Authorization_EntityType.unknown
        switch type {
        case .doc:
            entityType = .ccmDoc
        case .sheet:
            entityType = .ccmSheet
        case .bitable:
            entityType = .ccmBitable
        case .mindnote:
            entityType = .ccmMindnote
        case .file:
            entityType = .ccmFile
        case .slides:
            entityType = .ccmSlide
        case .imMsgFile:
            entityType = .imFile
        default:
            entityType = .unknown
        }
        return entityType
    }
}

public extension CCMSecurityPolicyService {
    ///鉴权结果
    struct ValidateResult {
        /// 是否允许
        public let allow: Bool
        /// 结果来源于哪种模型的校验
        public let validateSource: ValidateSource

        public init(allow: Bool, validateSource: ValidateSource) {
            self.allow = allow
            self.validateSource = validateSource
        }

        // 对 FileBizDomain 为 .unknown 的场景，安全 SDK 要求业务侧直接放行
        fileprivate static var allowForUnknownFileBizDomain: Self {
            ValidateResult(allow: true, validateSource: .unknown)
        }

        // 安全 SDK deny 且 source 为 unknown 时，转换为 CAC deny 让业务方弹窗兜底
        fileprivate static var denyForUnknownSource: Self {
            ValidateResult(allow: false, validateSource: .fileStrategy)
        }
    }

    // 对应安全 SDK fileBizDomain 和对应拓展属性，影响使用哪种业务实体模型
    enum BizDomain {
        // 对应 CCMEntity
        case customCCM(fileBizDomain: FileBizDomain)
        // 对应 IMFileEntity
        case customIM(fileBizDomain: FileBizDomain,
                      senderUserID: Int64? = nil,
                      senderTenantID: Int64? = nil,
                      msgID: String? = nil,
                      fileKey: String? = nil,
                      chatID: Int64? = nil,
                      chatType: Int64? = nil)

        // 默认 CCM 业务使用
        public static var ccm: Self { .customCCM(fileBizDomain: .ccm) }
        // 对应 CalendarEntity，但日历场景目前还没有仔细梳理完，暂时仍继续使用 CCMEntity + calendar domain
        public static var calendar: Self { .customCCM(fileBizDomain: .calendar) }
        // 默认的 IM 场景使用，不需要任何额外参数
        public static var im: Self { .customIM(fileBizDomain: .im) }

        fileprivate var fileBizDomain: FileBizDomain {
            switch self {
            case let .customCCM(fileBizDomain),
                let .customIM(fileBizDomain, _, _, _, _, _, _):
                return fileBizDomain
            }
        }

        // 入参对应 PolicyEntity 公共参数
        fileprivate func convertEntity(entityType: LarkSecurityComplianceInterface.EntityType,
                           entityDomain: EntityDomain,
                           entityOperate: EntityOperate,
                           operatorTenantID: Int64,
                           operatorUID: Int64) -> PolicyEntity {
            switch self {
            case let .customCCM(fileBizDomain):
                DocsLogger.info("authorize using CCM Entity with bizDomain: \(fileBizDomain)")
                return CCMEntity(entityType: entityType,
                                 entityDomain: entityDomain,
                                 entityOperate: entityOperate,
                                 operatorTenantId: operatorTenantID,
                                 operatorUid: operatorUID,
                                 fileBizDomain: fileBizDomain)
                // 日历场景还没有梳理完，没有明确结论，暂时沿用上面的 CCMEntity + calendar domain
//            case .calendar:
//                DocsLogger.info("authorize using Calendar Entity")
//                return CalendarEntity(entityType: entityType,
//                                      entityDomain: entityDomain,
//                                      entityOperate: entityOperate,
//                                      operatorTenantId: operatorTenantID,
//                                      operatorUid: operatorUID,
//                                      fileBizDomain: .calendar)
            case let .customIM(fileBizDomain,
                               senderUserID,
                               senderTenantID,
                               msgID,
                               fileKey,
                               chatID,
                               chatType):
                DocsLogger.info("authorize using IM File Entity")
                return IMFileEntity(entityType: entityType,
                                    entityDomain: entityDomain,
                                    entityOperate: entityOperate,
                                    operatorTenantId: operatorTenantID,
                                    operatorUid: operatorUID,
                                    fileBizDomain: fileBizDomain,
                                    senderUserId: senderUserID,
                                    senderTenantId: senderTenantID,
                                    msgId: msgID,
                                    fileKey: fileKey,
                                    chatID: chatID,
                                    chatType: chatType)
            }
        }
    }
}

@available(*, deprecated, message: "Use PermissionSDK instead - PermissionSDK")
public class CCMSecurityPolicyService {

    // 对调用安全 SDK 接口的参数封装, 对应 SecurityPolicyService 的 validate 接口
    private struct ValidateRequest {
        let policyModel: PolicyModel
        let authEntity: AuthEntity
        let config: ValidateConfig
    }

    // 根据 BizDomain 选用对应的 Entity 类型构造
    private static func convertEntity(entityOperate: EntityOperate,
                                      docType: DocsType,
                                      operatorTenantID: Int64,
                                      operatorUID: Int64,
                                      fileBizDomain: BizDomain) -> PolicyEntity {
        let entityType = entityTypeFor(docType: docType, entityOperate: entityOperate)
        let entityDomain = entityDomainFor(entityOperate: entityOperate, docType: docType)
        return fileBizDomain.convertEntity(entityType: entityType,
                                           entityDomain: entityDomain,
                                           entityOperate: entityOperate,
                                           operatorTenantID: operatorTenantID,
                                           operatorUID: operatorUID)
    }

    // 将业务传入的参数转换为安全 SDK 的参数模型
    private static func generateValidateRequest(entityOperate: EntityOperate,
                                                docType: DocsType,
                                                token: String?,
                                                operatorTenantID: Int64,
                                                operatorUID: Int64,
                                                fileBizDomain: BizDomain) -> ValidateRequest {
        /// 生成 策略校验模型 PolicyEntity
        let policyEntity = convertEntity(entityOperate: entityOperate,
                                         docType: docType,
                                         operatorTenantID: operatorTenantID,
                                         operatorUID: operatorUID,
                                         fileBizDomain: fileBizDomain)
        let pointKey = pointKeyFor(entityOperate: entityOperate)
        let policyModel = PolicyModel(pointKey, policyEntity)

        /// 生成 权限校验模型 AuthEntity
        let entity = entityFor(docType: docType, token: token)
        let permType = PermissionTypeFor(entityOperate: entityOperate)
        let permTypev2 = convertPermissionTypeWhilekaHuaQin(permType: permType, docType: docType)
        DocsLogger.info("convertPermissionType from \(permType) to \(permTypev2)")
        let authEntity = AuthEntity(permType: permTypev2,
                                    entity: entity)

        /// 生成 配置信息ValidateConfig
        let validateConfig = ValidateConfig(ignoreSecurityOperate: true)
        return ValidateRequest(policyModel: policyModel,
                               authEntity: authEntity,
                               config: validateConfig)
    }

    // 将安全 SDK 的结果转换为 CCM 返回给业务方的结果类型
    private static func parse(validateResult: LarkSecurityComplianceInterface.ValidateResult) -> ValidateResult {
        var allow = false
        switch validateResult.extra.resultSource {
        case .fileStrategy:
            allow = (validateResult.result == .allow)
        case .securityAudit:
            allow = isAllowFor(securityAuditResultType: validateResult.result)
        case .dlpDetecting, .dlpSensitive, .ttBlock:
            allow = true
            DocsLogger.info("dlp type")
        case .unknown:
            allow = isAllowFor(securityAuditResultType: validateResult.result)
            DocsLogger.info("unknown type")
            guard allow else {
                DocsLogger.warning("convert unknown source deny result to CAC deny result")
                return .denyForUnknownSource
            }
        }
        return ValidateResult(allow: allow, validateSource: validateResult.extra.resultSource)
    }

    /// 鉴权
    /// - Parameters:
    ///   - operate: 操作点位
    ///   - domain: 业务域
    ///   - docType: 文档类型
    ///   - token: 当前操作实体的唯一标识，文档token，文件fileid等
    /// - Returns: 鉴权结果： 见ValidateResult定义
    public class func syncValidate(entityOperate: EntityOperate, fileBizDomain: BizDomain, docType: DocsType, token: String?) -> ValidateResult {
        spaceAssert(docType != .wiki, "use wiki content type for CAC validation")
        if case .unknown = fileBizDomain.fileBizDomain {
            DocsLogger.warning("syncValidate allow for unknown file biz domain, operate: \(entityOperate.rawValue), type: \(docType), token: \(DocsTracker.encrypt(id: token ?? ""))")
            return .allowForUnknownFileBizDomain
        }

        /// 获取租户id和uid
        guard let uid = User.current.basicInfo?.userID, !uid.isEmpty, let operatorUID = Int64(uid),
              let tenantID = User.current.basicInfo?.tenantID, !tenantID.isEmpty, let operatorTenantID = Int64(tenantID) else {
            spaceAssertionFailure()
            DocsLogger.error("uid or tenantID is invalid")
            return ValidateResult(allow: false, validateSource: .fileStrategy)
        }

        let request = generateValidateRequest(entityOperate: entityOperate,
                                              docType: docType,
                                              token: token,
                                              operatorTenantID: operatorTenantID,
                                              operatorUID: operatorUID,
                                              fileBizDomain: fileBizDomain)

        @Provider var securityPolicyService: SecurityPolicyService
        /// 鉴权
        let validateResult = securityPolicyService.cacheValidate(policyModel: request.policyModel,
                                                                 authEntity: request.authEntity,
                                                                 config: request.config)
        DocsLogger.info("syncValidate operate: \(entityOperate.rawValue), result: \(validateResult), type=\(docType.rawValue), token=\(DocsTracker.encrypt(id: token ?? ""))")
        let result = parse(validateResult: validateResult)
        return result
    }

    public class func asyncValidate(entityOperate: EntityOperate, fileBizDomain: BizDomain, docType: DocsType, token: String?, completion: @escaping (ValidateResult) -> Void) {
        spaceAssert(docType != .wiki, "use wiki content type for CAC validation")
        if case .unknown = fileBizDomain.fileBizDomain {
            DocsLogger.warning("asyncValidate allow for unknown file biz domain, operate: \(entityOperate.rawValue), type: \(docType), token: \(DocsTracker.encrypt(id: token ?? ""))")
            completion(.allowForUnknownFileBizDomain)
            return
        }
        /// 获取租户id和uid
        guard let uid = User.current.basicInfo?.userID, !uid.isEmpty, let operatorUID = Int64(uid),
              let tenantID = User.current.basicInfo?.tenantID, !tenantID.isEmpty, let operatorTenantID = Int64(tenantID) else {
            spaceAssertionFailure()
            DocsLogger.error("uid or tenantID is invalid")
            completion(ValidateResult(allow: false, validateSource: .fileStrategy))
            return
        }

        let request = generateValidateRequest(entityOperate: entityOperate,
                                              docType: docType,
                                              token: token,
                                              operatorTenantID: operatorTenantID,
                                              operatorUID: operatorUID,
                                              fileBizDomain: fileBizDomain)

        @Provider var securityPolicyService: SecurityPolicyService
        securityPolicyService.asyncValidate(policyModel: request.policyModel,
                                            authEntity: request.authEntity,
                                            config: request.config) { validateResult in
            DocsLogger.info("asyncValidate operate: \(entityOperate.rawValue), result: \(validateResult), type=\(docType.rawValue), token=\(DocsTracker.encrypt(id: token ?? ""))")
            let result = parse(validateResult: validateResult)
            completion(result)
        }
    }

    /// 安全侧弹框(仅弹框，不鉴权)
    /// - Parameters:
    ///   - operate: 操作点位
    ///   - domain: 业务域
    ///   - docType: 文档类型
    ///   - token: 当前操作实体的唯一标识，文档token，文件fileid等
    public class func showInterceptDialog(entityOperate: EntityOperate, fileBizDomain: CCMSecurityPolicyService.BizDomain, docType: DocsType, token: String?) {
        /// 获取租户id和uid
        guard let uid = User.current.basicInfo?.userID, !uid.isEmpty, let numberUid = Int64(uid),
              let tenantID = User.current.basicInfo?.tenantID, !tenantID.isEmpty, let numberTenantID = Int64(tenantID) else {
            spaceAssertionFailure()
            DocsLogger.error("uid or tenantID is invalid")
            return
        }

        @Provider var securityPolicyService: SecurityPolicyService

        /// 生成 策略校验模型 PolicyEntity
        let policyEntity = convertEntity(entityOperate: entityOperate,
                                         docType: docType,
                                         operatorTenantID: numberTenantID,
                                         operatorUID: numberUid,
                                         fileBizDomain: fileBizDomain)
        let pointKey = pointKeyFor(entityOperate: entityOperate)
        let policyModel = PolicyModel(pointKey, policyEntity)
        securityPolicyService.showInterceptDialog(policyModel: policyModel)
        DocsLogger.info("showInterceptDialog: \(entityOperate.rawValue), type=\(docType.rawValue), token=\(DocsTracker.encrypt(id: token ?? ""))")
    }

    private class func entityDomainFor(entityOperate: EntityOperate, docType: DocsType) -> EntityDomain {
        switch docType {
        case .imMsgFile: return .im
        default: return .ccm
        }
    }

    /// 生成权限解析模型Entity
    private class func entityFor(docType: DocsType, token: String?) -> Entity {
        var entity = Entity()
        entity.entityType = AdminPermissionManager.getEntityTypeByDocsType(docType)
        entity.id = token ?? ""
        return entity
    }

    /// 解析权限模型返回值
    private class func isAllowFor(securityAuditResultType: ValidateResultType) -> Bool {
        /// 默认放行，由后端兜底
        var res: Bool = true
        switch securityAuditResultType {
        case .unknown, .allow, .null:
            res = true
        case .deny, .error:
            DocsLogger.error("Admin control operation:\(securityAuditResultType.rawValue)")
            res = false
        @unknown default:
            res = true
        }
        return res
    }

    ///doctype转EntityType
    private class func entityTypeFor(docType: DocsType, entityOperate: EntityOperate) -> LarkSecurityComplianceInterface.EntityType {
        /// 这几种操作使用.file类型
        let entityOperates: [EntityOperate] = [.ccmFileUpload, .ccmFileDownload, .ccmAttachmentUpload, .ccmAttachmentDownload]
        if entityOperates.contains(entityOperate) {
            return EntityType.file
        }

        switch docType {
        case .doc: return EntityType.doc
        case .docX: return EntityType.docx
        case .sheet: return EntityType.sheet
        case .bitable: return EntityType.bitable
        case .mindnote: return EntityType.mindnote
        case .file: return EntityType.file
        case .folder: return EntityType.spaceCatalog
        case .imMsgFile: return EntityType.imMsgFile
        default:
            spaceAssertionFailure("invalid type")
            return EntityType.doc
        }
    }

    ///KA_HQ https://bytedance.feishu.cn/docx/WNaFdA46HobJbRxK4ZWcZpcNnmb
    private class func convertPermissionTypeWhilekaHuaQin(permType: PermissionType, docType: DocsType) -> PermissionType {
        guard UserScopeNoChangeFG.GQP.legacyFileProtectCloudDocDownload else {
            DocsLogger.info("fg close")
            return permType
        }
        let types: [DocsType] = [.doc, .docX, .sheet, .mindnote, .bitable]
        let isDoc = types.contains(docType)

        guard isDoc else {
            DocsLogger.info("is not doc")
            return permType
        }
        switch permType {
        case .fileDownload: return .docDownload
        case .fileExport: return .docExport
        @unknown default: return permType
        }
    }

    ///EntityOperate转PermissionType
    private class func PermissionTypeFor(entityOperate: EntityOperate) -> PermissionType {
        switch entityOperate {
        case .ccmFileUpload, .ccmAttachmentUpload: return PermissionType.fileUpload
        case .ccmFileDownload, .ccmAttachmentDownload: return PermissionType.fileDownload
        case .ccmExport: return PermissionType.fileExport
        case .ccmCopy, .ccmCreateCopy: return PermissionType.fileCopy
        case .ccmFilePreView: return .localFilePreview
        case .ccmContentPreview: return .docPreviewAndOpen
        case .ccmMoveRecycleBin: return .fileDelete
        case .imFileDownload: return .fileDownload
        case .imFileCopy: return .fileCopy
        case .imFilePreview: return .localFilePreview
        case .imFileRead: return .fileRead
        default:
            spaceAssertionFailure("invalid entityOperate")
            return PermissionType.fileUpload
        }
    }
    ///EntityOperate获取PointKey
    private class func pointKeyFor(entityOperate: EntityOperate) -> PointKey {
        switch entityOperate {
        case .ccmCopy: return PointKey.ccmCopy
        case .ccmExport: return PointKey.ccmExport
        case .ccmAttachmentDownload: return PointKey.ccmAttachmentDownload
        case .ccmAttachmentUpload: return PointKey.ccmAttachmentUpload
        case .ccmContentPreview: return PointKey.ccmContentPreview
        case .ccmFilePreView: return PointKey.ccmFilePreView
        case .ccmCreateCopy: return PointKey.ccmCreateCopy
        case .ccmFileUpload: return PointKey.ccmFileUpload
        case .ccmFileDownload: return PointKey.ccmFileDownload
        case .ccmMoveRecycleBin: return PointKey.ccmMoveRecycleBin
        case .imFileDownload: return PointKey.imFileDownload
        case .imFileCopy: return PointKey.imFileCopy
        case .imFilePreview: return PointKey.imFilePreview
        case .imFileRead: return PointKey.imFileRead
        default:
            spaceAssertionFailure("invalid entityOperate")
            return .ccmCopy
        }
    }
}
