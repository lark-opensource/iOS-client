//
//  OPError+OPDiagnoseRunner.swift
//  OPSDK
//
//  Created by 尹清正 on 2021/2/18.
//

import Foundation
import LarkOPInterface

fileprivate let DiagnoseRunnerErrOpenMsgKey = "diagnose_runner_err_open_msg"

public extension OPError {

    /// 为diagnoseRunner定义的OPError初始化方式，多了openMessage的信息
    /// - Parameters:
    ///   - monitorCode: OPMonitorCode
    ///   - message: String
    ///   - openMessage: 可以对外开放的错误信息，将被存入OPError的userinfo中，键为DebugCommandErrOpenMsgKey
    ///   - filename: 自动填入文件名称
    ///   - function: 自动填入所在函数
    ///   - line: 自动填入所在行数
    /// - Returns: OPError
    static func diagnoseRunnerError(
        monitorCode: OPMonitorCode,
        message: String,
        openMessage: String,
        filename: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) -> OPError {
        return __OPErrorNew(monitorCode,
                            nil,
                            [DiagnoseRunnerErrOpenMsgKey: openMessage],
                            filename.cString(using: .utf8),
                            function.cString(using: .utf8),
                            line)
    }

    /// 返回diagnoseRunner的Error系统中的openMessage信息
    @objc var diagnoseRunnerOpenMsg: String? {
        return self.userInfo[DiagnoseRunnerErrOpenMsgKey] as? String
    }

}
