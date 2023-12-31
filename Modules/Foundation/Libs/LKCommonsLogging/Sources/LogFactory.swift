//
//  LKCommonsLoggingFactory.swift
//  LKCommonsLogging
//
//  Created by lvdaqian on 2018/3/25.
//  Copyright © 2018年 Efficiency Engineering. All rights reserved.
//

import Foundation

/// 日志工厂协议
public protocol LogFactory {
    /// 静态获取日志对象
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - category: 日志类别
    /// - Returns: 符合Log协议的日志对象
    static func createLog(_ type: Any, category: String) -> Log
}

/// 日志工厂 closure， 用于简单快捷配置日志工厂
public typealias LogFactoryBlock = (Any, String) -> Log

private let defalutLogFactory: LogFactoryBlock = { SimpleFactory.createLog($0, category: $1) }

/// Logger 公共接口
public final class Logger {

    fileprivate static var factoryStore: LogFactoryStore = LogFactoryStore(defalutLogFactory)
    /// 日志使用者获取日志对象
    ///
    /// - Parameters:
    ///   - type: 类型
    ///   - category: 类别，可为空
    /// - Returns: 符合Log协议的日志对象
    static public func log(_ type: Any, category: String = "") -> Log {
        let factory = factoryStore.findLogFactory(for: category)
        return factory(type, category)
    }

    /// 设置日志工厂
    ///
    /// - Parameters:
    ///   - category: 指定该日志工厂生效的类别
    ///   - factory: 实现LogFactory协议的类型
    static public func setup(for category: String = "", _ factory: LogFactory.Type) {
        factoryStore.setupLogFactory(for: category) { factory.createLog($0, category: $1) }
    }

    /// 设置日志工厂
    ///
    /// - Parameters:
    ///   - category: 指定该日志工厂生效的类别
    ///   - factory: 用于创造日志对象的closure
    static public func setup(for category: String = "", _ factory: @escaping LogFactoryBlock) {
        factoryStore.setupLogFactory(for: category, with: factory)
    }
}
