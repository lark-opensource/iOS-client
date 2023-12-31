//
//  SplashAccountDelegate.swift
//  LarkSplash
//
//  Created by 王元洵 on 2021/8/4.
//

import Foundation
import LarkAccountInterface
import RxSwift

final class SplashAccountDelegate: LauncherDelegate {
    public var name: String = "SplashAccountDelegate"

    func afterSwitchAccout(error: Error?) -> Observable<Void> {
        if let error = error {
            SplashLogger.shared.error(event: "account switched failed", params: error.localizedDescription)
        } else {
            SplashLogger.shared.info(event: "account switched")
            SplashManager.shareInstance.clearCache()
            SplashManager.shareInstance.displaySplash(isHotLaunch: false, fromIdle: true)
        }
        return .just(())
    }

    func afterLogout(context: LauncherContext, conf: LogoutConf) {
        SplashLogger.shared.info(event: "account after logout")
        SplashManager.shareInstance.clearCache()
        SplashManager.shareInstance.displaySplash(isHotLaunch: false, fromIdle: true)
    }
}
