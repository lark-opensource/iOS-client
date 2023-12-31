//
//  DrivePermissionMocker.swift
//  DocsTests
//
//  Created by bupozhuang on 2019/12/2.
//  Copyright © 2019 Bytedance. All rights reserved.
//

import UIKit
@testable import SpaceKit

class DrivePermissionMocker: DrivePermissionHelperProtocol {
    private var startFetch: (() -> Void)?
    private var permissionChanged: PermissionChangedBlock?
    private var failed: ((Error) -> Void)?
    private var successed: Bool = true
    private var permissionInfo: DrivePermissionInfo = DrivePermissionInfo(isReadable: true,
                                                                          isEditable: false,
                                                                          canComment: false,
                                                                          canExport: false,
                                                                          canCopy: false,
                                                                          permissionStatusCode: nil,
                                                                          userPermissions: nil)

    func startMonitorPermission(startFetch: @escaping() -> Void,
                                permissionChanged: @escaping PermissionChangedBlock,
                                failed: @escaping (Error) -> Void) {
        self.startFetch = startFetch
        self.permissionChanged = permissionChanged
        self.failed = failed
        self.startFetch?()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.successed {
                self.permissionChanged?(self.permissionInfo)
            } else {
                let error = NSError(domain: "unit.test", code: 8, userInfo: ["test": "unittest"])
                self.failed?(error as Error)
            }
        }
    }

    // config mocker
    func config(success: Bool, permissionInfo: DrivePermissionInfo) {
        self.successed = success
        self.permissionInfo = permissionInfo
    }
    func changePermission(_ permissionInfo: DrivePermissionInfo) {
        self.permissionInfo = permissionInfo
        self.permissionChanged?(permissionInfo)
    }
}
