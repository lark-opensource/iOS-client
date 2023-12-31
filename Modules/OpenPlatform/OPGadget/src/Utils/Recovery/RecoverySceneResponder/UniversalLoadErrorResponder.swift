//
//  UniversalLoadErrorResponder.swift
//  OPGadget
//
//  Created by qianhongqiang on 2022/6/07.
//

import Foundation
import OPSDK
import TTMicroApp

/// 当加载失败时需要触发的Responder
struct UniversalLoadErrorResponder: GadgetRecoveryResponder {

    func respondGadgetRecovery(with context: RecoveryContext) {
        guard let container = context.container as? OPGadgetContainer else {
            GadgetRecoveryLogger.logger.error("UniResponder: can not get container from RecoveryContext")
            return
        }

        let (_, errorStyle) = GadgetRecoveryTipInfoService.getErrorContent(context: context)
        
        guard let errorStyle = errorStyle  else {
            // 错误页配置兜底已经由前置方法兜底，这里不做处理
            return
        }
        
        // 错误页类型的错误首先直接在loading界面中展示错误页面
        if errorStyle.type == .errorPage {
            if container.tryChangeLoadingViewToUnifyErrorState(errorStyle: errorStyle) {
                GadgetRecoveryLogger.logger.info("UniResponder: error info will prompted by loading view")
                return
            }
            // 错误页类型的错误，没有找到loading界面，则直接转为modal类型的错误
            GadgetRecoveryLogger.logger.info("UniResponder: error info will prompted by modal alert")
        }

        // 错误类型不是modal;或者错误类型为错误页，没有的loading页面挂在错误页，使用模态弹框Alert
        GadgetResponderUtil.unifyErrorAlert(context: context, errorStyle: errorStyle) {
            if errorStyle.actions?.primaryButton?.clickEvent == .restart {
                container.reload(monitorCode: GDMonitorCode.unify_error_restart)
            }
        } cancelAction: {
            container.destroy(monitorCode: GDMonitorCode.unify_error_dismiss)
        }

    }

}
