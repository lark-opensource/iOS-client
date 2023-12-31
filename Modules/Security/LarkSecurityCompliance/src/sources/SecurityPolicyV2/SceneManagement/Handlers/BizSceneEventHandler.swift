//
//  BizSceneEventHandler.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/7.
//

import Foundation
import LarkSecurityComplianceInfra
protocol BizSceneEventHandler {
    func start()
    func stop()
    func execute()
}

extension BizSceneEventHandler {
    func start() {
        SCLogger.info("SceneEventHandler default start")
    }
    
    func stop() {
        SCLogger.info("SceneEventHandler default stop")
    }
    
    func execute() {
        SCLogger.info("SceneEventHandler default execute")
    }
}
