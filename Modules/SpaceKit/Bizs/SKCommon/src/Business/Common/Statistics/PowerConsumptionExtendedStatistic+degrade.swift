//
//  PowerConsumptionExtendedStatistic+degrade.swift
//  SKCommon
//
//  Created by ByteDance on 2022/12/14.
//

import Foundation
import SKFoundation
import RustPB
import LarkRustClient
import SKInfra

/// MS功耗降级推送处理者
public protocol MSDegradeRustPushHandler: AnyObject {
    
    func handleDowngradePush(payload: Data)
    
}

extension PowerConsumptionExtendedStatistic {
    
    func setupRustObservation() {
        
        guard UserScopeNoChangeFG.CS.powerOptimizeDowngradeEnabled else {
            DocsLogger.info("MS downgrade FG is false")
            return
        }
        
        if let rustService = DocsContainer.shared.resolve(RustService.self) {
            if degradeRustObservation == nil {
                let command: Command = Basic_V1_Command.pushCpuManagerMagicshareSceneDowngradeStrategy
                let observation = rustService.register(pushCmd: command) { [weak self] in
                    self?.handlePush($0)
                }
                degradeRustObservation = observation
                DocsLogger.info("add MS downgrade rust observation succeed")
            } else {
                DocsLogger.info("MS downgrade rust observation exist already")
            }
        } else {
            DocsLogger.error("get RustService failed")
        }
    }
    
    public func registerMSDegradeHandler(_ handler: MSDegradeRustPushHandler) {
        if degradeRustObservation == nil { // 有可能初始化时获取不到RustService, 因此再检查一下
            setupRustObservation()
        }
        msDegradeHandlers.add(handler)
    }
    
    private func handlePush(_ payload: Data) {
        DocsLogger.info("did receive MS downgrade rust push, data:\(payload)")
        msDegradeHandlers.all.forEach { handler in
            handler.handleDowngradePush(payload: payload)
        }
    }
}
