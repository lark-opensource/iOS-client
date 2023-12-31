//
//  LogHandler.swift
//  LarkExtensionServices
//
//  Created by 王元洵 on 2021/4/1.
//

import Foundation

/// 日志输出对象协议
/// 符合该协议的对象将可以用于各个模块输出日志
public protocol LogHandler {

    /// 实际记录日志的方法
    ///
    /// - Parameter eventMessage: 日志消息 参考：@Logger.Message
    func log(eventMessage: Logger.Message)
}
