//
//  PermissionSDKUtils.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/4/17.
//

import UIKit
import UniverseDesignToast
import SpaceInterface

enum PermissionSDKError: Error {
    case invalidOperation(reason: String)
}

enum PermissionSDKUtils {
    static func createDefaultUIBehavior(behaviorType: PermissionDefaultUIBehaviorType) -> PermissionResponse.Behavior {
        switch behaviorType {
        case let .toast(config, allowOverrideMessage, operationCallback, onTrigger):
            return { hostController, customNoPermissionMessage in
                onTrigger?()
                var config = config
                if allowOverrideMessage, let customNoPermissionMessage {
                    config.text = customNoPermissionMessage
                }
                UDToast.showToast(with: config,
                                  on: hostController.view.window ?? hostController.view,
                                  operationCallBack: operationCallback)
            }
        case let .present(controllerProvider):
            return { hostController, _ in
                let controller = controllerProvider()
                hostController.present(controller, animated: true)
            }
        case let .custom(action):
            return { hostController, overridePermissionMessage in
                action(hostController, overridePermissionMessage)
            }
        }
    }
}

extension PermissionValidatorResponse {
    func finalResponse(traceID: String) -> PermissionResponse {
        switch self {
        case let .allow(completion):
            return .allow(traceID: traceID) { _, _ in
                completion()
            }
        case let .forbidden(denyType, preferUIStyle, defaultUIBehaviorType):
            let beahvior = PermissionSDKUtils.createDefaultUIBehavior(behaviorType: defaultUIBehaviorType)
            return .forbidden(traceID: traceID, denyType: denyType, preferUIStyle: preferUIStyle, behavior: beahvior)
        }
    }
}

extension PermissionResponse {
    // 存在 forbidden 的 response 时，会取第一个返回
    static func merge(validatorResponses: [PermissionValidatorResponse], traceID: String) -> PermissionResponse {
        var completions: [() -> Void] = []
        for response in validatorResponses {
            switch response {
            case .allow(let completion):
                completions.append(completion)
            case .forbidden:
                return response.finalResponse(traceID: traceID)
            }
        }
        return .allow(traceID: traceID) { _, _ in
            completions.forEach { $0() }
        }
    }
    // 存在 forbidden 的 response 时，会取第一个返回
    static func merge(responses: [PermissionResponse], traceID: String) -> PermissionResponse {
        if let forbiddenResponse = responses.first(where: { !$0.allow }) {
            return forbiddenResponse
        }

        return .allow(traceID: traceID) { controller, customMessage in
            responses.forEach { $0.didTriggerOperation(controller: controller, customMessage) }
        }
    }
}
