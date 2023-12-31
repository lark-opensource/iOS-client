//
//  UserPermissionAPI.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2023/8/23.
//

import Foundation
import RxSwift
import UniverseDesignToast

// 有特殊权限的场景，提供业务方自定义用户权限的能力，目前 Drive 第三方附件场景使用
public protocol UserPermissionAPI<UserPermissionModel> {
    associatedtype UserPermissionModel
    typealias PermissionResult = UserPermissionAPIResult<UserPermissionModel>
    var entity: PermissionRequest.Entity { get }
    var offlineUserPermission: UserPermissionModel? { get }
    func updateUserPermission() -> Single<PermissionResult>
    func parseUserPermission(data: Data) throws -> PermissionResult
    func container(for: PermissionResult) -> PermissionContainerResponse
}

public enum UserPermissionAPIResult<UserPermissionModel> {
    case success(permission: UserPermissionModel)
    // 无权限时可能也需要一个 PermissionModel 对象，用于判断 CAC、admin 的管控状态
    case noPermission(permission: UserPermissionModel?, statusCode: UserPermissionResponse.StatusCode, applyUserInfo: AuthorizedUserInfo?)

    public var userPermissionResponse: UserPermissionResponse {
        switch self {
        case .success:
            return .success
        case let .noPermission(_, statusCode, applyUserInfo):
            return .noPermission(statusCode: statusCode, applyUserInfo: applyUserInfo)
        }
    }

    public var userPermission: UserPermissionModel? {
        switch self {
        case let .success(permission):
            return permission
        case let .noPermission(permission, _, _):
            return permission
        }
    }
}

public protocol PermissionSDKValidator {
    var name: String { get }
    func validate(request: PermissionRequest) -> PermissionValidatorResponse
    func asyncValidate(request: PermissionRequest, completion: @escaping (PermissionValidatorResponse) -> Void)
}


public protocol UserPermissionValidator<UserPermissionModel>: PermissionSDKValidator {
    associatedtype UserPermissionModel
    init(model: UserPermissionModel?, isFromCache: Bool)
}

public enum PermissionValidatorResponse {
    case allow(completion: () -> Void)
    case forbidden(denyType: PermissionResponse.DenyType,
                   preferUIStyle: PermissionResponse.PreferUIStyle,
                   defaultUIBehaviorType: PermissionDefaultUIBehaviorType)
}

public enum PermissionDefaultUIBehaviorType {
    case toast(config: UDToastConfig, allowOverrideMessage: Bool, operationCallback: ((String?) -> Void)?, onTrigger: (() -> Void)?)
    case present(controllerProvider: () -> UIViewController)
    case custom(action: PermissionResponse.Behavior)

    public static func error(text: String, allowOverrideMessage: Bool, onTrigger: (() -> Void)? = nil) -> Self {
        .toast(config: UDToastConfig(toastType: .error, text: text, operation: nil),
               allowOverrideMessage: allowOverrideMessage,
               operationCallback: nil,
               onTrigger: onTrigger)
    }

    public static func info(text: String, allowOverrideMessage: Bool, onTrigger: (() -> Void)? = nil) -> Self {
        .toast(config: UDToastConfig(toastType: .info, text: text, operation: nil),
               allowOverrideMessage: allowOverrideMessage,
               operationCallback: nil,
               onTrigger: onTrigger)
    }

    public static func warning(text: String, allowOverrideMessage: Bool, onTrigger: (() -> Void)? = nil) -> Self {
        .toast(config: UDToastConfig(toastType: .warning, text: text, operation: nil),
               allowOverrideMessage: allowOverrideMessage,
               operationCallback: nil,
               onTrigger: onTrigger)
    }
}
