//
//  AppFeedPushHandler.swift
//  LarkSDK
//
//  Created by yinyuan on 2019/10/9.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface
import UIKit

final class AppFeedPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Openplatform_V1_PushAppFeedResponse) {
        let appFeeds = message.appFeeds.mapValues { (appFeed) -> PushAppFeeds.AppFeed in
            PushAppFeeds.AppFeed(appID: appFeed.id, lastNotificationSeqID: appFeed.lastNotificationSeqID, url: URL(string: appFeed.iosSchema))
        }
        self.pushCenter?.post(PushAppFeeds(appFeeds: appFeeds))
    }
}
