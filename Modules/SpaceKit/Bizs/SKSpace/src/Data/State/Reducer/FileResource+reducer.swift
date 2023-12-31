//
//  FileResourceReducer.swift
//  FileResource
//
//  Created by weidong fu on 22/1/2018.
//

import ReSwift
import SKFoundation

extension FileResource {
    class func fileResourceReducer(action: Action, state: ResourceState?) -> ResourceState {
        spaceAssert("\(type(of: action))".hasSuffix("Action"), "所有Action取名必须以Action结尾")
        checkStateStatusBeforeReducer(state)
//        DocsLogger.info("get action \(action)")
        var newState = state ?? ResourceState()
        newState.stateUpdateCount += 1
        newState.currentAction = action
        return action.fileResourceReducer(action: action, state: newState)
    }

    private class func checkStateStatusBeforeReducer(_ state: ResourceState?) {
        spaceAssert(state != nil)
        guard let state = state else {
            return
        }
        var actionName = ""
        if let lastAction = state.currentAction {
            actionName = "\(type(of: lastAction))"
            }
        spaceAssert(state.stateUpdateCount == state.updateUserFileCount,
                    "有一次处理 Action 没有调用 updateUserFile, 上一个处理的 Action 是 \(actionName), \(state.stateUpdateCount) not equal \(state.updateUserFileCount)")
    }
}
