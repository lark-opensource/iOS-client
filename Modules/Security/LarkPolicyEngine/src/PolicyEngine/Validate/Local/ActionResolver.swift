//
//  ActionResolver.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/11/22.
//

import Foundation

enum ActionResolver {
    static let derivationMap: [String: [String: String]] = [
        KnownAction.fileBlockCommon.rawValue: [
            "entity_operation": "entityOperate",
            "file_biz_domain": "fileBizDomain"
        ],
        KnownAction.dlpContentDetecting.rawValue: [:],
        KnownAction.dlpContentSensitive.rawValue: [:],
        KnownAction.ttBlock.rawValue: [:],
        KnownAction.universalFallbackCommon.rawValue: [:],
        KnownAction.fallbackCommon.rawValue: [:]
    ]

    static func resolve(action: ActionName, request: ValidateRequest) throws -> Action {
        guard let derivation = derivationMap[action] else {
            throw ActionResolverError("Action resolve failed, action name:\(action)")
        }
        var params = [String: Any]()
        for (key, path) in derivation {
            params[key] = (request.entityJSONObject as NSDictionary).value(forKeyPath: path)
        }
        return Action(name: action, params: params)
    }
}
