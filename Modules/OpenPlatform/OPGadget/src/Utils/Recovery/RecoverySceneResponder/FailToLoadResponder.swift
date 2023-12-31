//
//  FailToLoadResponder.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK
import TTMicroApp

/// 当加载失败时需要触发的Responder
struct FailToLoadResponder: GadgetRecoveryResponder {

    func respondGadgetRecovery(with context: RecoveryContext) {
        guard let container = context.container as? OPGadgetContainer else {
            GadgetRecoveryLogger.logger.error("FailToLoadResponder: can not get container from RecoveryContext")
            return
        }

        let tipTitle = BDPI18n.openPlatform_GadgetErr_AppLoadFailTtl ?? ""
        let tipContent = GadgetRecoveryTipInfoService.getTipContent(context: context)

        // 首先尝试直接在loading界面中展示错误以及重试按钮
        if container.tryChangeLoadingViewToFailRefreshState(tipInfo: tipContent) {
            GadgetRecoveryLogger.logger.info("FailToLoadResponder: error info will prompted by loading view")
            return
        }
        GadgetRecoveryLogger.logger.info("FailToLoadResponder: error info will prompted by modal alert")

        // 如果没有对应的loading页面，则降级使用模态弹框Alert
        GadgetResponderUtil.alertCancelOrReload(context: context, title: tipTitle, content: tipContent) {
            container.reload(monitorCode: GDMonitorCode.about_restart)
        }
    }

}
