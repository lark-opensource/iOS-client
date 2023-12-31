//
//  DocsIconLogger.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/20.
//

import Foundation
import LKCommonsLogging
struct DocsIconLogger {
    // LarkDocsIcon 统一logger
    public static var logger = Logger.log(DocsIconLogger.self, category: "Module.LarkDocsIcon")
}
