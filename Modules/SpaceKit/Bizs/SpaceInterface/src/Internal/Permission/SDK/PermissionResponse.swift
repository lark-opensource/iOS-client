//
//  PermissionResponse.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2023/4/17.
//

import UIKit

extension PermissionResponse {
    /// 鉴权失败时的失败原因信息
    public enum DenyType: Equatable {
        /// 受条件访问控制策略管控 (CAC)
        case blockByFileStrategy
        /// 受精细化策略管控 (Admin)
        case blockBySecurityAudit
        /// 受 DLP 管控，DLP 检测中，暂无法确定是否可操作
        case blockByDLPDetecting
        /// 受 DLP 管控，DLP 检测到敏感内容
        case blockByDLPSensitive
        /// 受用户权限管控 (UserPermission)
        /// 可能包含更细分的失败原因，满足部分业务现有逻辑
        case blockByUserPermission(reason: UserPermissionDenyReason)
        /// 受用户权限管控时，具体的管控原因
        public enum UserPermissionDenyReason: Equatable {
            // TODO: 梳理清楚业务方的依赖现状，对齐现有逻辑
            /// UserPermission 尚未被准备好，如网络请求还没有返回，或 UserPermissionService 被析构
            case userPermissionNotReady
            /// 对应后端点位返回 2002 的场景
            case blockByCAC
            /// 其他受后端管控返回的值
            case blockByServer(code: Int)
            ///  不支持用缓存鉴权
            case cacheNotSupport
            /// 受文档审计管控，对应后端错误码 202
            case blockByAudit
            /// 其他原因，如点位没有查询
            case unknown
        }
    }

    /// 鉴权不通过时，建议的 UI 样式
    public enum PreferUIStyle: Equatable {
        /// 隐藏相关操作入口
        case hidden
        /// 置灰相关操作入口
        case disabled
        /// 没有偏好，业务自行处理或不做处理
        case `default`
    }

    public enum Result {
        /// 鉴权通过
        case allow
        /// 鉴权不通过，附带鉴权失败的原因和建议的 UI 样式
        case forbidden(denyType: DenyType, preferUIStyle: PreferUIStyle)
        /// 鉴权是否通过
        public var allow: Bool {
            switch self {
            case .allow:
                return true
            case .forbidden:
                return false
            }
        }

        public var needDisabled: Bool {
            guard case let .forbidden(_, style) = self else { return false }
            return style == .disabled
        }

        public var needHidden: Bool {
            guard case let .forbidden(_, style) = self else { return false }
            return style == .hidden
        }
    }

    public typealias Behavior = (UIViewController, String?) -> Void
}

/// 权限 SDK 鉴权请求的结果
public struct PermissionResponse {
    /// 鉴权结果
    public let result: Result
    /// 用户执行对应操作时，权限侧需要执行的操作，包括日志上报与权限 UI 弹窗，需要业务方执行
    private let behavior: Behavior
    /// 鉴权日志 ID
    public let traceID: String
    /// 鉴权是否通过
    public var allow: Bool {
        result.allow
    }

    public init(traceID: String, result: Result, behavior: @escaping Behavior) {
        self.traceID = traceID
        self.result = result
        self.behavior = behavior
    }

    public static func allow(traceID: String, behavior: @escaping Behavior) -> PermissionResponse {
        PermissionResponse(traceID: traceID, result: .allow, behavior: behavior)
    }

    public static func forbidden(traceID: String, denyType: DenyType, preferUIStyle: PreferUIStyle, behavior: @escaping Behavior) -> PermissionResponse {
        PermissionResponse(traceID: traceID,
                           result: .forbidden(denyType: denyType, preferUIStyle: preferUIStyle),
                           behavior: behavior)
    }
    
    /// 用户执行对应操作时，业务方需要调用此方法通知权限侧进行日志上报、UI 弹窗等逻辑, 因用户权限拦截时，会优先使用业务方传入的错误文案
    public func didTriggerOperation(controller: UIViewController, _ noPermissionMessage: String? = nil) {
        behavior(controller, noPermissionMessage)
    }
}
