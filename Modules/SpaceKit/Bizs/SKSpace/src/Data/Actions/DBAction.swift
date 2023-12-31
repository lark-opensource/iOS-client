//
//  DBAction.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/7/11.
//
//数据库也是Action，让Resource State 去处理

import Foundation
import ReSwift
import SKCommon


// MARK: - newDB
struct LoadNewDBDataAction: Action {
    let dbData: DBData
}

extension LoadNewDBDataAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if action is LoadNewDBDataAction {
            newState.udpateFromDBData(dbData)
        }
        return newState
    }
}

/// 加载子目录列表数据
struct LoadSubFolderEntriesAction: Action {
    let nodeToken: String
}

extension LoadSubFolderEntriesAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if action is LoadSubFolderEntriesAction {
            newState.loadSubFolderFileEntries(by: nodeToken)
        }
        return newState
    }
}

struct DeleteSubFolderEntriesAction: Action {
    let nodeToken: String
}

extension DeleteSubFolderEntriesAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if action is LoadSubFolderEntriesAction {
            newState.loadSubFolderFileEntries(by: nodeToken)
        }
        return newState
    }
}

/// 加载业务目录列表数据, 如个人空间、最近列表、快速访问、共享列表、手动离线、我的收藏等
struct LoadFolderEntriesAction: Action {
    let folderKey: DocFolderKey
    let limit: Int
}

extension LoadFolderEntriesAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if action is LoadFolderEntriesAction {
            newState.loadFolderEntries(folderKey: folderKey, limit: limit)
        }
        return newState
    }
}
