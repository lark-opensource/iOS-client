//
//  Logger.swift
//  LarkAppIntents
//
//  Created by Hayden on 2022/9/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkExtensionServices

enum Logger {

    static func error(_ message: String) {
        #if DEBUG
        NSLog("🔴" + message)
        #else
        ExtensionLogger.logger.error(LarkExtensionServices.Logger.Message(stringLiteral: message))
        #endif
    }

    static func info(_ message: String) {
        #if DEBUG
        NSLog("🔵" + message)
        #else
        ExtensionLogger.logger.info(LarkExtensionServices.Logger.Message(stringLiteral: message))
        #endif
    }
}
