//
//  PermissionPushHandler.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/12/28.
//

import RustPB
import LarkRustClient
import LKCommonsLogging
import UniverseDesignToast
import EENavigator
import LarkNavigator

final class PermissionPushHandler: UserPushHandler {

    typealias PushType = Passport_V1_PushPermissionResponse

    static let logger = Logger.log(PermissionPushHandler.self, category: "SecurityAudit.PermissionPushHandler")

    func process(push: Passport_V1_PushPermissionResponse) throws {
        Self.logger.info("receive permission push")
        SecurityAuditManager.shared.pullPermissionService?.fetchPermission(.push)
    }
}
