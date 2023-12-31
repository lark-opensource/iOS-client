//
//  SplashLogger.swift
//  LarkSplash
//
//  Created by Yuri on 2022/11/29.
//

import Foundation
import LKCommonsLogging

class SplashLogger {
    static let shared = SplashLogger()
    
    private let logger = Logger.log(SplashManagerDelegateDefaultImpl.self, category: "Module.Splash.Messages")
    
    func info(event: String, params: String? = nil) {
        if let params = params {
            logger.info("[Splash] \(event): \(params)")
        } else {
            logger.info("[Splash] \(event)")
        }
    }
    
    func error(event: String, params: String? = nil) {
        if let params = params {
            logger.error("[Splash] \(event): \(params)")
        } else {
            logger.error("[Splash] \(event)")
        }
    }
}
