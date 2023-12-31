//
//  OPError+OPMonitor.swift
//  LarkOPInterface
//
//  Created by yinyuan on 2020/7/14.
//

import Foundation

public extension OPMonitorCode {

    /// 获取一个对应的 OPError
    /// - Parameters:
    ///   - error: 传入一个 Error 信息
    ///   - userInfo: userInfo
    ///   - filename: 自动填入无需传入
    ///   - function: 自动填入无需传入
    ///   - line: 自动填入无需传入
    /// - Returns: OPError
    func error(
        filename: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> OPError {
        OPError.error(
            monitorCode: self,
            filename: filename,
            function: function,
            line: line
        )
    }

    /// 构造一个 OPError，携带一个 message 信息
    /// - Parameters:
    ///   - message: 异常信息
    ///   - error: 传入一个 Error 信息
    ///   - filename: 自动填入无需传入
    ///   - function: 自动填入无需传入
    ///   - line: 自动填入无需传入
    /// - Returns: OPError
    func error(
        message: String,
        filename: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> OPError {
        OPError.error(
            monitorCode: self,
            message: message,
            filename: filename,
            function: function,
            line: line
        )
    }

}
