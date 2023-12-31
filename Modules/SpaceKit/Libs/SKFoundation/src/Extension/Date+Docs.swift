//
//  Date+Docs.swift
//  DocsCommon
//
//  Created by weidong fu on 28/11/2017.
//

import Foundation
extension Date: DocsExtensionCompatible {}


public extension DocsExtension where BaseType == Date {

//    class func cal(execTimeWith action: () -> Void, finish: (_ cost: String) -> Void) {
//        let date = Date()
//        action()
//        let executionTime = Date().timeIntervalSince(date)
//        finish(String(format: "%.2f", executionTime))
//    }
    
    
    /// 时区之前的时间转换
    /// - Parameters:
    ///   - fromTimeZone: 原来的时区
    ///   - toTimeZone: 转换的时区
    /// - Returns: 转换后的时间
    public func convert(fromTimeZone: TimeZone = .current, toTimeZone: TimeZone) -> Date? {
        let dateFormatter = DateFormatter()
        // 时间格式
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = fromTimeZone
        let dateFormatted = dateFormatter.string(from: base)
        dateFormatter.timeZone = toTimeZone
        return dateFormatter.date(from: dateFormatted)
    }
}

extension Date {

    public var toLocalTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: self)
    }

    public var timestamp: String {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let second = Int(timeInterval)
        return "\(second)"
    }

    public var milliTimestamp: String {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval * 1000))
        return "\(millisecond)"
    }
}
