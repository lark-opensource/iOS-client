//
//  CalendarLogger.swift
//  Calendar
//
//  Created by 朱衡 on 2018/11/8.
//  Copyright © 2018 EE. All rights reserved.
//

import Foundation
import LKCommonsLogging
import RustPB

public typealias RustCommand = RustPB.Basic_V1_Command
private struct UILogger {}
let calendarLogCategory = "lark.calendar"
private let calendarLogger = Logger.log(UILogger.self, category: calendarLogCategory)

/*
日志格式
[infiniteScrollView(scrollView:willDisplay:at:)]    函数
(DaysView.swift(300)                                行数
UILogger(lark.calendar): UIOperation                分类
[message: load panel index: 0,                      message: 自定义信息
opt_type: threeToRight]                             opt_type: 记录用户行为，字段三端统一
 */
public func operationLog(
            message: String? = nil,
            optType: String? = nil,
            file: String = #fileID,
            function: String = #function,
            line: Int = #line) {
    var additon = [String: String]()
    if let msg = message {
        additon["message"] = msg
    }
    if let opt = optType {
        additon["opt_type"] = opt
    }
    calendarLogger.debug("UIOperation",
                         additionalData: additon,
                         file: file,
                         function: function,
                         line: line)
}

public func assertionFailureLog(_ message: String? = nil,
                         file: String = #fileID,
                         function: String = #function,
                         line: Int = #line) {
//    assertionFailure(message ?? "")
    normalErrorLog(message,
                   file: file,
                   function: function,
                   line: line)
}

public func assertLog(_ shouldBeTrue: Bool,
               _ message: String = "",
               file: String = #fileID,
               function: String = #function,
               line: Int = #line) {
//    assert(shouldBeTrue, message)
    if !shouldBeTrue {
        normalErrorLog(message,
                       file: file,
                       function: function,
                       line: line)
    }
}

public func normalErrorLog(_ message: String? = nil,
                    type: String? = nil,
                    file: String = #fileID,
                    function: String = #function,
                    line: Int = #line) {
    var additionalData: [String: String]?
    if let msg = message {
        additionalData = ["error": msg]
    }

    if let type = type {
        additionalData = ["type": type]
    }

    calendarLogger.error(function,
                         additionalData: additionalData,
                         file: file,
                         function: function,
                         line: line)
}
