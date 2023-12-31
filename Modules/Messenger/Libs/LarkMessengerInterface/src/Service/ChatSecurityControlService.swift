//
//  ChatSecurityControlService.swift
//  LarkMessengerInterface
//
//  Created by 王元洵 on 2020/12/25.
//
import Foundation
import LarkModel
import LarkSecurityComplianceInterface
import EENavigator
import LarkUIKit
import ThreadSafeDataStructure

public enum SecurityControlResourceType {
    case image
    case video
    case file
}
public enum SecurityControlEvent: String {
    case saveImage
    case saveVideo
    case saveFile
    case sendImage
    case sendVideo
    case sendFile
    case saveToDrive
    case addSticker
    case openInAnotherApp
    case localImagePreview
    case localVideoPreview
    case localFilePreview
    case fileCopy
    case receive //接收点位（安全侧称为“分享点位”）,接收到文件时需要鉴权，动态点位
}

/// "IMFileEntity"中可为nil的属性组成的Struct
/// DLP检测所需要的信息: fileKey + chatID + chatType + senderUserId + senderTenantId
/// 普通下载点位所需要的信息：senderUserId + senderTenantId
public struct SecurityExtraInfo {
    /// 资源key，1.图片传origin.key
    public private(set) var fileKey: String?
    /// 对于收藏、标记等会话外场景可能没有chatID，符合预期
    public private(set) var chatID: Int64?
    /// 1：单聊，2：群聊，3：话题群；默认为2
    public private(set) var chatType: Int64? = 2
    /// 发送者id
    public private(set) var senderUserId: Int64?
    /// 发送者租户id
    public private(set) var senderTenantId: Int64?
    /// 对应的msgId
    public private(set) var msgId: String?

    public init(fileKey: String, message: Message? = nil, chat: Chat? = nil) {
        self.fileKey = fileKey
        // 如果fileKey包含前缀，需要替换
        for prefix in ["origin:", "middle:", "thumbnail:"] { self.fileKey = fileKey.replacingOccurrences(of: prefix, with: "", options: .regularExpression) }
        // 组装chat
        if let chat = chat {
            self.chatID = (chat.id as NSString).longLongValue
            self.chatType = (chat.chatMode == .threadV2) ? 3 : ((chat.type == .p2P) ? 1 : 2)
        }
        // 组装message
        if let message = message {
            self.senderUserId = (message.fromId as NSString).longLongValue
            self.senderTenantId = ((message.fromChatter?.tenantId ?? "") as NSString).longLongValue
        }
    }

    public init(fileKey: String? = nil, chatID: Int64? = nil, chatType: Int64? = nil, senderUserId: Int64?, senderTenantId: Int64? = nil, msgId: String? = nil) {
        self.fileKey = fileKey
        self.chatID = chatID
        self.chatType = chatType
        self.senderUserId = senderUserId
        self.senderTenantId = senderTenantId
        self.msgId = msgId
    }

    public init(message: Message? = nil) {
        if let message = message {
            self.senderUserId = (message.fromId as NSString).longLongValue
            self.senderTenantId = ((message.fromChatter?.tenantId ?? "") as NSString).longLongValue
        }
    }
}

public protocol ChatSecurityControlService {
    var messageHadAsync: SafeLRUDictionary<String, Bool> { get set }
    /// 安全SDK此接口中会额外检测DLP信息
    func downloadAsyncCheckAuthority(event: SecurityControlEvent, securityExtraInfo: SecurityExtraInfo?, ignoreSecurityOperate: Bool?, completion: @escaping (ValidateResult) -> Void)
    func checkAuthority(event: SecurityControlEvent, ignoreSecurityOperate: Bool) -> ValidateResult
    func checkPreviewAndReceiveAuthority(chat: Chat?, message: Message) -> PermissionDisplayState
    func checkDynamicAuthority(params: DynamicAuthorityParams)
    func authorityErrorHandler(event: SecurityControlEvent,
                               authResult: ValidateResult?,
                               from: NavigatorFrom?,
                               errorMessage: String?,
                               forceToAlert: Bool)
    func checkPermissionPreview(anonymousId: String, message: Message?) -> (Bool, ValidateResult?)
    func checkPermissionFileCopy(anonymousId: String, message: Message?, ignoreSecurityOperate: Bool) -> (Bool, ValidateResult?)
    func getDynamicAuthorityFromCache(event: SecurityControlEvent, message: Message, anonymousId: String?) -> DynamicAuthorityEnum
    func getIfMessageNeedDynamicAuthority(_ message: Message, anonymousId: String?) -> Bool
    func alertForDynamicAuthority(event: SecurityControlEvent,
                                  result: DynamicAuthorityEnum,
                                  from: NavigatorFrom?)
    static func getNoPermissionSummaryText(permissionPreview: Bool,
                                    dynamicAuthorityEnum: DynamicAuthorityEnum,
                                    sourceType: SecurityControlResourceType) -> String
}

public extension ChatSecurityControlService {
    func authorityErrorHandler(event: SecurityControlEvent,
                               authResult: ValidateResult?,
                               from: NavigatorFrom?,
                               errorMessage: String? = nil) {
        authorityErrorHandler(event: event, authResult: authResult, from: from, errorMessage: errorMessage, forceToAlert: false)
    }
    func checkAuthority(event: SecurityControlEvent) -> ValidateResult {
        return self.checkAuthority(event: event, ignoreSecurityOperate: false)
    }

    func downloadAsyncCheckAuthority(event: SecurityControlEvent, securityExtraInfo: SecurityExtraInfo?, ignoreSecurityOperate: Bool? = false, completion: @escaping (ValidateResult) -> Void) {
        return self.downloadAsyncCheckAuthority(event: event, securityExtraInfo: securityExtraInfo, ignoreSecurityOperate: ignoreSecurityOperate, completion: completion)
    }
}

public typealias ValidateResult = LarkSecurityComplianceInterface.ValidateResult

public struct SecurityDynamicResult {
    let validateResult: ValidateResult
    let isFromAsync: Bool
    var isHadAsync: Bool
    public init(validateResult: ValidateResult, isFromAsync: Bool, isHadAsync: Bool) {
        self.validateResult = validateResult
        self.isFromAsync = isFromAsync
        self.isHadAsync = isHadAsync
    }
}

public extension SecurityDynamicResult {
    var authorityAllowed: Bool {
        return self.validateResult.authorityAllowed
    }

    //是降级/兜底/待清理结果，即需要重试
    var isDowngradeResult: Bool {
        return !self.validateResult.extra.isCredible
    }

    var dynamicAuthorityEnum: DynamicAuthorityEnum {
        func getResult() -> DynamicAuthorityEnum {
            if self.authorityAllowed {
                return .allow
            } else {
                return .deny
            }
        }
        // 异步接口返回结果，直接相信
        if self.isFromAsync {
            return getResult()
        } else {
            // 同步接口返回结果
            if self.isDowngradeResult {
                // 是不可信的
                if isHadAsync {
                    // 但这个结果异步校验过，相信
                    return getResult()
                } else {
                    // 并且这个结果没有异步校验过，不相信
                    return .loading
                }
            } else {
                // 是可信的
                return getResult()
            }
        }
    }
}

public extension ValidateResult {
    var authorityAllowed: Bool {
        return self.result != .deny && self.result != .error
    }
}

public extension SecurityDynamicResult? {
    var authorityAllowed: Bool {
        guard let self = self else { return false }
        return self.authorityAllowed
    }

    //是降级结果（或兜底结果），即需要重试
    var isDowngradeResult: Bool {
        guard let self = self else { return true }
        return self.isDowngradeResult
    }

    var dynamicAuthorityEnum: DynamicAuthorityEnum {
        guard let self = self else { return .loading }
        return self.dynamicAuthorityEnum
    }
}

public extension ValidateResult? {
    var authorityAllowed: Bool {
        guard let self = self else { return false }
        return self.authorityAllowed
    }
}

//动态权限的UI表现枚举
public enum DynamicAuthorityEnum: String {
    case allow
    case deny
    case loading

    public var authorityAllowed: Bool {
        return self == .allow
    }
}

public class DynamicAuthorityParams {
    public var event: SecurityControlEvent
    public var messageID: String
    public var senderUserId: Int64
    public var senderTenantId: Int64
    public var onComplete: ((SecurityDynamicResult) -> Void)

    private var policyModelCache: (policyModel: PolicyModel, operatorTenantId: Int64, operatorUid: Int64)?
    public func getPolicyModel(operatorTenantId: Int64,
                               operatorUid: Int64) -> PolicyModel? {
        if let policyModelCache = self.policyModelCache,
           policyModelCache.operatorUid == operatorUid,
           policyModelCache.operatorTenantId == operatorTenantId {
            return policyModelCache.policyModel
        }

        let policyModel = event.generatePolicyModel(operatorTenantId: operatorTenantId,
                                                    operatorUid: operatorUid,
                                                    securityExtraInfo: SecurityExtraInfo(
                                                        senderUserId: senderUserId,
                                                        senderTenantId: senderTenantId, msgId: messageID))
        if let policyModel = policyModel {
            self.policyModelCache = (policyModel: policyModel,
                                     operatorTenantId: operatorTenantId,
                                     operatorUid: operatorUid)
        }
        return policyModel
    }

    public func getTaskId(operatorTenantId: Int64,
                          operatorUid: Int64) -> String {
        return getPolicyModel(operatorTenantId: operatorTenantId, operatorUid: operatorUid)?.taskID ?? ""
    }

    public init(event: SecurityControlEvent,
                messageID: String,
                senderUserId: Int64,
                senderTenantId: Int64,
                onComplete: @escaping ((SecurityDynamicResult) -> Void)) {
        self.event = event
        self.messageID = messageID
        self.senderUserId = senderUserId
        self.senderTenantId = senderTenantId
        self.onComplete = onComplete
    }
}

public extension SecurityControlEvent {
    func generatePolicyModel(operatorTenantId: Int64,
                             operatorUid: Int64,
                             securityExtraInfo: SecurityExtraInfo? = nil) -> PolicyModel? {
        let pointKey: PointKey
        let policyEntity: PolicyEntity
        switch self {
        case .addSticker, .sendVideo, .sendFile, .sendImage:
            assertionFailure("upload event checkAuthority by backend instead of sdk now.")
            return nil
        case .saveFile, .saveImage, .saveVideo, .openInAnotherApp:
            pointKey = .imFileDownload
            policyEntity = getIMFileEntity(entityOperate: .imFileDownload)
        case .localFilePreview, .localImagePreview, .localVideoPreview:
            pointKey = .imFilePreview
            policyEntity = getIMFileEntity(entityOperate: .imFilePreview)
        case .receive:
            pointKey = .imFileRead
            policyEntity = getIMFileEntity(entityOperate: .imFileRead)
        case .saveToDrive:
            pointKey = .ccmFileUpload
            policyEntity = CCMEntity(
                entityType: .file,
                entityDomain: .ccm,
                entityOperate: .ccmFileUpload, operatorTenantId: operatorTenantId, operatorUid: operatorUid, fileBizDomain: .ccm)
        case .fileCopy:
            pointKey = .imFileCopy
            policyEntity = getIMFileEntity(entityOperate: .imFileCopy)
        }

        func getIMFileEntity(entityOperate: EntityOperate) -> IMFileEntity {
            var imFileEntity: IMFileEntity = IMFileEntity(entityType: .imMsgFile,
                                                          entityDomain: .im,
                                                          entityOperate: entityOperate,
                                                          operatorTenantId: operatorTenantId,
                                                          operatorUid: operatorUid,
                                                          fileBizDomain: .im)
            if let securityExtraInfo = securityExtraInfo {
                imFileEntity.senderTenantId = securityExtraInfo.senderTenantId
                imFileEntity.senderUserId = securityExtraInfo.senderUserId
                imFileEntity.fileKey = securityExtraInfo.fileKey
                imFileEntity.chatID = securityExtraInfo.chatID
                imFileEntity.chatType = securityExtraInfo.chatType
                imFileEntity.msgId = securityExtraInfo.msgId
            }
            return imFileEntity
        }

        return PolicyModel(pointKey, policyEntity)
    }

    func generateAuthEntity() -> AuthEntity {
        let permissionType: PermissionType
        var entity: Entity?
        switch self {
        case .addSticker, .sendVideo, .sendFile, .sendImage:
            permissionType = .fileUpload
        case .saveFile, .saveImage, .saveVideo, .openInAnotherApp:
            permissionType = .fileDownload
        case .localImagePreview, .localVideoPreview, .localFilePreview:
            permissionType = .localFilePreview
        case .receive:
            // “接收权限”是新增权限，之前没有接入过权限SDK，所以不进行权限SDK的校验
            assertionFailure("receive can not use it")
            permissionType = .fileRead
        case .saveToDrive:
            permissionType = .fileUpload
            entity = Entity()
            entity?.entityType = .ccmFile
            entity?.id = ""
        case .fileCopy:
            permissionType = .fileCopy
        }
        return AuthEntity(permType: permissionType, entity: entity)
    }
}
