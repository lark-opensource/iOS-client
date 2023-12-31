//
//  Log+Level.swift
//  Efficiency Engineering
//
//  Created by 王元洵 on 2021/04/01.
//  Copyright © 2018 Efficiency Engineering. All rights reserved.
//

import Foundation

/// 日志输出级别， 扩展与Int. 可以根据需要扩展与转换
/// 
/// 内置的日志级别如下
/// - trace: 详细信息，值为0
/// - debug: 调试信息，值为1
/// - info: 一般信息，值为2
/// - warn: 警告信息，值为3
/// - error: 错误信息，值为4
/// - fatal: 严重错误信息，值为5
public extension Logger {
    enum Level: Int, Codable, CaseIterable {
        /// 适用于跟踪程序执行时的信息。
        case trace

        /// 适用于调试信息。
        case debug

        /// 适用于普通的消息
        case info

        /// 适用于警告信息。
        case warn

        /// 适用于错误信息。
        case error
    }
}

extension Logger.Level {
    var levelString: String {
        switch self {
        case .trace:
            return "[TRACE]"
        case .debug:
            return "[DEBUG]"
        case .info:
            return "[INFO]"
        case .warn:
            return "[WARN]"
        case .error:
            return "[ERROR]"
        }
    }
}
