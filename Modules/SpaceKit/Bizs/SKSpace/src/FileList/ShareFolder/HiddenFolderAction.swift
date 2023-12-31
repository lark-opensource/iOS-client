//
//  HiddenFolderAction.swift
//  SKSpace
//
//  Created by majie.7 on 2022/2/22.
//

import Foundation
import ReSwift
import SwiftyJSON
import SKCommon


struct SetHiddenFolderAction: Action {
    let data: FileDataDiff
    
    init(data: FileDataDiff) {
        self.data = data
    }
}

extension SetHiddenFolderAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? SetHiddenFolderAction {
            newState.resetHiddenFolderV2(action.data)
        }
        return newState
    }
}

struct AppendHiddenFolderAction: Action {
    let data: FileDataDiff
    
    init(data: FileDataDiff) {
        self.data = data
    }
}

extension AppendHiddenFolderAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? AppendHiddenFolderAction {
            newState.appendHiddenFolderV2(action.data)
        }
        return newState
    }
}


struct UpdateHiddenStatusAction: Action {
    let nodeToken: FileListDefine.NodeToken
    let hidden: Bool
}

extension UpdateHiddenStatusAction: StateUpdate {
    // 共享文件夹，更新共享信息
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? UpdateHiddenStatusAction {
            newState.updateHiddenStatus(of: action.nodeToken, to: action.hidden)
        }
        return newState
    }
}

struct UpdateHiddenStatusV2Action: Action {
    let nodeToken: FileListDefine.NodeToken
    let hidden: Bool
}

extension UpdateHiddenStatusV2Action: StateUpdate {
    // 共享文件夹，更新共享信息
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? UpdateHiddenStatusV2Action {
            newState.updateHiddenStatusV2(of: action.nodeToken, to: action.hidden)
        }
        return newState
    }
}
