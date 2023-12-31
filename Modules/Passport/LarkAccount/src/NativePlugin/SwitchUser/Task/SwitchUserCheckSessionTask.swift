//
//  SwitchUserCheckSessionTask.swift
//  LarkAccount
//
//  Created by bytedance on 2021/8/31.
//

import Foundation
import LarkContainer
import RoundedHUD
import EENavigator
import ECOProbeMeta

class SwitchUserCheckSessionTask: SwitchUserPreTask {
    
    @Provider private var userSessionService: UserSessionService
    
    override func run() {
        logger.info(SULogKey.switchCommon, body: "check session task run")
        
        let hud = RoundedHUD()
        if let view = PassportNavigator.keyWindow {
            hud.showLoading(
                with: BundleI18n.LarkAccount.Lark_Legacy_BaseUiLoading,
                on: view,
                disableUserInteraction: true
            )
        }

        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.checkStatusStart, timerStart: .checkStatus, context: monitorContext)

        userSessionService.doCheckSession {[weak self] isSucc in
            guard let self = self else { return }
            self.logger.info(SULogKey.switchCommon, body: "check session task succ")

            hud.remove()
            self.succCallback()

            //监控
            if isSucc {
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.checkStatusResult, timerStop: .checkStatus, isSuccessResult: true, context: self.monitorContext)
            } else {
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.checkStatusResult, timerStop: .checkStatus, isFailResult: true, context: self.monitorContext)
            }
        }
    }
}
