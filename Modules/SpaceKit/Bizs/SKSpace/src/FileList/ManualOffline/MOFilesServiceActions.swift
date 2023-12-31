//
//  MOFilesServiceActions.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/8/23.
//  

import Foundation
import SKCommon
import ReSwift

/// 列表操作action
struct ResetManualOfflineTagAction: Action {
    let objToken: FileListDefine.ObjToken
    let isSetManuOffline: Bool
}

extension ResetManualOfflineTagAction: StateUpdate {
    // 我的文档，error
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? ResetManualOfflineTagAction {
            newState.resetManualOfflineTag(of: action.objToken, to: action.isSetManuOffline)
        }
        return newState
    }
}

struct UpdateFileSizeAction: Action {
    let objToken: FileListDefine.ObjToken
    let fileSize: UInt64
}

extension UpdateFileSizeAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? UpdateFileSizeAction {
            newState.updateFileSize(of: action.objToken, fileSize: action.fileSize)
        }
        return newState
    }
}

/// 文档详情页操作action
struct ResetMOFileFromDetailPage: Action {
    let entry: SpaceEntry
    let isSetManuOffline: Bool
}

extension ResetMOFileFromDetailPage: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? ResetMOFileFromDetailPage {
            newState.resetMOFileFromDetailPage(of: action.entry, to: action.isSetManuOffline)
        }
        return newState
    }
}
