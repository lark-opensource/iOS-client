//
//  DriveDynamicPermissionProtocol.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/13.
//  

import Foundation

@available(*, deprecated, message: "To be refactor by PermissionSDK - PermissionSDK")
protocol DriveDynamicPermissionProtocol {
    func update(permission: DrivePermissionInfo)
}
