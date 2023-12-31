//
//  SwitchStateActionHandler.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/11/30.
//

import Foundation
import RustPB
import LarkModel

public struct SwitchStateActionHandler: ActionBaseHandler {
    public static func handleAction(entity: URLPreviewEntity?,
                                    action: Basic_V1_UrlPreviewAction,
                                    actionID: String,
                                    dependency: URLCardDependency,
                                    completion: ActionCompletionHandler?,
                                    actionDepth: Int) {
        assert(action.method == .switchState, "invalidate method")
        assertionFailure("not supported")
        // dependency.switchToState(stateID: action.switchState.nextStateID)
        completion?(nil)
    }
}
