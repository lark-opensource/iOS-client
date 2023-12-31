//
//  QuickAccessActions.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/5/22.
//  

import Foundation
import ReSwift
import SwiftyJSON
import SKCommon

/// Pins列表，获取
struct ResetPinsAction: Action {
    let data: FileDataDiff
    let folderKey: DocFolderKey
}

extension ResetPinsAction: StateUpdate {
    //  快速访问的首页拉取
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? ResetPinsAction {
            newState.resetPins(action.data, action.folderKey)
        }
        return newState
    }
}

struct UpdatePinAction: Action {
    let objToken: FileListDefine.ObjToken
    let isPined: Bool
}

extension UpdatePinAction: StateUpdate {
    // 修改快速访问状态
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? UpdatePinAction {
           newState.changePinsStatus(objToken: action.objToken, isPined: action.isPined)
        }
        return newState
    }
}
