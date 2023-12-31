//
//  PushBannerNotificationHandler.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/27.
//

import Foundation
import LarkRustClient
import ServerPB
import LarkContainer
import ECOProbe
import LKCommonsLogging
import LarkFeatureGating

struct BannerNotificationPullData: PushMessage {
}

class BannerNotificationPullDataHandler: BaseRustPushHandler<ServerPB_Open_banner_OpenBannerPushResponse> {
    private let pushCenter: PushNotificationCenter

    init(pushCenter: PushNotificationCenter) {
        self.pushCenter = pushCenter
    }

    override func doProcessing(message: ServerPB_Open_banner_OpenBannerPushResponse) {
        openBannerLogger.info("PushBannerNotificationHandler.doProcessing.")
        self.pushCenter.post(BannerNotificationPullData())
    }
}
