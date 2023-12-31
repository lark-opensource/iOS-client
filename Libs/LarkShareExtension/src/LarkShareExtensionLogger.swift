//
//  LarkShareExtensionLogger.swift
//  LarkShareExtension
//
//  Created by ByteDance on 2023/4/13.
//

import Foundation
import LarkExtensionServices

class LarkShareExtensionLogger {
    static let shared = LarkShareExtensionLogger()

    private let logger = LogFactory.createLogger(label: "LarkShareExtension")

    func info(_ event: String, params: String? = nil) {
        if let params = params {
            logger.info("[LarkShareExtension] \(event): \(params)")
        } else {
            logger.info("[LarkShareExtension] \(event)")
        }
    }

    func error(_ event: String, params: String? = nil) {
        if let params = params {
            logger.error("[LarkShareExtension] \(event): \(params)")
        } else {
            logger.error("[LarkShareExtension] \(event)")
        }
    }
}
