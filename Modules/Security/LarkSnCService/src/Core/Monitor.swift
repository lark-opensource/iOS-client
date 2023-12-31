//
//  Monitor.swift
//  LarkSnCService
//
//  Created by Bytedance on 2022/8/15.
//

import Foundation

/// Monitor 监控
public protocol Monitor {
    /// 发送正确监控事件
    /// - Parameters:
    ///   - name: 事件名称
    ///   - category: 分类
    ///   - metric: 指标
    func sendInfo(service name: String,
              category: [String: Any]?,
              metric: [String: Any]?)

    /// 发送错误监控事件
    /// - Parameters:
    ///   - name: 事件名称
    ///   - error: 错误 Error
    func sendError(service name: String, error: Error?)
}

public extension Monitor {
    /// 发送监控事件
    /// - Parameters:
    ///   - name: 事件名称
    ///   - category: 分类
    ///   - metric: 指标
    func info(service name: String,
              category: [String: Any]? = nil,
              metric: [String: Any]? = nil) {
        sendInfo(service: name, category: category, metric: metric)
    }

    /// 发送错误监控事件
    /// - Parameters:
    ///   - name: 事件名称
    ///   - error: 错误 Error
    func error(service name: String, error: Error? = nil) {
        sendError(service: name, error: error)
    }
}
