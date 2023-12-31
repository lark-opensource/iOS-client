//
//  MGFeatureGatingRequest.swift
//  LarkMeego
//
//  Created by mzn on 2022/10/5.
//

import Foundation
import LarkFoundation
import LarkMeegoNetClient

// 多组合参数获取 FG Key <https://yapi.bytedance.net/project/3456/interface/api/1462542>
struct MGFeatureGatingRequest: Request {
    typealias ResponseType = Response<MGFeatureGatingResponse>

    let method: RequestMethod = .post
    let endpoint: String = "/m-api/v1/settings/fg"
    var catchError: Bool

    let appName: String
    let meegoUserKey: String
    let meegoTenantKey: String
    let meegoProjectKey: String?
    let keys: [String]
    let platform: String
    let version: String

    var parameters: [String: Any] {
        var params: [String: Any] = [:]
        var univasalInput: [String: Any] = [:]
        univasalInput["platform"] = platform
        univasalInput["meego_user_key"] = meegoUserKey
        univasalInput["meego_tenant_key"] = meegoTenantKey
        univasalInput["version"] = version
        if let projectKey = meegoProjectKey, !projectKey.isEmpty {
            univasalInput["meego_project_key"] = projectKey
        }

        var keyFilterCondition: [String: Any] = [:]
        keyFilterCondition["app"] = appName
        if !keys.isEmpty {
            keyFilterCondition["keys"] = keys
        }
        params["inputs"] = [univasalInput]
        params["key_filter_condition"] = keyFilterCondition
        return params
    }
}
