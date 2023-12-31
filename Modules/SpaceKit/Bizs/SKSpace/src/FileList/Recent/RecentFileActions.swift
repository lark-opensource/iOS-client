//
//  RecentFileAction.swift
//  Alamofire
//
//  Created by litao_dev on 2019/5/21.
//

import Foundation
import ReSwift
import SwiftyJSON
import SKCommon
import SKFoundation

// 根据token删除本地最近浏览
struct DeleteRecentFileAction: Action {
    let tokens: [FileListDefine.ObjToken]
}

extension DeleteRecentFileAction: StateUpdate {
    // 删除最近浏览的文件
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? DeleteRecentFileAction {
            let encryptedTokens = action.tokens.map { DocsTracker.encrypt(id: $0) }.joined(separator: ",")
            DocsLogger.info("delete Recent files \(encryptedTokens)", component: LogComponents.dataModel)
            newState.deleteRecentFile(action.tokens)
        }
        return newState
    }
}

/// 定义action，用于封装请求回来的reponseJson，dict--> model,做数据流转用
struct ResetRecentFileListOldAction: Action {
    let data: FileDataDiff
    let folderKey: DocFolderKey

    init(data: FileDataDiff, folderKey: DocFolderKey) {
        self.data = data
        self.folderKey = folderKey
    }
}

/// 遵守UpdateState协议，实现协议方法，解决当前业务场景，需要将什么数据更新到state上
extension ResetRecentFileListOldAction: StateUpdate {
    // 最近浏览 下拉刷新
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? ResetRecentFileListOldAction {
            newState.resetRecentFilesOld(action.data, action.folderKey)
        }
        return newState
    }
}

struct AppendRecentFileListOldAction: Action {
    let data: FileDataDiff
    let folderKey: DocFolderKey

    init(data: FileDataDiff, folderKey: DocFolderKey) {
        self.data = data
        self.folderKey = folderKey
    }
}

extension AppendRecentFileListOldAction: StateUpdate {
    // 最近浏览，上拉加载
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? AppendRecentFileListOldAction {
            newState.updateRecentFilesOld(action.data, action.folderKey)
        }
        return newState
    }
}

// 用于将server的数据合并到本地，更新数据，重新排序
struct MergeRecentFilesAction: Action {
    let data: FileDataDiff
    let folderKey: DocFolderKey
    init(data: FileDataDiff, folderKey: DocFolderKey) {
        self.data = data
        self.folderKey = folderKey
    }
}

extension MergeRecentFilesAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? MergeRecentFilesAction {
            newState.mergeRecentFiles(data: action.data, action.folderKey)
        }
        return newState
    }
}

struct ResetRecentFilesByTokensAction: Action {
    let tokens: [String]
    let folderKey: DocFolderKey
}

extension ResetRecentFilesByTokensAction: StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        guard let action = action as? ResetRecentFilesByTokensAction else { return state }
        var newState = state
        newState.resetRecentFiles(tokens: action.tokens, action.folderKey)
        return newState
    }
}
