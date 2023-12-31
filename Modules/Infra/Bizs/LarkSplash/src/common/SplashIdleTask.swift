//
//  SplashIdleTask.swift
//  LarkSplash
//
//  Created by 王元洵 on 2021/5/13.
//

import Foundation
import BootManager
import LarkStorage

final class SplashIdleTask: UserFlowBootTask, Identifiable {
    static var identify = "SplashIdleTask"

    override var runOnlyOnce: Bool { return true }  //开平页面需要用户登录态才能展示，并且只针对第一个用户展示一次

    @KVConfig(key: KVKeys.Splash.hasSplashData, store: KVStores.splash)
    private var hasSplashData

    override func execute(_ context: BootContext) {
        guard !hasSplashData else { return }
        SplashLogger.shared.info(event: "idle launch")
        SplashManager.shareInstance.register(userID: userResolver.userID)
        SplashManager.shareInstance.displaySplash(isHotLaunch: false, fromIdle: true)
    }
}
