//
//  Action+UpdateSateHandler.swift
//  FileResource
//
//  Created by weidong fu on 22/1/2018.
//

import ReSwift
import SwiftyJSON

public protocol StateUpdate {
    func fileResourceReducerToUpdateState(action: Action, state: ResourceState) -> ResourceState
}

extension Action {
    func fileResourceReducer(action: Action, state: ResourceState) -> ResourceState {
        // do nothing
        if let self = self as? StateUpdate {
            return self.fileResourceReducerToUpdateState(action: action, state: state)
        } else {
            fatalError("must be state Update")
        }
    }
}

/*
 1、此文件不在新增 业务action的定义，新增定义请放到自己业务模块的Actions文件夹中
 2、可参考RecentFileActions.swift
 */
