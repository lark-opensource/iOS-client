//
//  SecurityPolicyCommonErrorHandler.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/25.
//

import Foundation
import SpaceInterface
import SKResource

enum SecurityPolicyCommonErrorHandler {

    static let commonErrorCode = 900099011

    static func getCommonErrorBehaviorType() -> PermissionDefaultUIBehaviorType {
        // 现在不做任何事情，安全 SDK 会在网络层识别后弹窗
        return .custom { _, _ in }
    }
}
