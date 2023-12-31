//
//  MultiplexLogHandler.swift
//  LarkExtensionServices
//
//  Created by 王元洵 on 2021/4/1.
//

import Foundation

/// 默认的一个LogHandler代理，可以将消息发送给多个不同的LogHandler
struct MultiplexLogHandler: LogHandler {
    /// LogHandler数组
    private var handlers: [LogHandler]

    /// 创建一个 `MultiplexLogHandler`对象.
    ///
    /// - 参数:
    ///    - handlers: 一个实现了LogHandler协议的数组，非空
    init(_ handlers: [LogHandler]) {
        assert(!handlers.isEmpty, "handlers不能为空！")
        self.handlers = handlers
    }

    /// 输出日志
    ///
    /// - 参数:
    ///    - eventMessage: 一个Logger.Message对象，参见@Logger.Message
    func log(eventMessage: Logger.Message) {
        handlers.forEach { $0.log(eventMessage: eventMessage) }
    }
}
