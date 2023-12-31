//
//  Log.swift
//  Logger
//
//  Created by lichen on 2018/8/10.
//  Copyright © 2018年 linlin. All rights reserved.
//

import Foundation

public typealias LoggerLog = Log

// disable-lint: long parameters, duplicated code

public final class Log {

    let type: AnyClass

    let vender: () -> LogVendor

    let category: String

    init(_ type: AnyClass, category: String = "", vendor: @escaping () -> LogVendor) {
        self.type = type
        self.vender = vendor
        self.category = category
    }

    public func log(_ event: LogEvent) {
        var e = event
        e.type = type
        e.category = category
        vender().writeEvent(e)
    }
}

// enable-lint: long parameters, duplicated code
