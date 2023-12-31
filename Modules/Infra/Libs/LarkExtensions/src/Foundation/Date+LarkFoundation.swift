//
//  Date+Extensions.swift
//  LarkExtensions
//
//  Created by liuwanlin on 2018/4/26.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import LarkCompatible
import LarkTimeFormatUtils

extension Date: LarkFoundationExtensionCompatible {}

public extension LarkFoundationExtension where BaseType == Date {
    internal typealias CacheKey = NSString
    internal typealias Formater = (CacheKey, TimeInterval) -> NSString
    internal typealias GetFormater = () -> Formater
    internal typealias ReadCache = (GetFormater, CacheKey, TimeInterval) -> NSString

    /// 年月日(已国际化)
    func formatedOnlyDate() -> String {
        TimeFormatUtils.formatDate(from: self.base, with: Options(timeFormatType: .long, datePrecisionType: .day))
    }

    /// 年月(已国际化)
    func formatedOnlyDateWithoutDay() -> String {
        TimeFormatUtils.formatDate(from: self.base, with: Options(timeFormatType: .long, datePrecisionType: .month))
    }

    /// 时分/时分秒
    func formatedOnlyTime(
        accurateToSecond: Bool = false,
        timeZone: TimeZone = TimeZone.autoupdatingCurrent
    ) -> String {
        let options = Options(timeZone: timeZone,
                              is12HourStyle: !Date.lf.is24HourTime,
                              timePrecisionType: accurateToSecond ? .second : .minute)
        return TimeFormatUtils.formatTime(from: self.base, with: options)
    }

    func formatedDate(onlyShowDay: Bool = true) -> String {
        if DateUtil.isToday(self.base) {
            if onlyShowDay {
                return TimeFormatUtils.formatDate(from: self.base, with: Options(dateStatusType: .relative))
            } else {
                return formatedStr_v4()
            }
        }
        return formatedStr_v4()
    }

    func formatedTime_v2(accurateToSecond: Bool = false) -> String {
        let options = Options(is12HourStyle: !Date.lf.is24HourTime,
                              timeFormatType: .long,
                              timePrecisionType: accurateToSecond ? .second : .minute,
                              dateStatusType: .relative)
        return TimeFormatUtils.formatDateTime(from: self.base, with: options)
    }

    // __is_24_hour_time_style 是全局状态数据，用户无关，不进行 lark_storage 检查
    // lint:disable lark_storage_check
    private static var is24HourTimeKey: String { "__is_24_hour_time_style" }
    static var is24HourTime: Bool = UserDefaults.standard.bool(forKey: is24HourTimeKey) {
        didSet {
            if is24HourTime != oldValue {
                cleanResultCache()
                UserDefaults.standard.set(is24HourTime, forKey: is24HourTimeKey)
            }
        }
    }
    // lint:enable lark_storage_check

    // 今天 H:mm, 昨天 Yesterday, 今年 5-23 23May, 去年及以前 2017年3月25日 2017/3/25
    func formatedStr_v4() -> String {
        let options = Options(is12HourStyle: !Date.lf.is24HourTime,
                              timeFormatType: .short,
                              timePrecisionType: .minute,
                              dateStatusType: .relative)
        return TimeFormatUtils.formatDateTime(from: self.base, with: options)
    }

    func cacheFormat(_ keyPrefix: String, formater: @escaping (Date) -> String) -> String {
        return self.base.timeIntervalSince1970.lf.cacheFormat(keyPrefix, formater: formater)
    }

    static func getNiceDateString(_ time: TimeInterval) -> String {
        let key = "\(time)" as NSString
        return getNiceDateStringWithCache({ { Date(timeIntervalSince1970: $1).lf.formatedStr_v4() as NSString } },
                                          key,
                                          time) as String
    }

    static func cleanResultCache() {
        resultCache?.removeAllObjects()
    }

    private static let getNiceDateStringWithCache = memoizeNiceDateString()

    /// 该方法仅执行一次，为了生成缓存和第一次调用时间
    ///
    /// - Returns: 一个闭包，第一个参数是一个用与获取Formater的闭包，Formatter也是一个闭包
    private static func memoizeNiceDateString() -> ReadCache {
        let cache = NSCache<NSString, NSString>()
        cache.countLimit = 500
        resultCache = cache

        // 语言切换时：需要清除缓存的时间数据
        _ = NotificationCenter.default.addObserver(forName: .preferLanguageChange, object: nil, queue: nil) { _ in
            LarkFoundationExtension.cleanResultCache()
        }

        // 第一次调用的时间所在天的0点时间
        var firstCallTime = todayStartTime
        let oneDayMinutes: TimeInterval = 24 * 60 * 60
        return { getFormater, key, time in
            if Date().timeIntervalSince1970 - firstCallTime >= oneDayMinutes {
                cache.removeAllObjects()
                firstCallTime = todayStartTime
            }

            if let obj = cache.object(forKey: key) {
                return obj
            }
            let result = getFormater()(key, time)
            cache.setObject(result, forKey: key)
            return result
        }
    }

    private static var resultCache: NSCache<NSString, NSString>?

    private static var todayStartTime: TimeInterval {
        let calendar = NSCalendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        let startDate = calendar.date(from: components)
        return startDate!.timeIntervalSince1970
    }
}

extension TimeInterval: LarkFoundationExtensionCompatible {}

public extension LarkFoundationExtension where BaseType == TimeInterval {
    func cacheFormat(_ keyPrefix: String, formater: @escaping (Date) -> String) -> String {
        let key = "\(keyPrefix)_\(self.base)" as NSString

        return Date.lf.getNiceDateStringWithCache({ { formater(Date(timeIntervalSince1970: $1)) as NSString } },
                                                  key,
                                                  self.base) as String
    }
}

extension Int64: LarkFoundationExtensionCompatible {}

public extension LarkFoundationExtension where BaseType == Int64 {
    func cacheFormat(_ keyPrefix: String, formater: @escaping (Date) -> String) -> String {
        return TimeInterval(self.base).lf.cacheFormat(keyPrefix, formater: formater)
    }
}

enum DateUtil {
    static func isToday(_ date: Date) -> Bool {
        let calendar = Calendar.autoupdatingCurrent
        return calendar.isDateInToday(date)
    }

    static func isYesterday(_ date: Date) -> Bool {
        let calendar = Calendar.autoupdatingCurrent
        return calendar.isDateInYesterday(date)
    }

    static func weekOfYear(_ date: Date) -> Int {
        let calendar = Calendar.autoupdatingCurrent
        return calendar.component(.weekOfYear, from: date)
    }
}
