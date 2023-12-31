//
//  IMMentionLogger.swift
//  LarkIMMention
//
//  Created by Yuri on 2023/1/2.
//

import Foundation
#if canImport(LKCommonsLogging)
import LKCommonsLogging
#endif

class IMMentionLogger {
    enum Module: String {
        case panel
        case vc
        case provider
        case action
        case view
    }
    static let shared = IMMentionLogger()

#if canImport(LKCommonsLogging)
    private let logger = Logger.log(IMMentionLogger.self)
#endif
    
    func info(module: Module, event: String, parameters: String? = nil) {
#if canImport(LKCommonsLogging)
        if let parameters = parameters {
            logger.info("[IMMention.\(module.rawValue)]-\(event): \(parameters)")
        } else {
            logger.info("[IMMention.\(module.rawValue)]-\(event)")
        }
#else
        print("[IMMention.\(module.rawValue)]-\(event): \(parameters ?? "")")
#endif
    }
    
    func error(module: Module, event: String, parameters: String? = nil) {
#if canImport(LKCommonsLogging)
        if let parameters = parameters {
            logger.error("[IMMention.\(module.rawValue)]-\(event): \(parameters)")
        } else {
            logger.error("[IMMention.\(module.rawValue)]-\(event)")
        }
#else
        print("[IMMention]-\(event): \(parameters ?? "")")
#endif
    }
}
