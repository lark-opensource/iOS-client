//
//  AccountsBadgePushHandler.swift
//  LarkAccount
//
//  Created by KT on 2020/3/9.
//

import Foundation
import RustPB
import LarkRustClient
import LKCommonsLogging
import LarkContainer

public typealias PushAccountBadgeBody = RustPB.Basic_V1_PushAccountBadgeBody

final class AccountBadgePushHandler: UserPushHandler {

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    static var logger = Logger.log(AccountBadgePushHandler.self)

    private var switchAccountService: SwitchAccountService? {
        try? userResolver.resolve(assert: SwitchAccountService.self)
    }

    public func process(push message: PushAccountBadgeBody) throws {
        self.switchAccountService?.updateAccountBadge(with: message.userBadgeMap)
        AccountBadgePushHandler.logger.info("push userBadgeMap: \(message.userBadgeMap)")
    }
}
