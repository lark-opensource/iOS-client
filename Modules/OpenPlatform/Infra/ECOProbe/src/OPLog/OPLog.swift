//
//  OPLog.swift
//  LarkOPInterface
//
//  Created by 新竹路车神 on 2020/9/11.
//

import Foundation
import LKCommonsLogging

private let opCategoryPrefix = "op."

public extension Logger {

    /// 获取日志对象
    /// - Parameters:
    ///   - type: 类型
    ///   - category: 类别，可为空
    /// - Returns: 日志对象
    static func oplog(_ type: Any, category: String = "") -> Log {
        log(type, category: opCategoryPrefix + category)
    }
}

public extension Logger {

    /// 向 Logger 注入 oplog 的代理工厂
    /// 需要尽量提前执行
    /// OPLogProxy 用于日志审查，并不会真正消费日志消息，会丢回 `forwardLogFactory` 构造出的 Logger 处理
    /// - Parameter forwardLogFactory: OPLogProxy 处理完成后，日志需要被真正的 Logger 消费，需要传入一个 LoggerFactory，用于构造真正消费日志的 Logger
    static func setupOPLog(forwardLogFactory: @escaping (_ type: Any,_ category: String)-> Log) {
        Logger.setup(for: opCategoryPrefix) { (type, category) -> LKCommonsLogging.Log in
            return forwardLogFactory(type, category)
        }
    }
}
