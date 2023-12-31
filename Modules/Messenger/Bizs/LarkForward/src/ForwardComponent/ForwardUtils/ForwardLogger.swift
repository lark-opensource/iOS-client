//
//  ForwardLogger.swift
//  LarkForward
//
//  Created by ByteDance on 2023/8/11.
//

import Foundation
#if canImport(LKCommonsLogging)
import LKCommonsLogging
#endif

class ForwardLogger {
    enum Module: String {
        // 最近转发
        case recentForward
        // 最近访问
        case recentVisit
        // 搜索场景
        case search
        // 转发确认框
        case forwardAlert
        // 内容预览
        case contentPreview
        // 目标预览
        case targetPreview
        // 消息发送
        case forwardMessage
        // 创建群组并转发
        case createGroup
    }
    static let shared = ForwardLogger()

#if canImport(LKCommonsLogging)
    private let logger = Logger.log(ForwardLogger.self)
#endif

    func info(module: Module, event: String, parameters: String? = nil) {
#if canImport(LKCommonsLogging)
        if let parameters = parameters {
            logger.info("[Forward]{\(module.rawValue)}-\(event): \(parameters)")
        } else {
            logger.info("[Forward]{\(module.rawValue)}-\(event)")
        }
#else
        print("[Forward]{\(module.rawValue)}-\(event): \(parameters ?? "")")
#endif
    }

    func error(module: Module, event: String, parameters: String? = nil) {
#if canImport(LKCommonsLogging)
        if let parameters = parameters {
            logger.error("[Forward]{\(module.rawValue)}-\(event): \(parameters)")
        } else {
            logger.error("[Forward]{\(module.rawValue)}-\(event)")
        }
#else
        print("[Forward]{\(module.rawValue)}-\(event): \(parameters ?? "")")
#endif
    }
}
