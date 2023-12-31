//
//  SplashLaunchTask.swift
//  LarkSplash
//
//  Created by 王元洵 on 2020/10/19.
//

import Foundation
import BootManager
import LKCommonsLogging
import LarkStorage

final class SplashLaunchTask: UserFlowBootTask, Identifiable {
    static var identify = "SplashLaunchTask"

    override var runOnlyOnce: Bool { return true } //开平页面需要用户登录态才能展示，并且只针对第一个用户展示一次

    @KVConfig(key: KVKeys.Splash.hasSplashData, store: KVStores.splash)
    private var hasSplashData

    override func execute(_ context: BootContext) {
        SplashLogger.shared.info(event: "cold launch hasSplashData:\(hasSplashData) isFastLogin: \(context.isFastLogin)")
        guard self.hasSplashData, context.isFastLogin else { return }

        SplashManager.shareInstance.register(userID: userResolver.userID)
        SplashLogger.shared.info(event: "cold launch")
        SplashManager.shareInstance.displaySplash(isHotLaunch: false, fromIdle: false)
    }
}
