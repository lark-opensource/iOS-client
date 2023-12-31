//
//  SecurityPolicyDefines.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2022/11/15.
//

import Foundation
import ServerPB
import SwiftyJSON
import LarkContainer
import LarkSecurityComplianceInfra

public typealias PermissionType = ServerPB_Authorization_PermissionType
public typealias Entity = ServerPB_Authorization_Entity

public struct ValidateConfig {
    public var ignoreSecurityOperate: Bool
    public var ignoreCache: Bool
    public var ignoreReport: Bool
    public let cid: String
    
    public init(ignoreSecurityOperate: Bool = false, ignoreCache: Bool = false, ignoreReport: Bool = false, cid: String? = nil) {
        self.ignoreSecurityOperate = ignoreSecurityOperate
        self.ignoreCache = ignoreCache
        self.ignoreReport = ignoreReport
        self.cid = cid ?? UUID().uuidString
    }
}

public final class PolicyModel: Codable {
    public var pointKey: PointKey
    public var entity: PolicyEntity
    
    enum CodingKeys: String, CodingKey {
        case pointKey
        case entity
    }
    
    public init(_ pointKey: PointKey, _ entity: PolicyEntity) {
        self.pointKey = pointKey
        self.entity = entity
        
    }

#if DEBUG || ALPHA
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.pointKey = try container.decode(PointKey.self, forKey: .pointKey)
        
        if let entity = try? container.decode(CCMEntity.self, forKey: .entity) {
            if entity.fileBizDomain == .calendar, let calendarEntity = try? container.decode(CalendarEntity.self, forKey: .entity) {
                self.entity = calendarEntity
            } else {
                self.entity = entity
            }
        } else {
            self.entity = try container.decode(PolicyEntity.self, forKey: .entity)
        }
    }
#endif
    
}

public class PolicyEntity: SecurityPolicyParser {
    public var entityType: EntityType
    public var entityDomain: EntityDomain
    public var entityOperate: EntityOperate
    public var operatorTenantId: Int64
    public var operatorUid: Int64
    public init(entityType: EntityType, entityDomain: EntityDomain, entityOperate: EntityOperate, operatorTenantId: Int64, operatorUid: Int64) {
        self.entityType = entityType
        self.entityDomain = entityDomain
        self.entityOperate = entityOperate
        self.operatorTenantId = operatorTenantId
        self.operatorUid = operatorUid
    }
}

// 权限SDK参数
public struct AuthEntity {
    public var permType: PermissionType
    public var entity: Entity?
    public init(permType: PermissionType, entity: Entity? = nil) {
        self.permType = permType
        self.entity = entity
    }
}

// 业务动态参数
public final class CCMEntity: PolicyEntity {
    public var fileBizDomain: FileBizDomain
    public var token: String?
    public var ownerTenantId: Int64?
    public var ownerUserId: Int64?
    public var tokenEntityType: EntityType?
    
    enum CodingKeys: String, CodingKey {
        case entityType
        case entityDomain
        case entityOperate
        case operatorTenantId
        case operatorUid
        case fileBizDomain
        case token
        case ownerTenantId
        case ownerUserId
        case tokenEntityType
    }
    
    public init(entityType: EntityType,
                entityDomain: EntityDomain,
                entityOperate: EntityOperate,
                operatorTenantId: Int64,
                operatorUid: Int64,
                fileBizDomain: FileBizDomain,
                token: String? = nil,
                ownerTenantId: Int64? = nil,
                ownerUserId: Int64? = nil,
                tokenEntityType: EntityType? = nil) {
        self.fileBizDomain = fileBizDomain
        self.token = token
        self.ownerTenantId = ownerTenantId
        self.ownerUserId = ownerUserId
        self.tokenEntityType = tokenEntityType
        super.init(entityType: entityType, entityDomain: entityDomain, entityOperate: entityOperate, operatorTenantId: operatorTenantId, operatorUid: operatorUid)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fileBizDomain = try container.decode(FileBizDomain.self, forKey: .fileBizDomain)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        ownerTenantId = try container.decodeIfPresent(Int64.self, forKey: .ownerTenantId)
        ownerUserId = try container.decodeIfPresent(Int64.self, forKey: .ownerUserId)
        tokenEntityType = try container.decodeIfPresent(EntityType.self, forKey: .tokenEntityType)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entityType, forKey: .entityType)
        try container.encode(entityDomain, forKey: .entityDomain)
        try container.encode(entityOperate, forKey: .entityOperate)
        try container.encode(operatorTenantId, forKey: .operatorTenantId)
        try container.encode(operatorUid, forKey: .operatorUid)
        try container.encode(fileBizDomain, forKey: .fileBizDomain)
        try container.encode(token, forKey: .token)
        try container.encode(ownerTenantId, forKey: .ownerTenantId)
        try container.encode(ownerUserId, forKey: .ownerUserId)
        try container.encode(tokenEntityType, forKey: .tokenEntityType)
    }
}

public final class CalendarEntity: PolicyEntity {
    public var fileBizDomain: FileBizDomain
    public var token: String?
    public var ownerTenantId: Int64?
    public var ownerUserId: Int64?
    public var tokenEntityType: EntityType?
    
    enum CodingKeys: String, CodingKey {
        case entityType
        case entityDomain
        case entityOperate
        case operatorTenantId
        case operatorUid
        case fileBizDomain
        case token
        case ownerTenantId
        case ownerUserId
        case tokenEntityType
    }
    
    public init(entityType: EntityType,
                entityDomain: EntityDomain,
                entityOperate: EntityOperate,
                operatorTenantId: Int64,
                operatorUid: Int64,
                fileBizDomain: FileBizDomain,
                token: String? = nil,
                ownerTenantId: Int64? = nil,
                ownerUserId: Int64? = nil,
                tokenEntityType: EntityType? = nil) {
        self.fileBizDomain = fileBizDomain
        self.token = token
        self.ownerTenantId = ownerTenantId
        self.ownerUserId = ownerUserId
        self.tokenEntityType = tokenEntityType
        super.init(entityType: entityType, entityDomain: entityDomain, entityOperate: entityOperate, operatorTenantId: operatorTenantId, operatorUid: operatorUid)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fileBizDomain = try container.decode(FileBizDomain.self, forKey: .fileBizDomain)
        token = try container.decode(String.self, forKey: .token)
        ownerTenantId = try container.decode(Int64.self, forKey: .ownerTenantId)
        ownerUserId = try container.decode(Int64.self, forKey: .ownerUserId)
        tokenEntityType = try container.decode(EntityType.self, forKey: .tokenEntityType)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entityType, forKey: .entityType)
        try container.encode(entityDomain, forKey: .entityDomain)
        try container.encode(entityOperate, forKey: .entityOperate)
        try container.encode(operatorTenantId, forKey: .operatorTenantId)
        try container.encode(operatorUid, forKey: .operatorUid)
        try container.encode(fileBizDomain, forKey: .fileBizDomain)
        try container.encode(token, forKey: .token)
        try container.encode(ownerTenantId, forKey: .ownerTenantId)
        try container.encode(ownerUserId, forKey: .ownerUserId)
        try container.encode(tokenEntityType, forKey: .tokenEntityType)
    }
}

public final class IMFileEntity: PolicyEntity {
    public var fileBizDomain: FileBizDomain
    public var senderUserId: Int64?
    public var senderTenantId: Int64?
    public var msgId: String?
    public var fileKey: String?
    public var chatID: Int64?
    public var chatType: Int64?
    
    enum CodingKeys: String, CodingKey {
        case entityType
        case entityDomain
        case entityOperate
        case operatorTenantId
        case operatorUid
        case fileBizDomain
        case senderUserId
        case senderTenantId
        case msgId
        case fileKey
        case chatID
        case chatType
    }
    
    public init(
        entityType: EntityType,
        entityDomain: EntityDomain,
        entityOperate: EntityOperate,
        operatorTenantId: Int64,
        operatorUid: Int64,
        fileBizDomain: FileBizDomain,
        senderUserId: Int64? = nil,
        senderTenantId: Int64? = nil,
        msgId: String? = nil,
        fileKey: String? = nil,
        chatID: Int64? = nil,
        chatType: Int64? = nil
    ) {
        self.fileBizDomain = fileBizDomain
        self.senderUserId = senderUserId
        self.senderTenantId = senderTenantId
        self.msgId = msgId
        self.fileKey = fileKey
        self.chatID = chatID
        self.chatType = chatType
        super.init(entityType: entityType, entityDomain: entityDomain, entityOperate: entityOperate, operatorTenantId: operatorTenantId, operatorUid: operatorUid)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fileBizDomain = try container.decode(FileBizDomain.self, forKey: .fileBizDomain)
        senderUserId = try container.decode(Int64.self, forKey: .senderUserId)
        senderTenantId = try container.decode(Int64.self, forKey: .senderTenantId)
        msgId = try container.decode(String.self, forKey: .msgId)
        fileKey = try container.decode(String.self, forKey: .fileKey)
        chatID = try container.decode(Int64.self, forKey: .chatID)
        chatType = try container.decode(Int64.self, forKey: .chatType)
        
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entityType, forKey: .entityType)
        try container.encode(entityDomain, forKey: .entityDomain)
        try container.encode(entityOperate, forKey: .entityOperate)
        try container.encode(operatorTenantId, forKey: .operatorTenantId)
        try container.encode(operatorUid, forKey: .operatorUid)
        try container.encode(fileBizDomain, forKey: .fileBizDomain)
        try container.encode(senderUserId, forKey: .senderUserId)
        try container.encode(senderTenantId, forKey: .senderTenantId)
        try container.encode(msgId, forKey: .msgId)
        try container.encode(fileKey, forKey: .fileKey)
        try container.encode(chatID, forKey: .chatID)
        try container.encode(chatType, forKey: .chatType)
    }
}

public final class VCFileEntity: PolicyEntity {
    public var fileBizDomain: FileBizDomain
    
    enum CodingKeys: String, CodingKey {
        case entityType
        case entityDomain
        case entityOperate
        case operatorTenantId
        case operatorUid
        case fileBizDomain
    }
    
    public init(entityType: EntityType, entityDomain: EntityDomain, entityOperate: EntityOperate, operatorTenantId: Int64, operatorUid: Int64, fileBizDomain: FileBizDomain) {
        self.fileBizDomain = fileBizDomain
        super.init(entityType: entityType, entityDomain: entityDomain, entityOperate: entityOperate, operatorTenantId: operatorTenantId, operatorUid: operatorUid)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fileBizDomain = try container.decode(FileBizDomain.self, forKey: .fileBizDomain)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(entityType, forKey: .entityType)
        try container.encode(entityDomain, forKey: .entityDomain)
        try container.encode(entityOperate, forKey: .entityOperate)
        try container.encode(operatorTenantId, forKey: .operatorTenantId)
        try container.encode(operatorUid, forKey: .operatorUid)
        try container.encode(fileBizDomain, forKey: .fileBizDomain)
    }
}

public struct ValidateResult {
    public let userResolver: UserResolver
    public let result: ValidateResultType
    public let extra: ValidateExtraInfo
    public init(userResolver: UserResolver, result: ValidateResultType, extra: ValidateExtraInfo) {
        self.userResolver = userResolver
        self.result = result
        self.extra = extra
    }
    
    public func handleAction() {
        guard self.result == .deny, let rawActions = extra.rawActions else {
            SCLogger.info("security policy validate result handle action fail, result is not deny or actions is nil")
            return
        }
        let service = try? userResolver.resolve(assert: SecurityPolicyActionDecision.self)
        service?.handleNoPermissionAction(DefaultSecurityAction(rawActions: rawActions))
    }
    
    public func report() {
        let reporter = try? userResolver.resolve(assert: LogReportService.self)
        reporter?.report(self.extra.logInfos)
    }
}

public enum ValidateResultType: Int {
    case unknown = 0    // 未知
    case deny = 1       // 拒绝
    case allow = 2      // 允许
    case null = 3       // 没命中规则，业务方走默认逻辑
    case error = 4      // 没有拉取到权限数据 或 权限数据已过期
}

public enum ValidateErrorReason: Int {
    case networkError = 1
    case requestTimeout = 2
    case requestFailed = 3
}

public struct ValidateLogInfo {
    public let uuid: String
    public let policySetKeys: [String]?
    public init(uuid: String, policySetKeys: [String]?) {
        self.uuid = uuid
        self.policySetKeys = policySetKeys
    }
}

public struct ValidateExtraInfo {
    public let resultSource: ValidateSource
    public let errorReason: ValidateErrorReason?
    public let resultMethod: ValidateResultMethod?
    public let isCredible: Bool
    public let rawActions: String?
    public let logInfos: [ValidateLogInfo]
    public init(resultSource: ValidateSource,
                errorReason: ValidateErrorReason?,
                resultMethod: ValidateResultMethod? = nil,
                isCredible: Bool = true,
                logInfos: [ValidateLogInfo] = [],
                rawActions: String? = nil) {
        self.resultSource = resultSource
        self.errorReason = errorReason
        self.resultMethod = resultMethod
        self.isCredible = isCredible
        self.rawActions = rawActions
        self.logInfos = logInfos
    }
}

public enum ValidateResultMethod: String {
    case cache
    case fastpass
    case localStrategy
    case serverStrategy
    case downgrade
    case fallback
}

public enum ValidateSource {
    case unknown
    case fileStrategy
    case securityAudit
    case dlpDetecting
    case dlpSensitive
    case ttBlock
}
