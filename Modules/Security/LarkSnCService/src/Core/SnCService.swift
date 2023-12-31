//
//  SnCService.swift
//  LarkSnCService
//
//  Created by Bytedance on 2022/8/8.
//

import Foundation

/// 安全合规 Service protocol
public protocol SnCService {
    /// 网络请求
    var client: HTTPClient? { get }
    /// 存储
    var storage: Storage? { get }
    /// 日志打印
    var logger: Logger? { get }
    /// 埋点
    var tracker: Tracker? { get }
    /// 监控
    var monitor: Monitor? { get }
    /// Settings
    var settings: Settings? { get }
    /// 环境参数
    var environment: Environment? { get }
}
