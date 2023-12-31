//
//  PolicyEngineServiceDebugWrapper.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2023/2/8.
//

import Foundation
import LarkSecurityCompliance
import LarkSnCService

final class PolicyEngineServiceDebugWrapper: PolicyEngineSnCService {
    var client: LarkSnCService.HTTPClient?
    var storage: LarkSnCService.Storage?
    var logger: LarkSnCService.Logger?
    var tracker: LarkSnCService.Tracker?
    var monitor: LarkSnCService.Monitor?
    var settings: LarkSnCService.Settings?
    var environment: LarkSnCService.Environment?
    
    init(service: PolicyEngineSnCService) {
        client = service.client
        storage = service.storage
        logger = service.logger
        tracker = service.tracker
        monitor = service.monitor
        settings = service.settings
        environment = service.environment
    }
}
