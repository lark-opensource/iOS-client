//
//  DriveAttachmentPermissionHelper.swift
//  SpaceKit
//
//  Created by liweiye on 2020/6/23.
//

import Foundation
import SKCommon

class DriveAttachmentPermissionHelper: DrivePermissionHelper {

    // Drive 附件不需要请求 public permissions
    override func startMonitorPermission(startFetch: @escaping () -> Void, permissionChanged: @escaping PermissionChangedBlock, failed: @escaping (PermissionResponseModel) -> Void) {
        permissionObserver = PermissionObserver(fileToken: fileToken, type: type.rawValue)
        permissionObserver?.addObserveForPermission(delegate: self, observeKey: .all)
        permissionChangedBlock = permissionChanged
        failedBlock = failed
        startFetchBlock = startFetch
        if isReachable {
            fetchUserPermission()
        }
    }
}
