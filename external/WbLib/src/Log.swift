//
// Log.swift
//
//
// Created by kef on 2022/4/1.
//

import Foundation

private func cOnLogMessageHandler(cCategory: UnsafePointer<CChar>?, cLevel: UInt32, cMessage: UnsafePointer<CChar>?) {
    let category: String = String.fromCValue(cCategory) ?? "Unknown category"
    let message: String = String.fromCValue(cMessage) ?? "Empty message"
    
    _onLogMessage(category, Int(cLevel), message)
}

/// 白板内部日志输出, 通过此回调将内容回传到业务侧
///
/// # 参数
/// - `category`: 日志分类, UTF8 编码字符串
/// - `level`: 日志分级
/// - `msg`: 日志内容信息, UTF8 编码字符串
///
/// # 日志分级
/// - 默认开启
///   - 0: 最高优先级
///   - 1: 一般优先级
/// - 默认关闭
///   - 2: 重要, 但是没必要打印
///   - 3: 调试日志
public typealias LogMessageHandler = (String, Int, String) -> Void

private var _isLoggerSet: Bool = false
private var _onLogMessage: LogMessageHandler = onLogMessageDefault

public func onLogMessageDefault(_ category: String, _ level: Int, _ message: String) {
    var levelStr = "UnknownLevel"

    switch level {
    case 0:
        levelStr = "Error"
    case 1:
        levelStr = "Warning"
    case 2:
        levelStr = "Info"
    case 3:
        levelStr = "debug"
    case 4:
        levelStr = "trace"
    default:
        levelStr = "Error"
    }

    print("[\(category)] - [\(levelStr)] \(message)")
}

/// 设置日志回调
public func setLogMessageHandler(_ handler: @escaping LogMessageHandler) {
    _onLogMessage = handler
    
    if !_isLoggerSet {
        wrap { wb_set_log_callback(cOnLogMessageHandler) }
        _isLoggerSet = true
    }
}

extension WbError {
    /// 记录wb调用产生的错误信息
    public func log() {
        _onLogMessage("wb-swift-binding", 0, message)
    }
}

internal func printError(_ message: String) {
    _onLogMessage("wb-swift-binding", 0, message)
}
