//
//  TimeFormatProvider.swift
//  LarkMail
//
//  Created by majx on 2020/8/24.
//

import Foundation
import MailSDK
import LarkTimeFormatUtils

class TimeFormatProvider: TimeFormatProxy {
    func relativeDate(_ timestamp: Int64, showTime: Bool) -> String {
        let time = TimeInterval(timestamp)
        if showTime {
            return Date(timeIntervalSince1970: time).lf.formatedTime_v2()
        } else {
            return Date.lf.getNiceDateString(time)
        }
    }

    func mailDraftTimeFormat(_ timestamp: Int64, languageId: String?) -> String {
        let time = TimeInterval(timestamp)
        let date = Date(timeIntervalSince1970: time)
        var lang: Locale?
        if let languageId = languageId {
            lang = Locale(rawValue: languageId)
        }

        let options = Options(timeZone: TimeZone.current,
                              is12HourStyle: !Date.lf.is24HourTime,
                              timeFormatType: .long,
                              timePrecisionType: .minute,
                              datePrecisionType: .day,
                              dateStatusType: .absolute,
                              lang: lang)
        return TimeFormatUtils.formatFullDateTime(from: date, with: options)
    }

    func mailAttachmentTimeFormat(_ timestamp: Int64) -> String {
        let time = TimeInterval(timestamp)
        let date = Date(timeIntervalSince1970: time)
        let options = Options(timeZone: TimeZone.current,
                              is12HourStyle: !Date.lf.is24HourTime,
                              timeFormatType: .short,
                              datePrecisionType: .day,
                              dateStatusType: .absolute)

        return TimeFormatUtils.formatDate(from: date, with: options)
    }

    func mailScheduleSendTimeFormat(_ timestamp: Int64) -> String {
        let time = TimeInterval(timestamp)
        let date = Date(timeIntervalSince1970: time)
        let options = Options(timeZone: TimeZone.current,
                              is12HourStyle: !Date.lf.is24HourTime,
                              shouldShowGMT: true,
                              timeFormatType: .long,
                              timePrecisionType: .minute,
                              datePrecisionType: .day,
                              dateStatusType: .relative)
        return TimeFormatUtils.formatFullDateTime(from: date, with: options)
    }

    func mailSendStatusTimeFormat(_ timestamp: Int64) -> String {
        let dfYear = DateFormatter()
        dfYear.dateFormat = "YYYY"
        let timeYear = dfYear.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
        let nowYear = dfYear.string(from: Date())
        let df = DateFormatter()
        if timeYear == nowYear {
            let dfDay = DateFormatter()
            dfDay.dateFormat = "YYYY/MM/dd"
            let timeDay = dfDay.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
            let nowDay = dfDay.string(from: Date())
            if timeDay == nowDay {
                df.dateFormat = "HH:mm"
            } else {
                df.dateFormat = "MM/dd HH:mm"
            }
        } else {
            df.dateFormat = "YYYY/MM/dd HH:mm"
        }
        return df.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
    }
    
    func mailLargeAttachmentTimeFormat(_ timestamp: Int64) -> String {
        let df = DateFormatter()
        df.dateFormat = "YYYY-MM-dd HH:mm"
        return df.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
    }

    func mailReadReceiptTimeFormat(_ timestamp: Int64, languageId: String?) -> String {
        let time = TimeInterval(timestamp)
        let date = Date(timeIntervalSince1970: time)
        var lang: Locale?
        if let languageId = languageId {
            lang = Locale(rawValue: languageId)
        }

        let options = Options(timeZone: TimeZone.current,
                              is12HourStyle: !Date.lf.is24HourTime,
                              shouldShowGMT: true,
                              timeFormatType: .long,
                              timePrecisionType: .second,
                              datePrecisionType: .day,
                              dateStatusType: .absolute,
                              lang: lang)
        return TimeFormatUtils.formatFullDateTime(from: date, with: options)
    }
}
