//
//  DynamicBrandPushHandler.swift
//  LarkDynamicResource
//
//  Created by 王元洵 on 2023/4/3.
//

import Foundation
import ServerPB
import LarkRustClient
import LarkAccountInterface

final class DynamicBrandPushHandler: UserPushHandler {
    func process(push message: ServerPB_Brand_PushTenantBuildResourceRequest) throws {
        guard let tenantID = userResolver.resolve(PassportUserService.self)?.userTenant.tenantID, tenantID == message.tenantID,
              let buildResource = message.buildResources.filter({ $0.platform == .ios }).first else { return }

        DynamicBrandManager.fetchResource(with: buildResource.resourceURL, taskID: buildResource.taskID, tenantID: tenantID)
    }
}
