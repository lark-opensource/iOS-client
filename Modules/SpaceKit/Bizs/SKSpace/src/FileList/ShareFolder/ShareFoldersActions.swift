//
//  ShareFoldersActions.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/5/21.
//  

import Foundation
import ReSwift
import SwiftyJSON
import SKCommon

struct SetShareFolderListAction: Action {
    let data: FileDataDiff

    init(data: FileDataDiff) {
        self.data = data
    }
}

extension SetShareFolderListAction: StateUpdate {
    // 共享文件夹，更新共享信息
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? SetShareFolderListAction {
            newState.resetShareFolder(action.data)
        }
        return newState
    }
}

// space2.0 共享文件夹列表信息
struct SetShareFolderListV2Action: Action {
    let data: FileDataDiff
    
    init(data: FileDataDiff) {
        self.data = data
    }
}

extension SetShareFolderListV2Action: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? SetShareFolderListV2Action {
            newState.resetShareFolderV2(action.data)
        }
        return newState
    }
}


// space2.0 共享文件夹分页拉取
struct AppendShareFolderListAction: Action {
    let data: FileDataDiff
    
    init(data: FileDataDiff) {
        self.data = data
    }
}

extension AppendShareFolderListAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? AppendShareFolderListAction {
            newState.appendShareFolderV2(action.data)
        }
        return newState
    }
}
