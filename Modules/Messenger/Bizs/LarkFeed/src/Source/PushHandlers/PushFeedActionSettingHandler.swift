//
//  PushFeedActionSettingHandler.swift
//  LarkFeed
//
//  Created by ByteDance on 2023/11/10.
//

import Foundation
import RustPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import LarkModel
import LarkSDKInterface

extension FeedActionSettingData: PushMessage {}

final class PushFeedActionSettingHandler: UserPushHandler {
    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Feed_V1_PushFeedActionSetting) throws {
        guard let pushCenter = self.pushCenter else { return }
        var info = "leftSlideAction: \(message.slideAction.leftSlideAction), "
        + "rightSlideAction: \(message.slideAction.rightSlideAction), "

        FeedContext.log.info("feedlog/actionSetting/pushActionSetting. \(info)")
        let setting = FeedActionSettingData.transform(message: message)
        pushCenter.post(setting)
    }
}
