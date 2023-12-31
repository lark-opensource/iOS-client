//
//  UserPermissionUtils.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/17.
//

import Foundation
import SpaceInterface
import SKFoundation
import SKResource
import SwiftyJSON

enum UserPermissionUtils {
    static func defaultResponse(request: PermissionRequest) -> PermissionValidatorResponse {
        if let exemptRules = request.exemptConfig as? PermissionExemptRules,
           !exemptRules.shouldCheckUserPermission {
            // 识别到豁免逻辑，默认放行
            return .pass
        }
        return .forbidden(denyType: .blockByUserPermission(reason: .userPermissionNotReady),
                          defaultUIBehaviorType: defaultUIBehaviorType(request: request))
    }

    static func defaultUIBehaviorType(request: PermissionRequest) -> PermissionDefaultUIBehaviorType {
        let message = toastMessage(request: request)
        return .error(text: message, allowOverrideMessage: true)
    }

    static func toastMessage(request: PermissionRequest) -> String {
        // 用户权限失败通常业务方自行自定义错误文案
        return BundleI18n.SKResource.Doc_Facade_OperateFailedNoPermission
    }

    /// 从各类用户权限接口中解析 status code 和 applyUserInfo
    /// 如果发现除无权限外的其他错误，会直接原样抛出
    /// 返回 nil 则表示没有识别到无权限错误
    static func parseNoPermission<T>(json: JSON, permission: T?, error: Error?) throws -> UserPermissionAPIResult<T>? {
        guard let code = json["code"].int else {
            throw error ?? DocsNetworkError.invalidData
        }

        let data = json["data"]
        if code == DocsNetworkError.Code.forbidden.rawValue {
            let statusCodeValue = data["permission_status_code"].intValue
            let statusCode = UserPermissionResponse.StatusCode(rawValue: statusCodeValue)
            let ownerJSON = json["meta"]["owner"]
            guard ownerJSON["can_apply_perm"].boolValue,
                  let userID = ownerJSON["id"].string,
                  let userName = ownerJSON["name"].string else {
                return .noPermission(permission: permission, statusCode: statusCode, applyUserInfo: nil)
            }
            let aliasInfo = UserAliasInfo(json: ownerJSON["display_name"])
            let applyUserInfo = AuthorizedUserInfo(userID: userID, userName: userName, i18nNames: [:], aliasInfo: aliasInfo)
            return .noPermission(permission: permission, statusCode: statusCode, applyUserInfo: applyUserInfo)
        }

        guard code == 0 else {
            throw error ?? DocsNetworkError(code) ?? DocsNetworkError.invalidData
        }
        return nil
    }
}
