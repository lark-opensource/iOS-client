//
//  ShareWithMeAction.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/5/22.
//  

import Foundation
import ReSwift
import SwiftyJSON
import SKCommon

/// 与我共享，分页拉取
struct AppendShareFileListAction: Action {
    let data: FileDataDiff
    let folderKey: DocFolderKey
    
    init(_ json: JSON, _ folderKey: DocFolderKey) {
        self.data = DataBuilder.getShareFileData(from: json)
        self.folderKey = folderKey
    }

    init(data: FileDataDiff, folderKey: DocFolderKey) {
        self.data = data
        self.folderKey = folderKey
    }
}

extension AppendShareFileListAction: StateUpdate {
    // 与我共享文件列表，上拉加载更多
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? AppendShareFileListAction {
            newState.appendShareFiles(action.data, action.folderKey)
        }
        return newState
    }
}



/// 与我共享，从头刷新
struct ResetShareFileListAction: Action {
    let data: FileDataDiff
    let folderKey: DocFolderKey

    init(_ json: JSON, _ folderKey: DocFolderKey) {
        self.data = DataBuilder.getShareFileData(from: json)
        self.folderKey = folderKey
    }

    init(data: FileDataDiff, _ folderKey: DocFolderKey) {
        self.data = data
        self.folderKey = folderKey
    }
}

extension ResetShareFileListAction: StateUpdate {
    // 与我共享，下拉刷新
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? ResetShareFileListAction {
            newState.resetShareFiles(action.data, action.folderKey)
        }
        return newState
    }
}

struct DeleteShareWithMeFileAction: Action {
    let token: FileListDefine.ObjToken
    init(_ token: String) {
        self.token = token
    }
}

extension DeleteShareWithMeFileAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? DeleteShareWithMeFileAction {
            newState.deleteShareFile(action.token)
        }
        return newState
    }
}
