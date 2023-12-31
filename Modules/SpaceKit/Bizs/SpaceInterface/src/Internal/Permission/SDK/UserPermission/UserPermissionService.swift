//
//  UserPermissionService.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
import RxSwift

public enum UserPermissionResponse: Equatable {
    /// 获取权限成功
    case success
    /// 没有访问权限，如审核、需要密码，可以申请时会返回 userInfo 供业务展示 UI
    case noPermission(statusCode: StatusCode, applyUserInfo: AuthorizedUserInfo?)

    public enum StatusCode: Equatable, Codable {
        /// 状态正常: 0
        case normal
        /// 机器审核拦截: 10009
        case auditError
        /// 人工审核拦截，或文档被举报: 10013
        case reportError
        /// 需要输入密码才可以访问: 10016
        case passwordRequired
        /// 密码不正确: 10017
        case wrongPassword
        /// 密码尝试次数达到上限: 10018
        case attemptReachLimit
        /// 文档被删除: 1002
        case entityDeleted
        /// 其他未处理状态码
        case unknown(code: Int)
    
        // nolint: magic number
        public var rawValue: Int {
            switch self {
            case .normal:
                return 0
            case .auditError:
                return 10009
            case .reportError:
                return 10013
            case .passwordRequired:
                return 10016
            case .wrongPassword:
                return 10017
            case .attemptReachLimit:
                return 10018
            case .entityDeleted:
                return 1002
            case let .unknown(code):
                return code
            }
        }
        
        // nolint: magic number
        public init(rawValue: Int) {
            switch rawValue {
            case 0:
                self = .normal
            case 10009:
                self = .auditError
            case 10013:
                self = .reportError
            case 10016:
                self = .passwordRequired
            case 10017:
                self = .wrongPassword
            case 10018:
                self = .attemptReachLimit
            case 1002:
                // entityDeleted 不应该直接通过 status_code 字段返回，只能通过最外层 code 主动设置
                self = .unknown(code: rawValue)
            default:
                self = .unknown(code: rawValue)
            }
        }
    }
}

public protocol UserPermissionService: AnyObject {
    /// 是否已经完成用户权限的请求
    var ready: Bool { get }
    /// 用户权限已请求到，且有权限
    var hasPermission: Bool { get }
    /// 定位日志用
    var sessionID: String { get }
    /// 权限变化时的事件，供业务方监听
    /// 建立监听时，会重放已请求到的 Permission (若有)
    var onPermissionUpdated: Observable<UserPermissionResponse> { get }
    /// 当因无网导致用户权限请求失败时，从缓存中获取权限信息，用于处理离线场景下的管控逻辑
    var offlinePermission: Observable<UserPermissionResponse> { get }
    /// 最后一次请求用户权限的结果，nil 表示尚未请求成功
    var permissionResponse: UserPermissionResponse? { get }
    /// 获取业务可交互的权限模型容器，nil 表示尚未请求成功
    var containerResponse: PermissionContainerResponse? { get }
    /// 默认的 bizDomain
    var defaultBizDomain: PermissionRequest.BizDomain { get }
    /// 发起网络请求更新用户权限
    @discardableResult
    func updateUserPermission() -> Single<UserPermissionResponse>
    /// 使用已获取到的数据更新用户权限更新 Service
    @discardableResult
    func setUserPermission(data: Data) throws -> UserPermissionResponse
    /// 解析已获取到的数据为用户权限模型容器，不会更新 Service 内部状态
    func parsePermissionContainer(data: Data) throws -> PermissionContainerResponse
    /// 同步鉴权方法，会同时判断 SDK 全局管控与 UserPermission，如果 UserPermission 没有 ready，一定无法通过用户权限检查
    func validate(operation: PermissionRequest.Operation,
                  bizDomain: PermissionRequest.BizDomain) -> PermissionResponse
    /// 有豁免逻辑的同步鉴权方法
    func validate(exemptScene: PermissionExemptScene) -> PermissionResponse
    /// 异步鉴权方法，会同时判断 SDK 全局管控与 UserPermission，如果 UserPermission 没有 ready，一定无法通过用户检查
    func asyncValidate(operation: PermissionRequest.Operation,
                       bizDomain: PermissionRequest.BizDomain,
                       completion: @escaping (PermissionResponse) -> Void)
    /// 有豁免逻辑的异步鉴权方法
    func asyncValidate(exemptScene: PermissionExemptScene,
                       completion: @escaping (PermissionResponse) -> Void)
    /// DLP 场景要求业务方尽可能传入 tenantID
    func update(tenantID: String)
    /// 管控的资源可见时触发，对应 viewWillAppear
    func notifyResourceWillAppear()
    /// 管控的资源不可见时触发，对应 viewDidDisappear
    func notifyResourceDidDisappear()
}

public extension UserPermissionService {
    /// 同步鉴权方法，会同时判断 SDK 全局管控与 UserPermission，如果 UserPermission 没有 ready，一定无法通过用户权限检查
    func validate(operation: PermissionRequest.Operation) -> PermissionResponse {
        validate(operation: operation, bizDomain: defaultBizDomain)
    }
    /// 异步鉴权方法，会同时判断 SDK 全局管控与 UserPermission，如果 UserPermission 没有 ready，一定无法通过用户检查
    func asyncValidate(operation: PermissionRequest.Operation,
                       completion: @escaping (PermissionResponse) -> Void) {
        asyncValidate(operation: operation, bizDomain: defaultBizDomain, completion: completion)
    }
}

public enum PermissionContainerResponse {
    case success(container: UserPermissionContainer)
    case noPermission(container: UserPermissionContainer?,
                      statusCode: UserPermissionResponse.StatusCode,
                      applyUserInfo: AuthorizedUserInfo?)

    public var container: UserPermissionContainer? {
        switch self {
        case let .success(container):
            return container
        case let .noPermission(container, _, _):
            return container
        }
    }
}

// Container 用于向业务方代码中的权限逻辑暴露用户权限模型
/// 业务方的权限逻辑现有对 UserPermission 的依赖都抽象到 Container 中，注意常规点位鉴权不能写在这里
public protocol UserPermissionContainer {
    // MARK: 限 Leader 自动授权逻辑场景使用，其他场景请勿使用
    /// 是否因为 leader 授权获取 view 权限
    var grantedViewPermissionByLeader: Bool { get }
    /// 权限状态码，用于有权限时仍需要判断封禁申诉的逻辑
    var statusCode: UserPermissionResponse.StatusCode { get }
    /// 是否是 owner
    var isOwner: Bool { get }
    // MARK: 以下三个属性用于申请权限页的判断，其他场景请勿使用
    /// 是否被 CAC 管控分享能力，perceive 与 preview 点位同时控制场景
    var shareControlByCAC: Bool { get }
    /// 是否被 CAC 管控预览点位，仅 preview 点位被管控，perceive 点位未管控
    var previewControlByCAC: Bool { get }
    /// 是否被 Admin 精细化管控预览点位，canPerceive 且 ！canView 场景触发
    var previewBlockByAdmin: Bool { get }
    /// 是否被审计拦截预览，view 点位返回 202 场景
    var viewBlockByAudit: Bool { get }
}
