//
//  NSDate+Ext.swift
//  DocsSDK
//
//  Created by nine on 2018/3/13.
//

import Foundation

extension TimeInterval {

    static let formatter: DateFormatter = DateFormatter()

    /// 根据语言，返回时间格式
    private var yyyyMMddSlashFormat: String {
        return "yyyy/MM/dd"
    }

    var yyyyMMddSlash: String {
        let date = Date(timeIntervalSince1970: self)
        Double.formatter.timeZone = TimeZone(abbreviation: "GMT")
        Double.formatter.dateFormat = yyyyMMddSlashFormat
        Double.formatter.locale = NSLocale.current
        let dateString = Double.formatter.string(from: date)
        return dateString
    }
}
