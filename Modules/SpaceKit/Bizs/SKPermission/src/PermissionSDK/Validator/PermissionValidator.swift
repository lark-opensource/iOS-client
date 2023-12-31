//
//  PermissionValidator.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
import SpaceInterface

// 为了单测可验证 Response，单独抽象一层
extension PermissionValidatorResponse {
    var allow: Bool {
        switch self {
        case .allow:
            return true
        case .forbidden:
            return false
        }
    }

    static func forbidden(denyType: PermissionResponse.DenyType,
                          defaultUIBehaviorType: PermissionDefaultUIBehaviorType) -> PermissionValidatorResponse {
        .forbidden(denyType: denyType,
                   preferUIStyle: denyType.preferUIStyle,
                   defaultUIBehaviorType: defaultUIBehaviorType)
    }

    static func forbidden(denyType: PermissionResponse.DenyType,
                          customAction: @escaping PermissionResponse.Behavior) -> PermissionValidatorResponse {
        return .forbidden(denyType: denyType, preferUIStyle: denyType.preferUIStyle, defaultUIBehaviorType: .custom(action: customAction))
    }

    static func forbidden(denyType: PermissionResponse.DenyType,
                          preferUIStyle: PermissionResponse.PreferUIStyle,
                          customAction: @escaping PermissionResponse.Behavior) -> PermissionValidatorResponse {
        return .forbidden(denyType: denyType, preferUIStyle: preferUIStyle, defaultUIBehaviorType: .custom(action: customAction))
    }
    // 省略回调场景使用
    static var pass: PermissionValidatorResponse {
        .allow {}
    }
}

protocol PermissionValidator: PermissionSDKValidator {
    func shouldInvoke(rules: PermissionExemptRules) -> Bool
}
