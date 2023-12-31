//
//  LarkALoggerProxy.swift
//  LarkBaseService
//
//  Created by CL7R on 2020/11/30.
//

import Foundation
import LKCommonsLogging
import Logger

struct LarkALoggerProxy: LKCommonsLogging.Log {
    let logger: LoggerLog

    init(_ type: Any, _ category: String, custom: LKCommonsLogging.Log? = nil) {
        let typeCls: AnyClass = type as? AnyClass ?? Logger.self
        self.logger = Logger.log(typeCls, category: category, backendType: "ALog")
    }

    func log(event: LKCommonsLogging.LogEvent) {
        let en = EventTransform.transform(event)
        logger.log(en)
    }

    func isDebug() -> Bool {
        return true
    }

    func isTrace() -> Bool {
        return true
    }
}
