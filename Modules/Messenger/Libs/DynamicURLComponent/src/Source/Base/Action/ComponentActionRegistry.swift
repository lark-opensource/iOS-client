//
//  ComponentActionRegistry.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/9/2.
//

import Foundation
import RustPB
import LarkModel
import LKCommonsLogging

public typealias ActionCompletionHandler = (Error?) -> Void

/// 负责Action注册 & 处理
public final class ComponentActionRegistry {
    static let logger = Logger.log(ComponentActionRegistry.self, category: "DynamicURLComponent.ComponentActionRegistry")
    // 防止递归调用action
    static let maxDepth = 10

    static let handlers: [Basic_V1_UrlPreviewAction.Method: ActionBaseHandler.Type] = [
        .get: NetActionHandler.self,
        .post: NetActionHandler.self,
        .larkCommand: NetActionHandler.self,
        .openURL: OpenURLActionHandler.self,
        .switchState: SwitchStateActionHandler.self,
        .showToast: ShowToastActionHandler.self,
        .showDialog: ShowDialogActionHandler.self
    ]

    public static func handleAction(entity: URLPreviewEntity?,
                                    action: Basic_V1_UrlPreviewAction,
                                    actionID: String,
                                    dependency: URLCardDependency,
                                    completion: ActionCompletionHandler? = nil,
                                    actionDepth: Int = 1) {
        guard let handler = handlers[action.method], actionDepth < maxDepth else {
            logger.error("can not handle action for \(action.method) -> \(actionDepth)")
            completion?(NSError(domain: "can not handle action for \(action.method)", code: -1, userInfo: nil))
            return
        }
        handler.handleAction(entity: entity,
                             action: action,
                             actionID: actionID,
                             dependency: dependency,
                             completion: completion,
                             actionDepth: actionDepth)
    }
}
