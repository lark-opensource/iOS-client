//
//  LogFactory.swift
//  LarkExtensionServices
//
//  Created by 王元洵 on 2021/4/1.
//

import Foundation

/// 全局工厂，生产默认的Loghandler，默认的LoghandlerHandler会往控制台和文件输出Log
public enum LogFactory {

    private static let defaultLogHandler = MultiplexLogHandler([ConsoleLogHandler(), FileLogHandler()])

    /// 创建一个Logger对象用于日志输出.
    ///
    /// - Parameters:
    ///   - label: 日志使用者的标识符
    public static func createLogger(label: String) -> Logger { Logger(label: label, defaultLogHandler) }
}
