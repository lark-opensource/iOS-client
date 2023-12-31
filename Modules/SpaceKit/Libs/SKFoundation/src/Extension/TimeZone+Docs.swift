//
//  TimeZone+Docs.swift
//  SKFoundation
//
//  Created by zengsenyuan on 2022/6/9.
//  


import Foundation

extension TimeZone: DocsExtensionCompatible {}

public extension DocsExtension where BaseType == TimeZone {
    
    /// 获取格式化的 abbreviation
    /// - Parameter id: 时区 id
    /// - Returns: 格式化后的 abbreviation etc: CMT+00:00
    public static func formatedAbbreviation(id: String, for date: Date = Date()) -> String? {
        guard let timeZone = TimeZone(identifier: id) else {
            return nil
        }
        /// 格式化
        func makeAbbrFourNumStyle(hours: Int, minutes: Int) -> String? {
            let operaor = hours >= 0 ? "+" : "-"
            let absHours = abs(hours)
            let absMinutes = abs(minutes)
            switch (absHours >= 10, absMinutes >= 10) {
            case (true, true):
                return "GMT\(operaor)\(absHours):\(absMinutes)"
            case (true, false):
                return "GMT\(operaor)\(absHours):0\(absMinutes)"
            case (false, true):
                return "GMT\(operaor)0\(absHours):\(absMinutes)"
            case (false, false):
                return "GMT\(operaor)0\(absHours):0\(absMinutes)"
            }
        }
        let secondsFromGMT = timeZone.secondsFromGMT(for: date)
        let hours = (secondsFromGMT / 3600)
        let minutes = (secondsFromGMT % 3600) / 60
        return makeAbbrFourNumStyle(hours: hours, minutes: minutes)
    }
 
    /// 获取时区的 abbreviation，系统的有时会有问题
    /// - Returns: 格式化后的 abbreviation etc: CMT+00:00
    public func gmtAbbreviation(for date: Date = Date()) -> String {
        let secondsFromGMT = base.secondsFromGMT(for: date)
        let hours = (secondsFromGMT / 3600)
        let minutes = (secondsFromGMT % 3600) / 60
        func makeAbbrSimpleStyle(hours: Int, minutes: Int) -> String {
            let operaor = hours >= 0 ? "+" : "-"
            let absHours = abs(hours)
            let absMinutes = abs(minutes)
            switch (absHours > 0, absMinutes > 0) {
            case (true, true):
                return "GMT\(operaor)\(absHours):\(absMinutes)"
            case (true, false):
                return "GMT\(operaor)\(absHours)"
            case (false, true):
                return "GMT\(operaor)0:\(absMinutes)"
            case (false, false):
                return "GMT"
            }
        }
        return makeAbbrSimpleStyle(hours: hours, minutes: minutes)
    }
}
