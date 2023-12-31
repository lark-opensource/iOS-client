//
//  PersonalFilesActions.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/5/22.
//  

import Foundation
import ReSwift
import SwiftyJSON
import SKCommon
import SKFoundation

struct V2UpdateFileExternalAction: Action {
    let info: [FileListDefine.ObjToken: Bool]
}

extension V2UpdateFileExternalAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? V2UpdateFileExternalAction {
            newState.updateFileEntryExternal(info: action.info)
        }
        return newState
    }
}

struct V2SetRootFileAction: Action {
    let data: FileDataDiff
}

extension V2SetRootFileAction: StateUpdate {
    // 我的文档，设置root文件
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? V2SetRootFileAction {
            newState.resetFilesForOneFolder(action.data)
        }
        return newState
    }
}

struct AppendFileListAction: Action {
    let data: FileDataDiff
}

extension AppendFileListAction: StateUpdate {
    // 我的文档，上拉加载更多
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? AppendFileListAction {
            newState.appendFilesToFolder(action.data)
        }
        return newState
    }
}

struct UpdatePersionalFilesListAction: Action {
    let data: FileDataDiff
    let folderKey: DocFolderKey
}

extension UpdatePersionalFilesListAction: StateUpdate {
    // 我的文档，设置root文件
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? UpdatePersionalFilesListAction {
            spaceAssert(DocFolderKey.personalListKeys.contains(action.folderKey))
            newState.resetPersonalFiles(action.data, folderKey: action.folderKey)
        }
        return newState
    }
}

struct AppendPersionalFilesListAction: Action {
    let data: FileDataDiff
    let folderKey: DocFolderKey
}

extension AppendPersionalFilesListAction: StateUpdate {
    // 我的文档，上拉加载更多
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? AppendPersionalFilesListAction {
            spaceAssert(DocFolderKey.personalListKeys.contains(action.folderKey))
            newState.appendPersonalFiles(action.data, folderKey: action.folderKey)
        }
        return newState
    }
}

// 根据token删除本地personal 的内容某篇文档
struct DeletePersonFileAction: Action {
    let token: FileListDefine.ObjToken
}

extension DeletePersonFileAction: StateUpdate {
    // 删除个人文档
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? DeletePersonFileAction {
            newState.deletePersonalFile(action.token)
        }   
        return newState
    }
}
