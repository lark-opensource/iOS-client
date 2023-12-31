//
//  LKBGLogger.swift
//  LarkBGTaskScheduler
//
//  Created by 李勇 on 2020/2/18.
//

import Foundation

/// 日志工具
public protocol LKBGLogger {
    func debug(_ message: String, error: Error?, file: String, method: String, line: Int)
    func info(_ message: String, error: Error?, file: String, method: String, line: Int)
    func error(_ message: String, error: Error?, file: String, method: String, line: Int)
}

extension LKBGLogger {
    func debug(_ message: String, error: Error? = nil, file: String = #fileID, method: String = #function, line: Int = #line) {
        self.debug(message, error: error, file: file, method: method, line: line)
    }

    func info(_ message: String, error: Error? = nil, file: String = #fileID, method: String = #function, line: Int = #line) {
        self.info(message, error: error, file: file, method: method, line: line)
    }

    func error(_ message: String, error: Error? = nil, file: String = #fileID, method: String = #function, line: Int = #line) {
        self.error(message, error: error, file: file, method: method, line: line)
    }
}
