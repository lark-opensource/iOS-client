//
//  DLPCommonErrorHandler.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/25.
//

import Foundation
import SpaceInterface
import SKResource
import UniverseDesignToast

enum DLP {
    /// 后端检测所需最长耗时，单位: 秒
    static let DefaultDetectingCostTime: TimeInterval = 15 * 60

    /// 缓存的有效时间，单位: 秒
    static let DefaultTimeout: TimeInterval = 10 * 60

    enum ErrorCode: Int, Equatable {
        /// 本租户 DLP 策略检测中
        case sameTenantDetecting = 90099001
        /// 外部租户 DLP 策略检测中
        case externalTenantDetecting = 90099002
        /// 命中本租户 DLP 管控
        case sameTenantSensitive = 90099003
        /// 命中外部租户 DLP 管控
        case externalTenantSensitive = 90099004
    }
}

enum DLPCommonErrorHandler {
    static func getCommonErrorBehaviorType(token: String,
                                           userID: String,
                                           errorCode: DLP.ErrorCode) -> PermissionDefaultUIBehaviorType {
        let message: String
        switch errorCode {
        case .sameTenantDetecting, .externalTenantDetecting:
            // TODO: PermissionSDK 用户态改造后，找安全 SDK 要一个时间
            let maxCostTimeInSecond = DLP.DefaultDetectingCostTime
            let costTimeInMinute = Int(maxCostTimeInSecond / 60)
            message = BundleI18n.SKResource.LarkCCM_Docs_DLP_SystemChecking_Mob(costTimeInMinute)
        case .sameTenantSensitive:
            message = BundleI18n.SKResource.LarkCCM_Docs_DLP_SensitiveInfo_ActionFailed
        case .externalTenantSensitive:
            message = BundleI18n.SKResource.LarkCCM_Docs_DLP_Toast_ActionFailed
        }
        return .error(text: message, allowOverrideMessage: false)
    }
}
