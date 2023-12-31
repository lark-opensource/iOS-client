//
//  SuiteLoginFetchConfig.swift
//  LarkAccount
//
//  Created by KT on 2020/7/7.
//

import Foundation
import BootManager
import LKCommonsLogging

class SuiteLoginFetchConfig: FlowBootTask, Identifiable { // user:checked (boottask)

    static var identify = "SuiteLoginFetchConfig"
    
    static let logger = Logger.log(SuiteLoginFetchConfig.self, category: "SuiteLoginFetchConfig")

    override func execute(_ context: BootContext) {
        AccountIntegrator.shared.refreshConfig()
        /// 上报延迟事件
        NewBootManager.shared.addConcurrentTask {
            //上报延迟事件
            Self.logger.info("n_action_flush_delay_events", method: .local)
            PassportMonitor.flushDelayEvents()
        }
    }
}
