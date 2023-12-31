//
//  SpaceActions.swift
//  SKCommon
//
//  Created by guoqp on 2020/7/1.
//

import Foundation
import ReSwift
import SKCommon
import SKFoundation

// 用于补偿添加SpaceEntry到allFileEntries中
struct AddFileEntriesAction: Action {
    let files: [SpaceEntry]
    init(_ files: [SpaceEntry]) {
        self.files = files
    }
}
extension AddFileEntriesAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? AddFileEntriesAction {
            newState.addFileEntries(action.files)
        }
        return newState
    }
}

// add a file
struct AddFileAction: Action {
    let file: SpaceEntry
    init(_ file: SpaceEntry) {
        self.file = file
    }
}
extension AddFileAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? AddFileAction {
            newState.addAFileToAllEntries(action.file)
        }
        return newState
    }
}

// update custom icon
extension UpdateIconInfoToFileEntryAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? UpdateIconInfoToFileEntryAction {
            newState.updateIconInfoWith(action.objToken, customIcon: action.customIcon)
        }
        return newState
    }
}
struct UpdateIconInfoToFileEntryAction: Action {
    let customIcon: CustomIcon
    let objToken: FileListDefine.ObjToken
}

// 精简模式清理用
struct DeleteFileEntryByObjTokensAction: Action {
    let files: [SimpleModeWillDeleteFile]
    init(_ files: [SimpleModeWillDeleteFile]) {
        self.files = files
    }
}

extension DeleteFileEntryByObjTokensAction: StateUpdate {
    // 删除所有列表中的objTokens，并触发DB更新和删除
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? DeleteFileEntryByObjTokensAction {
            newState.deleteFilesInSimpleMode(action.files)
        }
        return newState
    }
}

/// 离线同步过程中UI的刷新状态变更
public struct SyncUIModifierAction: Action {
    let tokenInfos: [FileListDefine.ObjToken: SyncStatus]
    public init(tokenInfos: [FileListDefine.ObjToken: SyncStatus]) {
        self.tokenInfos = tokenInfos
    }
}
extension SyncUIModifierAction: StateUpdate {
    public func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? SyncUIModifierAction {
            DocsLogger.debug("SyncUIModifierAction \(action)")
            newState.updateSyncStatus(tokenInfos: action.tokenInfos)
        }
        return newState
    }
}

public struct ResetManuOfflineStatusAction: Action {
    let token: String
    public init(token: String) {
        self.token = token
    }
}

extension ResetManuOfflineStatusAction: StateUpdate {
    public func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? ResetManuOfflineStatusAction {
            DocsLogger.debug("ResetManuOfflineStatusAction \(action)")
            newState.resetManuOfflineStatus(by: action.token)
        }
        return newState
    }
}
