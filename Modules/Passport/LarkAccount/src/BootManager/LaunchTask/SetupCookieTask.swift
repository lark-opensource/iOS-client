//
//  SetupCookieTask.swift
//  LarkBaseService
//
//  Created by KT on 2020/7/8.
//

import Foundation
import AppContainer
import BootManager
import LarkAccountInterface
import CookieManager
import LarkContainer

final class SetupCookieTask: FlowBootTask, Identifiable {
    static var identify = "SetupCookieTask"

    @Provider private var passportService: PassportService
    @Provider private var passportCookieDependency: AccountDependency // user:checked (global-resolve)

    override var scope: Set<BizScope> {
        // 可能同步需要Cookie的场景
        return [.docs, .openplatform, .mail, .specialLaunch]
    }

    override func execute(_ context: BootContext) {
        if let foregroundUser = passportService.foregroundUser { // user:current
            passportCookieDependency.setupCookie(user: foregroundUser) // user:current
        }
    }
}
