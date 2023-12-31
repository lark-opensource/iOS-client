//
//  DriveFollowModuleState.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/4/3.
//  

import Foundation
import SwiftyJSON
import SKCommon
import SpaceInterface

protocol DriveFollowModuleState {
    static var module: String { get }
    var actionType: String { get }
    var data: JSON { get }
    init?(data: JSON)
}

extension DriveFollowModuleState {
    var module: String {
        Self.module
    }
}

extension DriveFollowModuleState {

    init?(followModuleState: FollowModuleState) {
        self.init(data: followModuleState.data)
    }

    var followModuleState: FollowModuleState {
        return FollowModuleState(module: module, actionType: actionType, data: data)
    }
}
