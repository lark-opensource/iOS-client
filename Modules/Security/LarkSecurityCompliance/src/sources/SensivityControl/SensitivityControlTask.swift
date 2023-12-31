//
//  SensitivityControlTask.swift
//  LarkSecurityCompliance
//
//  Created by bytedance on 2022/8/29.
//

import Foundation
import BootManager
import LarkContainer

import LarkSecurityComplianceInfra
import LarkSnCService
import LarkSensitivityControl
#if canImport(TTVideoEditor)
import TTVideoEditor
#endif

final class SensitivityControlTask: FlowBootTask, Identifiable { // Global
    static var identify = "SensitivityControlTask"

    override func execute(_ context: BootContext) {
        let serviceImpl = LarkPSDAServiceImpl(category: "sensitivity-control")
        SensitivityManager.shared.register { service in
            service.client = serviceImpl.client
            service.logger = serviceImpl.logger
            service.storage = serviceImpl.storage
            service.tracker = serviceImpl.tracker
            service.settings = serviceImpl.settings
            service.monitor = serviceImpl.monitor
            service.environment = serviceImpl.environment
        }
#if canImport(TTVideoEditor)
        VESaftyControlModule.setPolicyDelegate(VEPolicyImpl())
#endif

    }

    override var runOnlyOnce: Bool {
        return true
    }
}
