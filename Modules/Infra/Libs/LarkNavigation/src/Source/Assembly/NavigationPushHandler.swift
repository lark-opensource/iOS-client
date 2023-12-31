//
//  NavigationPushHandler.swift
//  LarkNavigation
//
//  Created by 袁平 on 2020/12/9.
//

import Foundation
import LarkRustClient
import RustPB
import LarkContainer
import LKCommonsLogging

extension NavigationInfoResponse: PushMessage {}

final class NavigationPushHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    private static let logger = Logger.log(NavigationPushHandler.self, category: "LarkNavigation.NavigationPushHandler")

    func process(push message: NavigationAppInfoResponse) throws {
        guard let pushCenter = self.pushCenter else { return }
        let message = NavigationInfoResponse(response: message)
        pushCenter.post(message)
        Self.logger.info("receive push navigation")
    }
}
