//
//  NetworkError.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/9/7.
//

import Foundation

/// 通用错误处理
public protocol NetworkErrorHandler: AnyObject {
    /// 通用错误处理，处理成功返回true
    func handleBizError(httpClient: HttpClient, error: RustBizError) -> Bool
}

/// NetworkError
public enum NetworkError: String, Error, Hashable, Codable, CustomStringConvertible {
    case unknown
    case rustNotFound
    case noElements
    case unsupportedType

    public var description: String {
        rawValue
    }
}

/// 服务器返回的错误信息
public struct RustBizError: Error, Codable, CustomStringConvertible {
    /// 错误 code
    /// - https://bytedance.feishu.cn/wiki/wikcn6ZoPljlTe3GSBiCECR5EKe
    public var code: Int
    ///  用于 debug 的错误信息
    public var debugMessage: String
    /// 用于显示的错误信息
    public var displayMessage: String

    /// 是否被通用错误逻辑处理过
    public var isHandled = false
    public var msgInfo: MsgInfo?
    public var content: String = ""
    public var i18nValues: [String: String] = [:]

    /// - parameter msgInfo: `MsgInfo`的jsonString
    public init(code: Int, debugMessage: String, displayMessage: String, msgInfo: String?) {
        self.code = code
        self.debugMessage = debugMessage
        self.displayMessage = displayMessage
        if let s = msgInfo, !s.isEmpty {
            self.msgInfo = try? MsgInfo(jsonString: s)
        }
    }

    public var description: String {
        if let msgInfo = msgInfo {
            return "RustBizError(code: \(code), debugMessage: \(debugMessage), msgInfo: \(msgInfo))"
        } else {
            return "RustBizError(code: \(code), debugMessage: \(debugMessage), displayMessage: \(displayMessage))"
        }
    }
}

extension RustBizError: RawRepresentable {
    public init?(rawValue: Int) {
        // nolint-next-line: magic number
        if rawValue < 240000, rawValue >= 10000 {
            self.init(code: rawValue, debugMessage: "", displayMessage: "", msgInfo: nil)
        } else {
            return nil
        }
    }

    public var rawValue: Int {
        code
    }
}

extension RustBizError: Hashable {
    public static func == (lhs: RustBizError, rhs: RustBizError) -> Bool {
        return lhs.code == rhs.code
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
    }
}
