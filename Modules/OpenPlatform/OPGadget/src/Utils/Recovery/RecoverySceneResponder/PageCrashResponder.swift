//
//  PageCrashResponder.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK
import TTMicroApp

/// 小程序页面白屏(崩溃)时需要触发的响应
struct PageCrashResponder: GadgetRecoveryResponder {

    func respondGadgetRecovery(with context: RecoveryContext) {

        guard let page = context.valueFromUserInfo(for: NSStringFromClass(BDPAppPage.self)) as? BDPAppPage else {
            GadgetRecoveryLogger.logger.error("PageCrashResponder: can not get container from RecoveryContext")
            return
        }

        let tipContent = GadgetRecoveryTipInfoService.getTipContent(context: context)
        
        if let parentController = page.parentController() {
            parentController.updateCrashOverloadView(show: true, tipText: tipContent)
        } else {
            GadgetRecoveryLogger.logger.error("PageCrashResponder: can not get parentController for page")
        }
    }

}
