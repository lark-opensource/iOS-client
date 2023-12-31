//
//  LoggerService.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/10/30.
//

import Foundation
import LarkWebViewContainer

class LoggerService: WASimpleBridgeService {
    
    override var name: WABridgeName {
        .logger
    }
    
    override var serviceType: WABridgeServiceType {
        .base
    }
    
    override func handle(invocation: WABridgeInvocation) {
        guard let msg = invocation.params["message"] as? String ?? invocation.params["logMessage"] as? String else {
            assertionFailure()
            return
        }
        let level = invocation.params["level"] as? String ?? "info"
        let logMsg = "js call, \(msg)"
        switch level {
        case "error":
            Self.logger.error(logMsg)
        case "debug":
            Self.logger.debug(logMsg)
        case "warn":
            Self.logger.warn(logMsg)
        default:
            Self.logger.info(logMsg)
        }
    }
}
