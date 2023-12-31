//
//  RuntimeFailResponder.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK
import TTMicroApp

/// 小程序运行时出现错误时需要触发的响应
struct RuntimeFailResponder: GadgetRecoveryResponder {

    func respondGadgetRecovery(with context: RecoveryContext) {
        guard let container = context.container else {
            GadgetRecoveryLogger.logger.error("RuntimeFailResponder: can not get container from RecoveryContext")
            return
        }

        let tipTitle = BDPI18n.openPlatform_GadgetErr_AppErrorTtl ?? ""
        let tipContent = GadgetRecoveryTipInfoService.getTipContent(context: context)

        GadgetResponderUtil.alertCancelOrReload(context: context, title: tipTitle, content: tipContent) {
            container.reload(monitorCode: GDMonitorCode.about_restart)
        }
    }

}
