//
//  AppendUserAction.swift
//  SpaceKit
//
//  Created by litao_dev on 2019/5/22.
//  

import Foundation
import ReSwift
import SwiftyJSON
import SKCommon

struct AppendUserAction: Action {
    let userJson: FileListDefine.Users
    init(_ json: [String: [String: Any]]) {
        self.userJson = json
    }
}

extension AppendUserAction: StateUpdate {
    // 权限所有者，新增
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState {
        var newState = state
        if let action = action as? AppendUserAction {
            newState.appendUsers(users: action.userJson)
        }
        return newState
    }
}
