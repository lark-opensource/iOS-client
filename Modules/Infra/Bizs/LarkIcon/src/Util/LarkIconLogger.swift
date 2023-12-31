//
//  LarkIconLogger.swift
//  LarkIcon
//
//  Created by huangzhikai on 2023/12/13.
//

import Foundation
import LKCommonsLogging
struct LarkIconLogger {
    // LarkDocsIcon 统一logger
    public static var logger = Logger.log(LarkIconLogger.self, category: "Module.LarkIcon")
}
