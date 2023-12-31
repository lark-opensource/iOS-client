//
//  FavoritesActions.swift.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/5/21.
//  

import Foundation
import ReSwift
import SwiftyJSON
import SKCommon

/// 收藏，从头刷新
struct ResetFavoritesAction: Action {
    let data: FileDataDiff
    let folderKey: DocFolderKey
}

extension ResetFavoritesAction: StateUpdate {
    // 收藏，下拉刷新
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? ResetFavoritesAction {
            newState.resetFavorites(action.data, folderKey: action.folderKey)
        }
        return newState
    }
}

/// 收藏，分页拉取
struct UpdateFavoritesAction: Action {
    let data: FileDataDiff
    let folderKey: DocFolderKey
}

extension UpdateFavoritesAction: StateUpdate {
    // 收藏，上拉加载更多
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? UpdateFavoritesAction {
            newState.appendFavorites(action.data, folderKey: action.folderKey)
        }
        return newState
    }
}

struct UpdateFileStarValueInAllListAction: Action {
    let objToken: FileListDefine.ObjToken
    let isStared: Bool
}

extension UpdateFileStarValueInAllListAction: StateUpdate {
    // 收藏，刷新所有
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? UpdateFileStarValueInAllListAction {
            newState.changeStarStatus(action.objToken, isStared: action.isStared)
        }
        return newState
    }
}
