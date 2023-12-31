//
//  ConsoleLogHandler.swift
//  LarkExtensionServices
//
//  Created by 王元洵 on 2021/03/19.
//  Copyright © 2021年 Efficiency Engineering. All rights reserved.
//

import Foundation

/// 默认的控制台日志输出类
final class ConsoleLogHandler: LogHandler {
    @inlinable
    func log(eventMessage: Logger.Message) {
        #if DEBUG
        print("\(eventMessage)")
        #endif
    }
}
