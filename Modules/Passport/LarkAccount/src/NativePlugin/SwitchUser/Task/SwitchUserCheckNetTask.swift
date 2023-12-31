//
//  SwitchUserCheckNetTask.swift
//  LarkAccount
//
//  Created by bytedance on 2021/8/31.
//

import Foundation
import Reachability
import EENavigator
import LarkAlertController
import LarkAccountInterface

class SwitchUserCheckNetTask: SwitchUserPreTask {
    
    override func run() {
        logger.info(SULogKey.switchCommon, body: "net task run", method: .local)

        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.startCheckNet, context: monitorContext)
        
        let connection = Reachability()?.connection
        if connection == Reachability.Connection.none {

            //监控
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.checkNetResult, isFailResult: true, context: monitorContext)

            guard let mainSceneWindow = PassportNavigator.keyWindow else {
                logger.info(SULogKey.switchCommon, body: "net task fail with no alert")
                failCallback(AccountError.switchUserCheckNetError)
                return
            }
            logger.info(SULogKey.switchCommon, body: "net task fail with alert")

            let alertController = LarkAlertController()
            alertController.setTitle(text: BundleI18n.LarkAccount.Lark_Legacy_SwitchUser_InternetErrorAlert_Title)
            alertController.setContent(text: BundleI18n.LarkAccount.Lark_Legacy_SwitchUser_InternetErrorAlert_Content)
            alertController.addPrimaryButton(text: BundleI18n.LarkAccount.Lark_Legacy_SwitchUser_InternetErrorAlert_Confirm)
            Navigator.shared.present(alertController, from: mainSceneWindow) // user:checked (navigator)

            failCallback(AccountError.switchUserCheckNetError)
        }else{
            //监控
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.checkNetResult, isSuccessResult: true, context: monitorContext)

            logger.info(SULogKey.switchCommon, body: "net task succ", method: .local)
            succCallback()
        }
    }
}

