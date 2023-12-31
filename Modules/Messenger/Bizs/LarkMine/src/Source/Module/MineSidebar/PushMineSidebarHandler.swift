//
//  PushMineSidebarHandler.swift
//  LarkMine
//
//  Created by 李勇 on 2020/7/6.
//

import Foundation
import RustPB
import LarkRustClient
import LarkContainer
import LarkSDKInterface

/// Feed侧边栏远端下发的Sidebar变化
final class PushMineSidebarHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: RustPB.Passport_V1_GetUserSidebarResponse) throws {
        guard let pushCenter = self.pushCenter else { return }
        pushCenter.post(PushMineSidebar(sidebars: message.sidebarInfos))
    }
}
