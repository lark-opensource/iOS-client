//
//  SplashApplicationDelegate.swift
//  Lark
//
//  Created by 王元洵 on 2020/10/19.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import AppContainer
import BootManager
import LarkStorage

final class SplashApplicationDelegate: ApplicationDelegate {
    static let config = Config(name: "Splash", daemon: true)

    required init(context: AppContext) {
        context.dispatcher.add(observer: self) { [weak self] (_, message: WillEnterForeground) in
            self?.willEnterForeground(message)
        }
    }

    @KVConfig(key: KVKeys.Splash.hasSplashData, store: KVStores.splash)
    private var hasSplashData

    private func willEnterForeground(_ message: WillEnterForeground) {
        guard let userID = NewBootManager.shared.context.currentUserID,
              self.hasSplashData ?? false else { return }
        SplashLogger.shared.info(event: "hot launch")
        SplashManager.shareInstance.register(userID: userID)
        SplashManager.shareInstance.displaySplash(isHotLaunch: true, fromIdle: false)
    }
}
