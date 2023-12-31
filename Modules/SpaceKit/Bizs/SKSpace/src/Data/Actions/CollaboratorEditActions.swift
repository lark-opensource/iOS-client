//
//  CollaboratorEditActions.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/5/22.
//  

import Foundation
import ReSwift
import SwiftyJSON
import SKFoundation
import SKCommon

struct TransferOwnerAction: Action {
    let token: FileListDefine.ObjToken
    let newOwner: FileListDefine.UserID
    let isFolder: Bool
    init (token: String, newOwner: String, isFolder: Bool) {
        self.token = token
        self.newOwner = newOwner
        self.isFolder = isFolder
    }
}

extension TransferOwnerAction: StateUpdate {
    // CollaboratorEdit，转移所有者
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? TransferOwnerAction {
            newState.transfer(action.token, to: action.newOwner)
        } else {
            spaceAssertionFailure()
        }
        return newState
    }
}

struct RemoveFileShareInfoAction: Action {
    let fileToken: FileListDefine.NodeToken
}

extension RemoveFileShareInfoAction: StateUpdate {
    // CollaboratorEdit，移除文件共享信息
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? RemoveFileShareInfoAction {
            newState.removeShareFolderInfo(folderNodeToken: action.fileToken)
        } else {
            spaceAssertionFailure()
        }
        return newState
    }
}
