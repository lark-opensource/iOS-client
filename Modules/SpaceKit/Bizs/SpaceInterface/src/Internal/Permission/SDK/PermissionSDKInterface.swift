//
//  PermissionSDKInterface.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
/// SDK 对外接口，对应除文档 UserPermission 外其他维度的全局管控 (Admin、DLP、CAC 等)
/// 注意 SDK 的鉴权接口不判断 UserPermission，有需要请使用 UserPermissionService
public protocol PermissionSDK {
    typealias DriveSDKPermissionDomain = PermissionRequest.Entity.DriveSDKPermissionDomain
    /// 同步鉴权接口
    func validate(request: PermissionRequest) -> PermissionResponse
    /// 异步鉴权接口，仅特定场景、特别关注实时性才使用
    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionResponse) -> Void)
    /// 有豁免需求时，通过此方法构造特殊的 Request，豁免场景和特定的 BizDomain、Operation 绑定，需要提前定义
    func getExemptRequest(entity: PermissionRequest.Entity, exemptScene: PermissionExemptScene, extraInfo: PermissionExtraInfo) -> PermissionRequest
    /// 关注 UserPermission 的业务场景，使用 UsersePermissionService 进行鉴权
    /// - withPush: 是否需要监听权限长链，默认不需要
    func userPermissionService(for entity: UserPermissionEntity, withPush: Bool, extraInfo: PermissionExtraInfo?) -> UserPermissionService
    /// DriveSDK 非 CCM 业务域场景使用，帮助业务封装上下文信息
    func driveSDKPermissionService(domain: DriveSDKPermissionDomain,
                                   fileID: String,
                                   bizDomain: PermissionRequest.BizDomain) -> UserPermissionService
    // 打包使用的 Xcode 14.1 (Swift 5.7.1) 存在 bug，导致 any/some 语法在 iOS 15及以下版本会 crash
    // 在打包机升级到 Xcode 14.2 之前，暂时通过禁用优化绕过此问题
    // https://github.com/apple/swift/issues/61403
    /// 使用非 CCM 标准用户模型的场景使用，如 Drive 第三方附件
    @_optimize(none)
    func driveSDKCustomUserPermissionService<UserPermissionModel>(permissionAPI: any UserPermissionAPI<UserPermissionModel>,
                                                                  validatorType: any UserPermissionValidator<UserPermissionModel>.Type,
                                                                  tokenForDLP: String?,
                                                                  bizDomain: PermissionRequest.BizDomain,
                                                                  sessionID: String) -> UserPermissionService
    /// 识别是否因为鉴权不通过导致业务方网络请求失败
    func canHandle(error: Error, context: PermissionCommonErrorContext) -> PermissionResponse.Behavior?
}

// 如果想获取的是 DriveSDK 第三方附件类型的用户权限，需要用 DriveSDK 包装过的实现
public protocol DrivePermissionSDK {
    func attachmentUserPermissionService(fileToken: String,
                                         mountPoint: String,
                                         authExtra: String?,
                                         bizDomain: PermissionRequest.BizDomain) -> UserPermissionService
}

public struct PermissionCommonErrorContext {
    public var objToken: String
    public var objType: DocsType
    public var operation: PermissionRequest.Operation

    public init(objToken: String, objType: DocsType, operation: PermissionRequest.Operation) {
        self.objToken = objToken
        self.objType = objType
        self.operation = operation
    }
}

public extension PermissionSDK {
    /// 有豁免需求时，通过此方法构造特殊的 Request，豁免场景和特定的 BizDomain、Operation 绑定，需要提前定义
    func getExemptRequest(entity: PermissionRequest.Entity, exemptScene: PermissionExemptScene) -> PermissionRequest {
        getExemptRequest(entity: entity, exemptScene: exemptScene, extraInfo: .default)
    }

    /// 关注 UserPermission 的业务场景，使用 UserPermissionService 进行鉴权
    func userPermissionService(for entity: UserPermissionEntity) -> UserPermissionService {
        userPermissionService(for: entity, withPush: false, extraInfo: nil)
    }
    
    func userPermissionService(for entity: UserPermissionEntity, withPush: Bool) -> UserPermissionService {
        userPermissionService(for: entity, withPush: withPush, extraInfo: nil)
    }
    
}

public struct TNSRedirectInfo {

    public enum AppForm: String {
        case inVideoConference = "vc"
        case standard = "none"
    }

    public let meta: SpaceMeta
    public let redirectURL: URL
    public let module: String
    public let appForm: AppForm

    public var subModule: String?
    public var creatorID: String?
    public var ownerID: String?
    public var ownerTenantID: String?

    public init(meta: SpaceMeta, redirectURL: URL, module: String, appForm: AppForm, subModule: String? = nil, creatorID: String? = nil, ownerID: String? = nil, ownerTenantID: String? = nil) {
        self.meta = meta
        self.redirectURL = redirectURL
        self.module = module
        self.appForm = appForm
        self.subModule = subModule
        self.creatorID = creatorID
        self.ownerID = ownerID
        self.ownerTenantID = ownerTenantID
    }
}
