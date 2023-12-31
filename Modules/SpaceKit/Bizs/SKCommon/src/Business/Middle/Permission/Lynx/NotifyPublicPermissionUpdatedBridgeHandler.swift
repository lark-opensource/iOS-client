//
//  NotifyPublicPermissionUpdatedBridgeHandler.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/4/26.
//

import Foundation
import BDXBridgeKit
import BDXServiceCenter
import SKFoundation

class NotifyPublicPermissionUpdatedBridgeHandler: BridgeHandler {

    let methodName = "ccm.permission.notifyPublicPermissionUpdated"
    let handler: BDXLynxBridgeHandler = { (_, _, _, callback) in
        NotificationCenter.default.post(name: Notification.Name.Docs.publicPermissonUpdate, object: nil)
    }
}
