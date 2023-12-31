//
//  ContactLogger.swift
//  LarkIMMention
//
//  Created by Yuri on 2023/1/2.
//

import Foundation
#if canImport(LKCommonsLogging)
import LKCommonsLogging
#endif

class ContactLogger {
    enum Module: String {
        case view
        case addExternalContact
        case onboarding
        case special
        case action // 用户交互
    }
    static let shared = ContactLogger()

#if canImport(LKCommonsLogging)
    private let logger = Logger.log(ContactLogger.self)
#endif

    func info(module: Module, event: String, parameters: String? = nil) {
#if canImport(LKCommonsLogging)
        if let parameters = parameters {
            logger.info("[Contact]{\(module.rawValue)}-\(event): \(parameters)")
        } else {
            logger.info("[Contact]{\(module.rawValue)}-\(event)")
        }
#else
        print("[Contact]{\(module.rawValue)}-\(event): \(parameters ?? "")")
#endif
    }

    func error(module: Module, event: String, parameters: String? = nil) {
#if canImport(LKCommonsLogging)
        if let parameters = parameters {
            logger.error("[Contact]{\(module.rawValue)}-\(event): \(parameters)")
        } else {
            logger.error("[Contact]{\(module.rawValue)}-\(event)")
        }
#else
        print("[Contact]{\(module.rawValue)}-\(event): \(parameters ?? "")")
#endif
    }
}
