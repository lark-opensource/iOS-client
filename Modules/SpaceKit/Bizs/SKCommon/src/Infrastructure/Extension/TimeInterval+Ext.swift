//
//  NSDate+Ext.swift
//  SpaceKit
//
//  Created by nine on 2018/3/13.
//

import SKFoundation
import SKResource
import LarkTimeFormatUtils
import LarkContainer
import SpaceInterface
import SKInfra

public extension TimeInterval {

    // 为什么要区分 stampDateFormatter 和 feedDateFormatter 和 fileSubTitleDateFormatter?
    // 因为产品需要卡片评论和 feed 页面和 FileVC 页面的时间不同
    // 为什么不合并为一个函数，然后传参使用
    // 因为这两部分是相对独立的日期计算/还有我觉得未来肯定要删除其中一个的，两套逻辑统一，没有必要封装一个通用函数
    // ⬆️我也觉得

    private var space: String {
        return BundleI18n.SKResource.Doc_Facade_Space
    }
    private var at: String {
        return BundleI18n.SKResource.Doc_Facade_At
    }

    // MM:DD
    func shortDate(timeFormatType: Options.TimeFormatType = .short) -> String {
        let date = Date(timeIntervalSince1970: self)
        let options = Options(timeZone: TimeZone.current,
                              is12HourStyle: isEn,
                              timeFormatType: timeFormatType,
                              datePrecisionType: .day,
                              dateStatusType: .absolute,
                              shouldRemoveTrailingZeros: false)
        return TimeFormatUtils.formatDate(from: date, with: options)
    }

    // stampDateFormatter
    /**
     *  24h                               12h
     * <1d: 13:05                    <1d: 下午1:05
     * <2d: 昨天 13:05                <2d: 昨天 下午1:05
     * <same year: 3月15日 13:05          <same year: 3月15日 下午1:05
     * Else: 2019年3月15日 13:05      Else: 2019年3月15日 下午1:05
     */
    func fullDateTime(timeFormatType: Options.TimeFormatType = .long, dateStatusType: Options.DateStatusType = .relative) -> String {
        let date = Date(timeIntervalSince1970: self)
        let options = Options(timeZone: TimeZone.current,
                              is12HourStyle: isEn,
                              timeFormatType: timeFormatType,
                              timePrecisionType: .minute,
                              datePrecisionType: .day,
                              dateStatusType: dateStatusType,
                              shouldRemoveTrailingZeros: false)
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        if let config = try? userResolver.resolve(assert: PowerOptimizeConfigProvider.self), config.dateFormatOptEnable {
            let key = "ccm.common.dateformat" as NSString
            let formatter: DateFormatter
            if let cachedFormatter = Thread.main.threadDictionary.object(forKey: key) as? DateFormatter {
                formatter = cachedFormatter
            } else {
                let newFormatter = TimeFormatUtils.createDateFormatter(with: options)
                Thread.main.threadDictionary.setObject(newFormatter, forKey: key)
                formatter = newFormatter
            }
            return TimeFormatUtils.formatDateTime(from: date, formatter: formatter, options: options)
        } else {
            return TimeFormatUtils.formatDateTime(from: date, with: options)
        }
    }
    
    static let formatter: DateFormatter = DateFormatter()
    var stampDateFormatter: String {
        let date = Date()
        let duration: TimeInterval = date.timeIntervalSince1970 - self

        if duration <= 60 { // 60s 以内定义为 [刚刚]
            // 设计要求just now前面加上空格
            return space + BundleI18n.SKResource.Doc_Facade_JustNow
        }

        if duration <= 3600 { // 60min 以内定义为 [x 分钟前]
            let min: Int = Int(duration / 60)
            return BundleI18n.SKResource.Doc_Facade_MinsAgo(min)
        }

        let commentDate: Date = Date(timeIntervalSince1970: self)

        if Calendar.current.isDateInToday(commentDate) { // 当天 以内定义为 [HH:mm]
            let hour = Int(duration / 3600)
            return BundleI18n.SKResource.Doc_Facade_HoursAgo(hour)
        }

        Double.formatter.resetDateFormatterLocale(isEn: isEn)

        if Calendar.current.isDateInYesterday(commentDate) { // 昨天 以内定义为 [昨天]
            return fullDateTime()
        }
        if Calendar.current.isDateInYear(commentDate) { // 今年之内 定义为 [M/dd HH:mm]
            return space + fullDateTime()
        }

        return shortDate(timeFormatType: .long)
    }

    var feedDateFormatter: String {
        let duration: TimeInterval = Date().timeIntervalSince1970 - self

        if duration <= 60 { // 60s 以内定义为 [刚刚]
            return BundleI18n.SKResource.Doc_Facade_JustNow
        }

        if duration <= 3600 { // 60min 以内定义为 [x 分钟前]
            let min = Int(duration / 60)
            return BundleI18n.SKResource.Doc_Facade_MinsAgo(min)
        }

        let feedDate: Date = Date(timeIntervalSince1970: self)

        Double.formatter.resetDateFormatterLocale(isEn: isEn)

        if Calendar.current.isDateInToday(feedDate) { // 当天 以内定义为 [HH:mm]
            return fullDateTime()
        }

        if Calendar.current.isDateInYesterday(feedDate) { // 昨天 以内定义为 [昨天]
            return fullDateTime(timeFormatType: .short)
        }

        // 其余时间 定义为 [M/dd]
        return shortDate()
    }

    // 特意为创建文档写的时间规则
    var creationTime: String {
        return fullDateTime(dateStatusType: .absolute)
    }

    // **** ⬆️ *****
    // 上面这些 case 刚好符合日语、英语的

//    enum DocsTimeType: Int {
//        case lessThanOneMin = 0
//        case lessThanOneHour
//        case withinToday
//        case withinYesterday
//        case withinThisYear
//        case afterThisYear
//    }

    private var isEn: Bool {
        return DocsSDK.currentLanguage == .en_US
    }
    
    private var isZhCN: Bool {
        return DocsSDK.currentLanguage == .zh_CN
    }
    
    /// 根据语言，返回时间格式 https://bytedance.feishu.cn/space/doc/doccn6vJ6keqLvaz7kXBDR#
    private var yyyymmddFormat: String {
        return isZhCN ? "yyyy年M月d日" : "MMM d, yyyy"
    }
    /// 根据语言，返回时间格式 https://bytedance.feishu.cn/space/doc/doccn6vJ6keqLvaz7kXBDR#
    private var mmddhhmmFormat: String {
        return isZhCN ? "M月d日 HH:mm" : "h:mm a MMM d"
    }

    var fileSubTitleDateFormatter: String {
        return fullDateTime()
    }
}

public extension Calendar {
    func isDateInYear(_ date: Date) -> Bool {
        let theYear = self.component(.year, from: date)
        let thisYear = self.component(.year, from: Date())
        return theYear == thisYear
    }
}

public extension Date {
    /// 月份格式成 Jan
//    0
//    func monthAsString() -> String {
//        let df = DateFormatter()
//        df.setLocalizedDateFormatFromTemplate("MMM")
//        let date = Date()
//        return df.string(from: date)
//    }
}

extension DateFormatter {
    /// 重置locale属性，不然真机上，英文环境格式化不显示AM、PM，而且显示不成12小时制
    ///
    /// - Parameter isEn: 是否是英文环境
    public func resetDateFormatterLocale(isEn: Bool) {
        locale = isEn ? Locale(identifier: "en_US_POSIX") : NSLocale.current
        amSymbol = "AM"
        pmSymbol = "PM"
    }
}
