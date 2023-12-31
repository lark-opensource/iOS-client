//
//  OPError.swift
//  LarkOPInterface
//
//  Created by yinyuan on 2020/7/9.
//

import Foundation
import ECOProbe

public extension OPError {
    
    /// 构造一个 OPError
    /// - Parameters:
    ///   - monitorCode: monitorCode 必填
    ///   - userInfo: userInfo 自定义信息
    ///   - filename: 自动填入无需传入
    ///   - function: 自动填入无需传入
    ///   - line: 自动填入无需传入
    /// - Returns: OPError
    class func error(
        monitorCode: OPMonitorCode,
        userInfo: [String: Any]? = nil,
        filename: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> OPError {
        __OPErrorNew(
            monitorCode,
            nil,
            userInfo,
            filename.cString(using: .utf8),
            function.cString(using: .utf8),
            line
        )
    }
    
    /// 构造一个 OPError，携带一个 message 信息
    /// - Parameters:
    ///   - monitorCode: monitorCode 必填
    ///   - message: 异常信息
    ///   - filename: 自动填入无需传入
    ///   - function: 自动填入无需传入
    ///   - line: 自动填入无需传入
    /// - Returns: OPError
    class func error(
        monitorCode: OPMonitorCode,
        message: String,
        filename: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> OPError {
        OPError.error(
            monitorCode: monitorCode,
            userInfo: [NSLocalizedDescriptionKey: message],
            filename: filename,
            function: function,
            line: line
        )
    }
}

extension Error {
    
    /// 构造一个 OPError
    /// - Parameters:
    ///   - monitorCode: monitorCode 必填
    ///   - userInfo: userInfo 自定义信息
    ///   - filename: 自动填入无需传入
    ///   - function: 自动填入无需传入
    ///   - line: 自动填入无需传入
    /// - Returns: OPError
    public func newOPError(
        monitorCode: OPMonitorCode,
        userInfo: [String: Any]? = nil,
        filename: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> OPError {
        __OPErrorNew(
            monitorCode,
            self,
            userInfo,
            filename.cString(using: .utf8),
            function.cString(using: .utf8),
            line
        )
    }
    
    /// 构造一个 OPError，携带一个 message 信息
    /// - Parameters:
    ///   - monitorCode: monitorCode 必填
    ///   - message: 异常信息
    ///   - filename: 自动填入无需传入
    ///   - function: 自动填入无需传入
    ///   - line: 自动填入无需传入
    /// - Returns: OPError
    public func newOPError(
        monitorCode: OPMonitorCode,
        message: String,
        filename: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> OPError {
        newOPError(
            monitorCode: monitorCode,
            userInfo: [NSLocalizedDescriptionKey: message],
            filename: filename,
            function: function,
            line: line
        )
    }
}
