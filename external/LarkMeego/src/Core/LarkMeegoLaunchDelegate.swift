//
//  LarkMeegoLaunchDelegate.swift
//  LarkMeego
//
//  Created by shizhengyu on 2021/8/26.
//

import Foundation
import LarkAccountInterface
import RxSwift
import Swinject
import LarkContainer
import LarkMeegoInterface
import LarkMeegoNetClient
import LarkMeegoPush
import LarkMeegoLogger

class LarkMeegoLaunchDelegate: LauncherDelegate {
    var name: String = "LarkMeegoLaunchDelegate"

    @Provider private var meegoService: LarkMeegoService

    func fastLoginAccount(_ account: LarkAccountInterface.Account) {
        (meegoService as? LarkMeegoServiceImpl)?.fetchMeegoEnableIfNeeded()
    }

    func afterLoginSucceded(_ context: LarkAccountInterface.LauncherContext) {
        (meegoService as? LarkMeegoServiceImpl)?.fetchMeegoEnableIfNeeded()
    }

    func switchAccountSucceed(context: LarkAccountInterface.LauncherContext) {
        // 清理渠道相关Cookie
        MeegoLogger.info("switchAccountSucceed cleanChannelCookie")
        LarkMeegoNetClient.cleanChannelCookie()
    }

    func beforeSwitchAccout() {
        MeegoLogger.info("beforeSwitchAccout stopPushService")
        MeegoPushNativeService.stopPushService()
    }

    func beforeLogout() {
        MeegoLogger.info("beforeLogout stopPushService")
        MeegoPushNativeService.stopPushService()
    }

    public func afterLogout(_ context: LauncherContext) {
        // 清理渠道相关Cookie
        MeegoLogger.info("afterLogout cleanChannelCookie")
        LarkMeegoNetClient.cleanChannelCookie()
    }
}
