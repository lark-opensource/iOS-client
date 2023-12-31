//
//  LoggerConstruct.swift
//  Lark
//
//  Created by linlin on 2017/4/7.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation

public final class LoggerConstruct {
    public class func createLoggerConsoleAppender(config: LoggerConsoleConfig) -> Appender {
        return LoggerConsoleAppender(config)
    }

    public class func createConsoleAppender(config: XcodeConsoleConfig) -> Appender {
        return ConsoleAppender(config)
    }
}
