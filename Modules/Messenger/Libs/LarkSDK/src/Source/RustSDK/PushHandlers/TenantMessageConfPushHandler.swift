//
//  TenantMessageConfPushHandler.swift
//  LarkSDK
//
//  Created by ByteDance on 2022/8/16.
//

import Foundation
import RustPB
import LarkRustClient
import LKCommonsLogging
import LarkSDKInterface
import LarkContainer

final class TenantMessageConfPushHandler: UserPushHandler {

    override class var compatibleMode: Bool { SDK.userScopeCompatibleMode }
    static var logger = Logger.log(TenantMessageConfPushHandler.self, category: "Rust.PushHandler")

    private var pushCenter: PushNotificationCenter? { try? userResolver.userPushCenter }

    func process(push message: Im_V1_PushTenantMessageConfResponse) {
        let tenantMessageConf = PushTenantMessageConf(conf: message.conf)
        self.pushCenter?.post(tenantMessageConf)
    }
}
