//
//  OPGadgetContainer+RecoverableErrorHandler.swift
//  OPGadget
//
//  Created by liuyou on 2021/5/14.
//

import Foundation
import OPSDK
import ECOProbe
import TTMicroApp
import LarkSetting

/// OPGadgetContainer接入错误恢复框架
extension OPGadgetContainer: RecoverableErrorHandler {
    public func handle(with context: RecoveryContext) -> [RecoveryAction]? {
        let uniqueID = containerContext.uniqueID
        // 熔断机制
        GadgetRecoveryHystrixCenter.current.triggerRecovery(with: uniqueID)
        let currentHystrixType = GadgetRecoveryHystrixCenter.current.currentHystrixType(with: uniqueID)

        // 统一错误页总开关
        if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.gadget.errorpage.unify")) {
            if let gadgetUnifyErrorResponder = GadgetRecoveryResponderService.getGadgetUnifyErrorResponder(for: context) {
                gadgetUnifyErrorResponder.respondGadgetRecovery(with: context)
            } else {
                GadgetRecoveryLogger.logger.error("gadget(\(uniqueID.fullString)) error accured, missing responder for \(String(describing: context.recoveryScene?.value))")
            }
        } else {
            let gadgetRecoveryResponder = GadgetRecoveryResponderService.getGadgetRecoveryResponder(for: context)
            gadgetRecoveryResponder?.respondGadgetRecovery(with: context)
        }

        
        // 自动恢复框架捕获到错误发生，埋点上报
        GadgetRecoveryMonitor.current.notifyGadgetRecoveryErrorCatched(recoveryContext: context, currentHystrixType: currentHystrixType)

        let actions = GadgetRecoveryActionService.getActions(with: context.recoveryError, hystrixType: currentHystrixType)
        GadgetRecoveryLogger.logger.info("gadget(\(uniqueID.fullString)) recovery with recoveryActions: \(actions) and hystrixType: \(currentHystrixType)")
        return actions
    }
}
