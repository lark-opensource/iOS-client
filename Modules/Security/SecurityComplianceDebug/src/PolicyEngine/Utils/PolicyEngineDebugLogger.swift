//
//  PolicyEngineDebugLogger.swift
//  SecurityComplianceDebug
//
//  Created by 汤泽川 on 2022/12/2.
//

import Foundation
import LarkSnCService

final class PolicyEngineDebugLogger: Logger {
    
    var logList = [(LogLevel, String)]()
    
    func log(level: LogLevel,
             _ message: String,
             file: String,
             line: Int,
             function: String) {
        logList.append((level, message))
    }
}
