//
//  FileListActions.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/5/22.
//  

import Foundation
import ReSwift
import SwiftyJSON
import SKFoundation
import SKCommon
import SpaceInterface

public struct DeleteFileByTokenAction: Action {
    let token: TokenStruct
    public init(token: TokenStruct) {
        self.token = token
    }
}

extension DeleteFileByTokenAction: StateUpdate {
    public func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        guard let action = action as? DeleteFileByTokenAction else { return state }
        newState.deleteByToken(action.token)
        return newState
    }
}

public struct DeleteFileAction: Action {
    var file: FileListDefine.NodeToken
    var folder: FileListDefine.NodeToken
    public init(file: FileListDefine.NodeToken, folder: FileListDefine.NodeToken) {
        self.file = file
        self.folder = folder
    }
}

extension DeleteFileAction: StateUpdate {
    public func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? DeleteFileAction {
            newState.delete(action.file, in: action.folder)
        }
         return newState
    }
}

struct InsertFakeFileAction: Action {
    let fakeFileEntry: SpaceEntry
    let folder: FileListDefine.NodeToken
}

extension InsertFakeFileAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if action is InsertFakeFileAction {
            newState.insertFakeFileEntry(fakeFileEntry, to: folder)
        }
         return newState
    }
}

/// 本地创建的文档成功同步到了后台
struct ReplaceFakeTokenAction: Action {
    let fileEntry: SpaceEntry
    let newObjToken: FileListDefine.ObjToken
    let newNodeToken: FileListDefine.NodeToken
}

extension ReplaceFakeTokenAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? ReplaceFakeTokenAction {
            newState.replaceOldFileEntry(fileEntry: fileEntry, newObjToken: action.newObjToken, newNodeToken: action.newNodeToken)
        }
        return newState
    }
}

public struct RenameFileAction: Action {
    let objToken: String
    let newName: String
    public init(objToken: String, _ newName: String) {
        self.objToken = objToken
        self.newName = newName
    }
}

extension RenameFileAction: StateUpdate {
    public func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? RenameFileAction {
            newState.rename(key: action.objToken, with: action.newName)
        }
         return newState
    }
}

public struct RenameShortCutFileAction: Action {
    let token: String
    let newName: String
    public init(token: String, _ newName: String) {
        self.token = token
        self.newName = newName
    }
}

extension RenameShortCutFileAction: StateUpdate {
    public func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? RenameShortCutFileAction {
            newState.rename(key: action.token, with: action.newName)
        }
         return newState
    }
}


public struct MoveFileAction: Action {
    var file: FileListDefine.NodeToken
    var from: FileListDefine.NodeToken
    var to: FileListDefine.NodeToken
    public init(file: FileListDefine.NodeToken, from: FileListDefine.NodeToken, to: FileListDefine.NodeToken) {
        self.file = file
        self.from = from
        self.to = to
    }
}

extension MoveFileAction: StateUpdate {
    public func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? MoveFileAction {
            newState.move(action.file, from: action.from, to: action.to)
        }
         return newState
    }
}

public struct TrashDeleteFileAction: Action {
    var file: String
    var folder: String
    public init(file: String, folder: String) {
        self.file = file
        self.folder = folder
    }
}

extension TrashDeleteFileAction: StateUpdate {
    public func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? TrashDeleteFileAction {
            newState.delete(action.file, in: action.folder)
        }
         return newState
    }
}

public struct TrashRestoreFileAction: Action {
    let file: String
    let folder: String
    public init(file: String, folder: String) {
        self.file = file
        self.folder = folder
    }
}

extension TrashRestoreFileAction: StateUpdate {
    public func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? TrashRestoreFileAction {
            newState.delete(action.file, in: action.folder)
        }
         return newState
    }
}

/*
 (litao_dev).(todo)
 暂时放在这里，后续重构中移走
 */
public struct NeedSyncAction: Action {
    let objToken: FileListDefine.ObjToken
    let type: DocsType
    let needSync: Bool

    public init(objToken: FileListDefine.ObjToken, type: DocsType, needSync: Bool) {
        self.objToken = objToken
        self.type = type
        self.needSync = needSync
    }
}

extension NeedSyncAction: StateUpdate {
    // 暂定，搜索：dispatch(NeedSync，出现在离线，创建引导，编辑管理中，都调用了filesource.dispatch
    public func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? NeedSyncAction {
            newState.set(needSync: action.needSync, objToken: action.objToken, type: type)
            DocsLogger.info("need sync action: token=\(action.objToken.encryptToken), needSync=\(action.needSync)")
        }
        return newState
    }
}

struct UpdateMyEditTimeAction: Action, StateUpdate {
    let objToken: FileListDefine.ObjToken
    let editTime: TimeInterval
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if action is UpdateMyEditTimeAction {
            newState.updateMyEditTime(editTime, for: objToken)
        }
        return newState
    }
}

/// 用了同步数据的，执行完这个以后，在block里会取到最新信息
struct DummyAction: Action, StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if action is DummyAction {
            newState.onDummyAction()
        }
        return newState
    }
}

public struct UpdateSecretAction: Action {
    let objToken: String
    let newName: String
    public init(objToken: String, _ newName: String) {
        self.objToken = objToken
        self.newName = newName
    }
}

extension UpdateSecretAction: StateUpdate {
    public func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? UpdateSecretAction {
            newState.updateSecret(key: action.objToken, with: action.newName)
        }
         return newState
    }
}

struct InsertUploadFileAction: Action, StateUpdate {
    let entry: SpaceEntry
    let parentFolderToken: String

    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? InsertUploadFileAction {
            newState.insertUploadFileEntry(fileEntry: action.entry, folderToken: parentFolderToken)
        }
        return newState
    }
}

struct InsertUploadWikiAction: Action, StateUpdate {
    let entry: SpaceEntry

    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? InsertUploadWikiAction {
            newState.insertUploadWikiEntry(fileEntry: entry)
        }
        return newState
    }
}
