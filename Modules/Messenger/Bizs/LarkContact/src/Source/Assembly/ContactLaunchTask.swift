//
//  ContactLaunchTask.swift
//  LarkContact
//
//  Created by KT on 2020/7/8.
//

import Foundation
import BootManager
import LarkAccountInterface
import LarkContainer
import LarkTourInterface
import LarkMessengerInterface

final class NewContactLaunchTask: UserFlowBootTask, Identifiable {
    static var identify = "ContactLaunchTask"

    @ScopedInjectedLazy private var resourceService: DynamicResourceService?

    override func execute(_ context: BootContext) {
        guard let contactInviteInfoService = try? userResolver.resolve(assert: ContactInviteInfoService.self) else { return }
        contactInviteInfoService.fetchInviteInfo()
        contactInviteInfoService.fetchTenantCreateGuide()
        contactInviteInfoService.setAvatarObserver()
        contactInviteInfoService.trackPushNotificationStatus()

        // 预加载配置，包括邀请码动图地址等
        // TCC: https://lark-devops.bytedance.net/page/configuration/edit/763/6041?env=online&unit=cn&confSpace=default
        let statusKey = "guide_config_status"
        let resourceKey = "guide_config_data"
        resourceService?.preload(
            statusKeys: [statusKey],
            resourceKeys: [resourceKey]
        )
    }
}
