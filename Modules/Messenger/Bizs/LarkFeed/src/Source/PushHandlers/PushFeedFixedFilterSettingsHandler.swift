//
//  PushFeedFixedFilterSettingsHandler.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/4/25.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel

extension FeedThreeColumnSettingModel: PushMessage {}

final class PushFeedFixedFilterSettingsHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Feed_V1_PushThreeColumnsSetting) throws {
        guard let pushCenter = self.pushCenter else { return }
        var info = "showMobileThreeColumns: \(message.setting.showMobileThreeColumns), "
                 + "showPcThreeColumns: \(message.setting.showPcThreeColumns), "
                 + "mobileThreeColumnsNewUser: \(message.setting.mobileThreeColumnsNewUser), "
                 + "mobileTriggerScene: \(message.setting.mobileTriggerScene), "
                 + "updateTime: \(message.setting.updateTime)"
        FeedContext.log.info("feedlog/threeColumns/pushThreeColumnsSetting. \(info)")
        let filters = FeedThreeColumnSettingModel.transform(message)
        pushCenter.post(filters)
    }
}
