//
//  LarkInlineAILogger.swift
//  LarkInlineAI
//
//  Created by Guoxinyi on 2023/5/6.
//

import Foundation
import LKCommonsLogging

final class LarkInlineAILogger {
    static var logger = Logger.log(LarkInlineAILogger.self, category: "LarkAIService")
    
    class func info(_ message: String) {
        logger.info("[AILogger] \(message)")
    }
    
    class func error(_ error: String) {
        logger.error("[AILogger] \(error)")
    }
    
    class func warn(_ error: String) {
        logger.warn("[AILogger] \(error)")
    }
    
    class func debug(_ error: String) {
        logger.debug("[AILogger] \(error)")
    }
}
