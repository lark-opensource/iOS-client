//
//  Authorization.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/12/24.
//

import Foundation
import RustPB
import RustSDK
import ServerPB
import LarkAccountInterface
import CryptoSwift
import LKCommonsLogging
import LarkContainer
import LarkSecurityComplianceInfra

// swiftlint:disable missing_docs

public typealias PermissionType = ServerPB_Authorization_PermissionType
public typealias Entity = ServerPB_Authorization_Entity
public typealias ResultType = ServerPB_Authorization_ResultType
public typealias CustomizedEntity = ServerPB_Authorization_CustomizedEntity

public enum AuthResult: Int {
    case unknown = 0    // 未知
    case deny = 1       // 拒绝
    case allow = 2      // 允许
    case null = 3       // 没命中规则，业务方走默认逻辑
    case error = 4      // 没有拉取到权限数据 或 权限数据已过期
}

public enum AuthResultErrorReason: Int {
    case networkError = 1

    case requestTimeout = 2

    case requestFailed = 3
}

extension ServerPB_Authorization_ResultType {
    var authResult: AuthResult {
        switch self {
        case .unknown:
            return AuthResult.unknown
        case .deny:
            return AuthResult.deny
        case .allow:
            return AuthResult.allow
        case .null:
            return AuthResult.null
        @unknown default:
            return AuthResult.unknown
        }
    }
}

extension AuthResult {
    var resultType: ResultType {
        switch self {
        case .unknown:
            return ResultType.unknown
        case .deny:
            return ResultType.deny
        case .allow:
            return ResultType.allow
        default:
            return ResultType.null
        }
    }
}

extension ServerPB_Authorization_EntityType: CodingKey {}

public protocol EntityProtocol {
    func getCustomizedFromProtocol() -> CustomizedEntity?
}

extension Entity: EntityProtocol {
    public func getCustomizedFromProtocol() -> CustomizedEntity? {
        let additionData = ["id": id, "entityType": entityType.stringValue]
        let logger = Logger.log(ServerPB_Authorization_Entity.self, category: "SecurityAudit.Entity")
        logger.info("trans entity to customized entity", additionalData: additionData)
        return customizedEntity
    }

}

extension CustomizedEntity: EntityProtocol {
    public func getCustomizedFromProtocol() -> CustomizedEntity? {
        return self
    }

}

extension Entity {
    var customizedEntity: CustomizedEntity {
        var customized = CustomizedEntity()
        customized.id = id
        customized.entityType = entityType.stringValue
        return customized
    }
}

public protocol SecurityAuditAuthProtocol {
    /// 离线鉴权
    func checkAuth(
        permType: PermissionType,
        object: EntityProtocol?
    ) -> AuthResult

    func registe(_ observer: PermissionChangeAction)

    func unRegiste(_ observer: PermissionChangeAction)

    @available(*, deprecated)
    func checkAuthority(
        permType: PermissionType,
        object: EntityProtocol?
    ) -> ResultType
}

extension SecurityAudit: SecurityAuditAuthProtocol {
    public func checkAuth(
        permType: PermissionType,
        object: EntityProtocol? = nil
    ) -> AuthResult {
        let customizedEntity = object?.getCustomizedFromProtocol()
        return SecurityAuditManager.shared.checkAuthority(permType: permType, object: customizedEntity)
    }

    public func checkAuthWithErrorType(
        permType: PermissionType,
        object: EntityProtocol? = nil
    ) -> (AuthResult, AuthResultErrorReason?) {
        let customizedEntity = object?.getCustomizedFromProtocol()
        let authResult = SecurityAuditManager.shared.checkAuthority(permType: permType, object: customizedEntity)
        return SecurityAuditManager.shared.wrapAuthResult(authResult)
    }

    public func checkAuthority(
        permType: PermissionType,
        object: EntityProtocol? = nil
    ) -> ResultType {
        let customizedEntity = object?.getCustomizedFromProtocol()
        let authResult = SecurityAuditManager.shared.checkAuthority(permType: permType, object: customizedEntity)
        return authResult.resultType
    }

    public func registe(_ observer: PermissionChangeAction) {
        SecurityAuditManager.shared.registe(observer)
    }
    public func unRegiste(_ observer: PermissionChangeAction) {
        SecurityAuditManager.shared.unRegiste(observer)
    }
}

extension SecurityAuditManager {
    public var isStarted: Bool {
        started.value
    }

    // get_ntp_time()方法有获取失败的情况，如果获取失败则使用当前系统时间
    static var ntpTime: TimeInterval {
        let ntpTime = TimeInterval(get_ntp_time() / 1000)
       // ntp_time有获取失败的情况，获取失败的时候返回的值是时间的偏移量，和sdk同学沟可以认为通当ntp_time的值大于2010年的时间戳认为获取成功
        let ntpBaseTimestamp: TimeInterval = 1_262_275_200 // 2010-01-01 00:00
        if ntpTime > ntpBaseTimestamp {
            Self.logger.debug("Got NTP time: \(ntpTime)")
            return ntpTime
        } else {
            Self.logger.error("Failed to get ntp time")
            return Date().timeIntervalSince1970
        }
    }
    
    var strictAuthModeCache: Bool {
        get {
            guard let strictAuthMode = strictAuthMode else {
                let key = "SecurityAuditStrictAuthMode"
                let cache = self.udkv?.bool(forKey: key) ?? false
                strictAuthMode = cache
                return cache
            }
            return strictAuthMode
        }
        set {
            if strictAuthMode == newValue { return }
            strictAuthMode = newValue
            let key = "SecurityAuditStrictAuthMode"
            self.udkv?.set(newValue, forKey: key)
        }
    }

    var deprecatedPermTypes: [PermissionType] {
        let defaultValue = [PermissionType.localFilePreview]
        guard let service = try? userResolver?.resolve(assert: SCRealTimeSettingService.self) else { return defaultValue }
        let rawOperates: [Int] = service.array(.securityAuditDeprecatedPermType)
        return rawOperates.compactMap(PermissionType.init(rawValue:))
    }

    // swiftlint:disable function_body_length
    func checkAuthority(
        permType: PermissionType,
        object: CustomizedEntity? = nil
    ) -> AuthResult {
        guard preCheckAuthority(permType: permType) else { return .null }
        return checkAuthorityFromPermissionMap(permType, object: object)
    }

    func preCheckAuthority(permType: PermissionType) -> Bool {
        let additionalData: [String: String] = ["permission_type": "\(permType)"]
        guard let userResolver, PullPermissionService.enablePermission(resolver: userResolver) else {
            Self.logger.info("fg disable", additionalData: additionalData)
            return false
        }
        guard !deprecatedPermTypes.contains(permType) else {
            Self.logger.info("perm type is deprecated", additionalData: additionalData)
            return false
        }
        return true
    }

    func checkAuthorityFromPermissionMap(_ permType: PermissionType, object: CustomizedEntity? = nil) -> AuthResult {
        let cid = uuid()
        var additionalData: [String: String] = ["cid": cid,
                                                "permission_type": "\(permType)"]

        guard let pullPermissionService = pullPermissionService else {
            Self.logger.info("no pullPermissionService", additionalData: additionalData)
            return .null
        }

        guard let permissionResponse = pullPermissionService.permissionResponse,
              let permissionMap = pullPermissionService.permissionMap else {
            let result: AuthResult = strictAuthModeCache ? .error : .null
            additionalData["result"] = "\(result)"
            additionalData["errorType"] = "\(lastErrorType?.rawValue ?? 0)"
            Self.logger.info("no permissionResponse", additionalData: additionalData)
            if self.enablePullPermission() {
                pullPermissionService.fetchPermission(.noneResponse)
            }
            return result
        }
        let currentTime = SecurityAuditManager.ntpTime
        let expiredTime = TimeInterval(permissionResponse.permissionData.expireTime)
        guard expiredTime >= currentTime else {
            let result: AuthResult = strictAuthModeCache ? .error : .null
            additionalData["result"] = "\(result)"
            Self.logger.info("permission expired", additionalData: additionalData)
            if self.enablePullPermission() {
                pullPermissionService.fetchPermission(.noneResponse)
            }
            return result
        }
        guard let permissions = permissionMap[permType] else {
            guard let isForceClear = permissionResponse.permissionExtra.permissionTypeInfos.first(where: { element in element.permType == permType })?.forceClear,
                  isForceClear else {
                additionalData["isForceClear"] = "false"
                Self.logger.info("no permissions in permissionMap", additionalData: additionalData)
                return .null
            }
            let result: AuthResult = strictAuthModeCache ? .error : .null
            additionalData["result"] = "\(result)"
            additionalData["errorType"] = "\(lastErrorType?.rawValue ?? 0)"
            additionalData["isForceClear"] = "\(isForceClear)"
            Self.logger.info("no permission data", additionalData: additionalData)
            if self.enablePullPermission() {
                pullPermissionService.fetchPermission(.noneResponse)
            }
            return result
        }
        // 查找 entityType 和 id 相同的 permission
        if let obj = object, let permission = permissions.first(where: { (permission) -> Bool in
            return permission.object.entityType == obj.entityType && permission.object.id == obj.id
        }) {
            let result = permission.result.authResult
            additionalData["result"] = "\(result)"
            Self.logger.info("specific permission found", additionalData: additionalData)
            return result
        // 查找 entityType 是 any的 permission
        } else if let permission = permissions.first(where: { (permission) -> Bool in
            return ServerPB_Authorization_EntityType.any.stringValue == permission.object.entityType
        }) {
            let result = permission.result.authResult
            additionalData["result"] = "\(result)"
            Self.logger.info("wildcard permission found", additionalData: additionalData)
            return result
        } else {
            Self.logger.info("not found permission", additionalData: additionalData)
            return .null
        }
    }

    private func enablePullPermission() -> Bool {
        guard let userResolver else {
            self.enableFetchPermission = false
            return false
        }
        guard let enablePullPermission = enableFetchPermission else {
            let enablePullPermission = AuditPermissionSetting.optPullPermissionsettings(userResolver: userResolver).authzRetry
            return enablePullPermission
        }
        return enablePullPermission
    }

    func wrapAuthResult(_ result: AuthResult) -> (AuthResult, AuthResultErrorReason?) {
        switch result {
        case .error:
            return (result, lastErrorType)
        default:
            return (result, nil)
        }
    }
    // swiftlint:enable function_body_length

    func registe(_ observer: PermissionChangeAction) {
        if let pullPermissionService = pullPermissionService {
            pullPermissionService.registe(observer)
        }
    }

    func unRegiste(_ observer: PermissionChangeAction) {
        if let pullPermissionService = pullPermissionService {
            pullPermissionService.unRegiste(observer)
        }
    }
}

#if DEBUG || ALPHA
extension SecurityAuditManager {
    public func pullPermission() {
        pullPermissionService?.fetchPermission()
    }
    public func clearPermissionData() {
        pullPermissionService?.clearPermissionData()
    }

    public func fetchPermission() {
        pullPermissionService?.fetchPermission()
    }

    public func retryPullPermission() {
        pullPermissionService?.retryPullPermission()
    }

    public func isStrictMode() -> Bool {
        strictAuthModeCache
    }

    public func getPermissionMap() -> [PermissionType: [ServerPB_Authorization_CustomizedOperatePermission]]? {
        return pullPermissionService?.permissionMap
    }

    public func mockAndStoreData(padding: CryptoSwift.Padding) {
        pullPermissionService?.mockAndStoreData(padding: padding)
    }
}
#endif

// swiftlint:enable missing_docs
