//
//  MGFeatureGatingResponse.swift
//  LarkMeego
//
//  Created by mzn on 2022/10/5.
//

import Foundation
import LarkFoundation
import LarkMeegoNetClient

struct MGFeatureGatingResponse: Codable {
    let result: [MGFeatureGatingModel]?

    // 获取请求和响应中FG的数据变化
    var enabledFeatures: [String] {
        if let result = result {
            return result
                .flatMap({
                    $0.features.map { $0 }
                })
                .filter({
                    $0.isHit && $0.exist
                })
                .map { $0.key }
        } else {
            return []
        }
    }

    // 服务端的返回数据
    var fgJsonInfos: [MGFeatureGatingKeyInfo] {
        if let result = result {
            return result
                .flatMap({
                    $0.features.map { $0 }
                })
        } else {
            return []
        }
    }

    private enum CodingKeys: String, CodingKey {
        case result = "result"
    }
}

/// Model
struct MGFeatureGatingModel: Codable {
    let input: MGFeatureGatingInput
    let features: [MGFeatureGatingKeyInfo]

    private enum CodingKeys: String, CodingKey {
        case input = "input"
        case features = "features"
    }
}

struct MGFeatureGatingInput: Codable {
    let meegoUserKey: String?
    let meegoTenantKey: String?
    let platform: String?
    let version: String?

    private enum CodingKeys: String, CodingKey {
        case meegoUserKey = "meego_user_key"
        case meegoTenantKey = "meego_tenant_key"
        case platform = "platform"
        case version = "version"
    }
}

struct MGFeatureGatingKeyInfo: Codable {
    let key: String
    let isHit: Bool
    let exist: Bool

    private enum CodingKeys: String, CodingKey {
        case key = "key"
        case isHit = "is_hit"
        case exist = "exist"
    }
}
