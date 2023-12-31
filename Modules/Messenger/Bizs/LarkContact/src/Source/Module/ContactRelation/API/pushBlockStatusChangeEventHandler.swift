//
//  pushBlockStatusChangeEventHandler.swift
//  LarkContact
//
//  Created by JackZhao on 2020/8/14.
//

import Foundation
import RustPB
import LarkRustClient
import LKCommonsLogging
import LarkSDKInterface
import LarkModel
import LarkContainer

/// 导致IM会话的引导banner状态发生变化的实时事件的推送
public final class PushContactApplicationBannerAffectEventHandler: UserPushHandler {

    static var logger = Logger.log(PushContactApplicationBannerAffectEventHandler.self, category: "LarkContact.PushContactApplicationBannerAffectEventHandler")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    public func process(push message: Contact_V2_PushContactApplicationBannerAffectEvent) throws {
        guard let pushCenter = self.pushCenter else { return }
        pushCenter.post(PushContactApplicationBannerAffectEvent(targetUserIds: message.targetUserIds))
    }
}
