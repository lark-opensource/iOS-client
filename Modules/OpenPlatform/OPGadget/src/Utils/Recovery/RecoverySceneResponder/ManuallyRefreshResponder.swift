//
//  ManuallyRefreshResponder.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK
import TTMicroApp

/// 用户手动点击刷新小程序时需要触发的响应
struct ManuallyRefreshResponder: GadgetRecoveryResponder {

    func respondGadgetRecovery(with context: RecoveryContext) {
        guard let container = context.container else {
            GadgetRecoveryLogger.logger.error("ManuallyRefreshResponder: can not get container from RecoveryContext")
            return
        }

        container.reload(monitorCode: GDMonitorCode.about_restart)
    }

}
