//
//  SandboxError.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

/// An error that can be thrown by Sandbox.
public enum SandboxError: Error {
    /// 系统错误
    case system(action: SandboxAction, underlying: Error)

    /// 创建文件失败
    case createFailure(message: String)

    /// unexpected
    case performReadingUnexpected(message: String)

    /// unexpected
    case performWritingUnexpected(message: String)

    /// 读操作
    case typeRead(type: String, message: String)

    /// 写操作
    case typeWrite(type: String, message: String)

    /// 缺少加密套件
    case missingCipher
}

extension SandboxError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .system(let action, let underlying):
            return "base error. action: \(action), underlying: \(underlying)"
        case .performReadingUnexpected(let message):
            return "perform reading failed: " + message
        case .performWritingUnexpected(let message):
            return "perform writing failed: " + message
        case .createFailure(let message):
            return "create failed: " + message
        case .typeRead(let type, let message):
            return "\(type) read failed: \(message)"
        case .typeWrite(let type, let message):
            return "\(type) write failed: \(message)"
        case .missingCipher:
            return "missing cipher"
        }
    }

}
