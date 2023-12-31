//
//  ChineseCalendar.swift
//  Calendar
//
//  Created by yantao on 2020/3/5.
//

// Included OSS: taro-dates
// Copyright (c) Microsoft Corporation.
// spdx license identifier: MIT License

import Foundation
import CalendarFoundation
import ThreadSafeDataStructure
import CTFoundation

final class ChineseCalendar {

    // 24节气数据缓存
    private var solarTermCache: SafeDictionary<IndexOfYear, Int> = [:] + .readWriteLock

    init() {
        // 初始化时预生成本年的数据
        yearCacheList.append(generateYearCache(year: 2020, baseOffsetDay: 43_823))
        pthread_rwlock_init(&rwLock, nil)
    }

    deinit {
        pthread_rwlock_destroy(&rwLock)
    }

    // MARK: - 农历缓存优化

    private struct YearCache {
        let year: Int
        // 本年第一天对应的dayOffset
        let baseDayOffset: Int
        // 下一年第一天对应的dayOffset
        let nextYearBaseDayOffset: Int
        // 对应年闰哪个月，没有为0
        let leapMonth: Int
        // 一年13个月（可能有闰月，闰月紧随被闰月份后面），每个月第一天对应的dayOffset
        let monthBaseDayOffsets: [Int]
    }

    // 线程不安全，用rwLock管理
    private var yearCacheList = [YearCache]()
    private var rwLock = pthread_rwlock_t()

    // 入口方法，替换单次接口中的getMonthDay(offsetInDay:)方法
    func getLunarYearMonthDay(dayOffset: Int) -> MonthDay? {
        var cache = tryGetYearCache(dayOffset: dayOffset)
        var count = 0
        while cache == nil, count < 1000 {
            createYearCache(dayOffset: dayOffset)
            cache = tryGetYearCache(dayOffset: dayOffset)
            count += 1
        }

        guard let cache = cache else {
            assertionFailure()
            return nil
        }

        var monthIndex = (dayOffset - cache.baseDayOffset) / 30
        guard var monthBaseDayOffset = cache.monthBaseDayOffsets[safeIndex: monthIndex] else { return nil }
        let monthUpperIndex = cache.leapMonth > 0 ? 12 : 11
        while monthBaseDayOffset <= dayOffset {
            if monthIndex == monthUpperIndex {
                return MonthDay(
                    year: cache.year,
                    month: 12,
                    day: dayOffset - monthBaseDayOffset + 1,
                    isLeap: cache.leapMonth == 12
                )
            }
            monthIndex += 1
            guard let newOffset = cache.monthBaseDayOffsets[safeIndex: monthIndex] else {
                assertionFailure()
                return nil
            }
            monthBaseDayOffset = newOffset
        }
        guard let index = cache.monthBaseDayOffsets[safeIndex: monthIndex - 1] else { return nil }

        return MonthDay(
            year: cache.year,
            month: cache.leapMonth > 0 && cache.leapMonth < monthIndex ? monthIndex - 1 : monthIndex,
            day: dayOffset - index + 1,
            isLeap: cache.leapMonth > 0 && cache.leapMonth == monthIndex - 1
        )
    }

    // 仅供测试调用
    func resetYearCacheList() {
        yearCacheList = [generateYearCache(year: 2020, baseOffsetDay: 43_823)]
    }

    private func tryGetYearCache(dayOffset: Int) -> YearCache? {
        defer {
            pthread_rwlock_unlock(&rwLock)
        }
        pthread_rwlock_rdlock(&rwLock)

        guard let first = yearCacheList.first,
              let last = yearCacheList.last,
              dayOffset >= first.baseDayOffset && dayOffset < last.nextYearBaseDayOffset
        else {
            return nil
        }
        // 348 = 29 * 12
        var currentYearIndex = (dayOffset - first.baseDayOffset) / 348
        currentYearIndex = min(currentYearIndex, yearCacheList.count - 1)
        var currentYear = yearCacheList[currentYearIndex]
        while dayOffset < currentYear.baseDayOffset && currentYearIndex > 0 {
            currentYearIndex -= 1
            currentYear = yearCacheList[currentYearIndex]
        }
        guard dayOffset >= currentYear.baseDayOffset && dayOffset < currentYear.nextYearBaseDayOffset else {
            assertionFailure()
            return nil
        }
        return currentYear
    }

    private func createYearCache(dayOffset: Int) {
        defer {
            pthread_rwlock_unlock(&rwLock)
        }
        pthread_rwlock_wrlock(&rwLock)

        if let first = yearCacheList.first, dayOffset < first.baseDayOffset {
            let yearCache = generateYearCacheBackword(year: first.year - 1, nextYearBaseOffsetDay: first.baseDayOffset)
            yearCacheList.insert(yearCache, at: yearCacheList.startIndex)
        }

        if let last = yearCacheList.last, dayOffset >= last.nextYearBaseDayOffset {
            let yearCache = generateYearCache(year: last.year + 1, baseOffsetDay: last.nextYearBaseDayOffset)
            yearCacheList.append(yearCache)
        }
    }

    // 向后计算，例：2020->2021
    private func generateYearCache(year: Int, baseOffsetDay: Int) -> YearCache {
        /*
         0xf: 1111
         0x8000: 1000 0000 0000 0000
         0x8: 1000
         */
        let yearInfo = lunarYearInfo[year - 1900]
        let leapMonth = yearInfo & 0xf // 对应年闰月月份
        var month = 1
        var monthBaseDayOffsets: [Int?] = Array(repeating: nil, count: 13)
        var dayOffset = baseOffsetDay
        // 从左至右依次与yearInfo的每一位进行 & 操作，读出每个月的天数
        // 具体参考lunarYearInfo变量的注释
        var i = 0x8000
        while i > 0x8 {
            monthBaseDayOffsets[month - 1] = dayOffset
            if leapMonth > 0 && leapMonth + 1 == month {
                dayOffset += ((yearInfo & 0x10000) > 0) ? 30 : 29
            } else {
                dayOffset += ((yearInfo & i) > 0) ? 30 : 29
                i >>= 1
            }
            month += 1
        }

        return YearCache(
            year: year,
            baseDayOffset: baseOffsetDay,
            nextYearBaseDayOffset: dayOffset,
            leapMonth: leapMonth,
            monthBaseDayOffsets: monthBaseDayOffsets.map { $0 ?? 30 }
        )
    }

    // 向前计算，例：2020->2019
    private func generateYearCacheBackword(year: Int, nextYearBaseOffsetDay: Int) -> YearCache {
        /*
        0xf: 1111
        0x10: 1 0000
        0x10000: 1 0000 0000 0000 0000
        */
        let yearInfo = lunarYearInfo[year - 1900]
        let leapMonth = yearInfo & 0xf // 对应年闰月月份
        var month = leapMonth > 0 ? 13 : 12
        var monthBaseDayOffsets: [Int?] = Array(repeating: nil, count: 13)
        var dayOffset = nextYearBaseOffsetDay
        // 从左至右依次与yearInfo的每一位进行 & 操作，读出每个月的天数
        // 具体参考lunarYearInfo变量的注释
        var i = 0x10
        while i < 0x10000 {
            if leapMonth > 0 && leapMonth + 1 == month {
                dayOffset -= ((yearInfo & 0x10000) > 0) ? 30 : 29
            } else {
                dayOffset -= ((yearInfo & i) > 0) ? 30 : 29
                i <<= 1
            }
            monthBaseDayOffsets[month - 1] = dayOffset
            month -= 1
        }

        return YearCache(
            year: year,
            baseDayOffset: dayOffset,
            nextYearBaseDayOffset: nextYearBaseOffsetDay,
            leapMonth: leapMonth,
            monthBaseDayOffsets: monthBaseDayOffsets.map { $0 ?? 30 }
        )
    }

    // MARK: - 单次接口相关

    func getDisplayElement(julianDay: Int) -> String {
        guard let monthDay = getMonthDay(julianDay: julianDay) else {
            return ""
        }

        // 优先级：节日>节气>月份>日期
        let festival = getFestival(year: monthDay.year, month: monthDay.month, day: monthDay.day)
        if !festival.isEmpty {
            return festival
        }

        let (year, month, day) = JulianDayUtil.yearMonthDay(from: julianDay)
        let solarTerm = getTwentyFourSolarTerm(year: year, month: month, day: day)
        if !solarTerm.isEmpty {
            return solarTerm
        }

        let (_, monthAlia, dayAlia) = getAlias(year: monthDay.year,
                                               month: monthDay.month,
                                               day: monthDay.day,
                                               isLeap: monthDay.isLeap)
        return dayAlia == "初一" ? monthAlia : dayAlia
    }

    func getDisplayElement(date: Date) -> String {
        guard let monthDay = getMonthDay(date: date) else {
            return ""
        }

        // 优先级：节日>节气>月份>日期
        let festival = getFestival(year: monthDay.year, month: monthDay.month, day: monthDay.day)
        if !festival.isEmpty {
            return festival
        }

        let solarTerm = getTwentyFourSolarTerm(
            year: date.get(.year),
            month: date.get(.month),
            day: date.get(.day)
        )
        if !solarTerm.isEmpty {
            return solarTerm
        }

        let (_, monthAlia, dayAlia) = getAlias(year: monthDay.year,
                                               month: monthDay.month,
                                               day: monthDay.day,
                                               isLeap: monthDay.isLeap)
        return dayAlia == "初一" ? monthAlia : dayAlia
    }

    private func getMonthDay(julianDay: Int) -> MonthDay? {
        // 获取当前date和basejulianDay(1900-01-31->农历1900年正月初一)的差值，单位是天
        guard let offsetInDay = getOffsetInDay(julianDay: julianDay) else {
            return nil
        }

        if let result = getLunarYearMonthDay(dayOffset: offsetInDay) {
            return result
        }
        return getMonthDay(offsetInDay: offsetInDay)
    }

    // 根据传入的date计算农历年月日
    private func getMonthDay(date: Date) -> MonthDay? {
        // 获取当前date和baseDate(1900-01-31->农历1900年正月初一)的差值，单位是天
        guard let offsetInDay = getOffsetInDay(date: date) else {
            return nil
        }

        if let result = getLunarYearMonthDay(dayOffset: offsetInDay) {
            return result
        }
        return getMonthDay(offsetInDay: offsetInDay)
    }

    // 公共部分
    func getMonthDay(offsetInDay: Int) -> MonthDay {
        // 从1900年开始遍历，每次减去当年的天数，直到确定当前年
        let (year, offsetOfCurrentYear) = getYearByOffsetInDay(offsetInDay: offsetInDay)

        // 从本年1月开始遍历，每次减去当月天数，直到确定当前月以及当前天
        let (month, day, isLeap) = getMonthAndDayByOffsetInDay(offsetOfCurrentYear: offsetOfCurrentYear,
                                                               year: year)
        return MonthDay(year: year, month: month, day: day, isLeap: isLeap)
    }

    private func getOffsetInDay(julianDay: Int) -> Int? {
        // 1901.01.01 < julianDay < 2099.01.01
        guard julianDay > 2_415_386, julianDay < 2_487_705 else {
            // 农历数据从1901 ~ 2099 其它范围返回空
            return nil
        }
        // 2415051 指 1900-01-31（农历1900年正月初一）正午（12:00）时刻对应的儒略日
        let basejulianDay = 2_415_051
        return julianDay - basejulianDay
    }

    func getOffsetInDay(date: Date) -> Int? {
        let date = TimeZoneUtil.dateTransForm(srcDate: date, srcTzId: TimeZone.current.identifier, destTzId: "UTC")
        let timeStamp = date.timeIntervalSince1970
        // 1901.01.01 < timeStamp < 2099.01.01
        guard timeStamp > -2_177_481_600, timeStamp < 4_070_880_000 else {
            assertionFailure()
            return nil
        }
        // -2206396800.0 指UTC下 1900-01-31（农历1900年正月初一） 零点时刻对应的timeStamp
        let baseTimeStamp = TimeInterval(exactly: -2_206_396_800.0)!
        let secondsInOneDay: Double = 86_400
        let offsetInDay = Int((timeStamp - baseTimeStamp) / secondsInOneDay)
        return offsetInDay
    }

    private func getYearByOffsetInDay(offsetInDay: Int) -> (Int, Int) {

        var offsetInDay = offsetInDay
        var year = 1900
        var temp = 0

        while offsetInDay > 0 {
            temp = lunarYearDays(lunarYear: year)
            offsetInDay -= temp
            year += 1
        }

        if offsetInDay < 0 {
            offsetInDay += temp
            year -= 1
        }

        let offsetOfCurrentYear = offsetInDay

        return (year, offsetOfCurrentYear)
    }

    private func getMonthAndDayByOffsetInDay(offsetOfCurrentYear: Int, year: Int) -> (Int, Int, Bool) {
        var offsetOfCurrentYear = offsetOfCurrentYear
        let leapMonth = leapMonthInYear(lunarYear: year)
        var isLeap = false
        var temp = 0
        var month = 1

        while month < 13 && offsetOfCurrentYear > 0 {
            if leapMonth > 0 && month == ( leapMonth + 1 ) && !isLeap {
                month -= 1
                isLeap = true
                temp = leapMonthDays( lunarYear: year )
            } else {
                temp = monthDays( lunarYear: year, lunarMonth: month )
            }

            // 解除闰月
            if isLeap == true && month == ( leapMonth + 1 ) {
                isLeap = false
            }

            offsetOfCurrentYear -= temp
            month += 1
        }

        if offsetOfCurrentYear == 0 && leapMonth > 0 && month == leapMonth + 1 {
            if isLeap {// 闰月结尾
                isLeap = false
            } else {// 闰月开头
                isLeap = true
                month -= 1
            }
        }

        if offsetOfCurrentYear < 0 {
            offsetOfCurrentYear += temp
            month -= 1
        }

        let day = offsetOfCurrentYear + 1

        return (month, day, isLeap)
    }

    // 批量接口是基于单次接口的，appendCount可以理解为在计算完单次接口以后，后面需要再额外计算的元素数量
    func getDisplayElementList(date: Date, appendCount: Int) -> [LunarComponents] {

        let monthDayList = getMonthDayList(date: date, appendCount: appendCount)

        var result: [LunarComponents] = []

        for monthDay in monthDayList {
            // 优先级：节日>节气>月份>日期
            let festival = getFestival(year: monthDay.year, month: monthDay.month, day: monthDay.day)

            let (_, monthAlia, dayAlia) = getAlias(year: monthDay.year,
                                                   month: monthDay.month,
                                                   day: monthDay.day,
                                                   isLeap: monthDay.isLeap)
            let dateText = dayAlia == "初一" ? monthAlia : dayAlia
            result.append(LunarComponents(festival: festival.isEmpty ? nil : festival,
                                         solarTerm: nil,
                                         dateText: dateText))
        }
        return result
    }

    private func getMonthDayList(julianDay: Int, appendCount: Int) -> [MonthDay] {
        guard let offsetInDay = getOffsetInDay(julianDay: julianDay) else {
            return []
        }
        return getMonthDayList(offsetInDay: offsetInDay, appendCount: appendCount)
    }

    private func getMonthDayList(date: Date, appendCount: Int) -> [MonthDay] {
        guard let offsetInDay = getOffsetInDay(date: date) else {
            return []
        }
        return getMonthDayList(offsetInDay: offsetInDay, appendCount: appendCount)
    }

    // 公共部分
    private func getMonthDayList(offsetInDay: Int, appendCount: Int) -> [MonthDay] {
        let yearOffsetList = getYearOffsetList(offsetInDay: offsetInDay, appendCount: appendCount)
        var result: [MonthDay] = []
        for yearOffset in yearOffsetList {
            result += getMonthDayList(offsetOfCurrentYear: yearOffset.offset,
                                      year: yearOffset.year,
                                      appendCount: yearOffset.appendCount)
        }
        return result
    }

    private func getYearOffsetList(offsetInDay: Int, appendCount: Int) -> [YearOffset] {

        var (year, offsetOfCurrentYear) = getYearByOffsetInDay(offsetInDay: offsetInDay)

        var result: [YearOffset]
        var appendCount = appendCount
        var currentYearDay = lunarYearDays(lunarYear: year)
        // 跨年
        if appendCount >= currentYearDay - offsetOfCurrentYear {
            // 先补上本年剩下的
            result = [YearOffset(year: year, offset: offsetOfCurrentYear, appendCount: currentYearDay - offsetOfCurrentYear - 1)]

            // 整年数据
            appendCount -= currentYearDay - offsetOfCurrentYear
            year += 1
            currentYearDay = lunarYearDays(lunarYear: year)
            while appendCount > currentYearDay {
                result.append(YearOffset(year: year, offset: 0, appendCount: currentYearDay - 1))
                appendCount -= currentYearDay
                year += 1
                currentYearDay = lunarYearDays(lunarYear: year)
            }

            // 处理剩下不满一年的数据
            if appendCount >= 0 {
                result.append(YearOffset(year: year, offset: 0, appendCount: appendCount))
            }
        }
        // 没有跨年
        else {
            result = [YearOffset(year: year, offset: offsetOfCurrentYear, appendCount: appendCount)]
        }

        return result
    }

    private func getMonthDayList(offsetOfCurrentYear: Int, year: Int, appendCount: Int) -> [MonthDay] {
        let (month, day, isLeap) = getMonthAndDayByOffsetInDay(offsetOfCurrentYear: offsetOfCurrentYear,
                                                               year: year)
        return getMonthDayList(year: year, month: month, day: day, isLeap: isLeap, appendCount: appendCount)
    }

    private func getMonthDayList(year: Int,
                                 month: Int,
                                 day: Int,
                                 isLeap: Bool,
                                 appendCount: Int) -> [MonthDay] {
        // 至少有一天
        var result: [MonthDay] = []
        result.append(MonthDay(year: year, month: month, day: day, isLeap: isLeap))
        if appendCount == 0 {
            return result
        }

        let currentMonthDay = isLeap ? leapMonthDays(lunarYear: year) : monthDays(lunarYear: year, lunarMonth: month)
        // 跨月
        if appendCount > currentMonthDay - day {
            // 先补上本月剩下的
            if day < currentMonthDay {
                for i in (day + 1)...currentMonthDay {
                    result.append(MonthDay(year: year, month: month, day: i, isLeap: isLeap))
                }
            }

            // 整月数据
            var appendCount = appendCount
            var isLeap = isLeap
            var month = month
            let leapMonth = leapMonthInYear(lunarYear: year)
            var monthDay: Int
            appendCount -= currentMonthDay - day
            // 闰月的前一个月，例如润六月 -> 六月
            if month == leapMonth && !isLeap {
                monthDay = leapMonthDays(lunarYear: year)
                isLeap = true
            }
            // 正常月份，闰月本身也按正常算
            else {
                isLeap = false
                month += 1
                monthDay = monthDays(lunarYear: year, lunarMonth: month)
            }
            while appendCount > monthDay {
                for i in 1...monthDay {
                    result.append(MonthDay(year: year, month: month, day: i, isLeap: isLeap))
                }
                appendCount -= monthDay
                // 同上
                if month == leapMonth && !isLeap {
                    monthDay = leapMonthDays(lunarYear: year)
                    isLeap = true
                } else {
                    isLeap = false
                    month += 1
                    monthDay = monthDays(lunarYear: year, lunarMonth: month)
                }
            }

            // 处理剩下不满一月的数据
            if appendCount > 0 {
                for i in 1...appendCount {
                    result.append(MonthDay(year: year, month: month, day: i, isLeap: isLeap))
                }
            }
        }
        // 非跨月
        else {
            for i in (day + 1)...(day + appendCount) {
                result.append(MonthDay(year: year, month: month, day: i, isLeap: isLeap))
            }
        }

        return result
    }

    // MARK: - 农历数据存储，以数组为载体的小型“数据库”

    /*
    以16进制的形式记录了1900-2100年的大小月及闰月分布情况，规则如下

    xxxx      xxxx        xxxx        xxxx        xxxx
    20-17     16-13       12-9        8-5         4-1
    1-4：判断当年是否为闰年，若为闰年，则为闰年的月份，反之为0；
    5-16：为除了闰月外的正常月份是大月还是小月，1为30天，0为29天。
    （注意：1月对应第16位，2月对应第15位……12月对应第5位)
    17-20： 表示闰月是大月还是小月，若为1，则为大月，若为0，则为小月。
    （注意：仅当存在闰月的情况下有意义）
    举例说明：
    例一：0x04bd8
    对应二进制：0000    0100     1011    1101    1000
    则表示当年有闰月8月，且闰月为小月29天
    该年1-12月的天数为：29  30  29  29  30  29  30  29(闰月)  30  30  29  30

    例二：0x04ae0
    对应二进制：0000    0100     1010    1110    0000
    则表示当年没有闰月
    该年1-12月的天数为：29  30  29  29  30  29  30  29  30  30  30  29
    */
    private let lunarYearInfo = [
        0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2, // 1900-1909
        0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977, // 1910-1919
        0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, // 1920-1929
        0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950, // 1930-1939
        0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, // 1940-1949
        0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0, // 1950-1959
        0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, // 1960-1969
        0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6, // 1970-1979
        0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570, // 1980-1989
        0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x05ac0, 0x0ab60, 0x096d5, 0x092e0, // 1990-1999
        0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, // 2000-2009
        0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930, // 2010-2019
        0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530, // 2020-2029
        0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, // 2030-2039
        0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0, // 2040-2049
        0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0, // 2050-2059
        0x0a2e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4, // 2060-2069
        0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0, // 2070-2079
        0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160, // 2080-2089
        0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252, // 2090-2099
        0x0d520] // 2100

    // 对应年的总天数
    private func lunarYearDays(lunarYear: Int) -> Int {
        guard let info = lunarYearInfo[safeIndex: lunarYear - 1900] else {
            assertionFailure()
            return 0
        }
        var sum = 348
        var i = 0x8000 // 对应二进制 1000 0000 0000 0000
        while i > 0x8 {
            sum += (info & i > 0) ? 1 : 0
            i >>= 1
        }
        return sum + leapMonthDays(lunarYear: lunarYear)
    }

    // 对应年闰月的天数，没有返回0
    private func leapMonthDays(lunarYear: Int) -> Int {
        if leapMonthInYear(lunarYear: lunarYear) > 0 {
            guard let info = lunarYearInfo[safeIndex: lunarYear - 1900] else {
                assertionFailure()
                return 0
            }
            return ((info & 0x10000 > 0) ? 30 : 29 )
        } else {
            return 0
        }
    }

    // 对应年闰哪个月，没有返回0
    private func leapMonthInYear(lunarYear: Int) -> Int {
        guard let info = lunarYearInfo[safeIndex: lunarYear - 1900] else {
            assertionFailure()
            return 0
        }
        return ( info & 0xf )
    }

    // 对应年对应月份的天数
    private func monthDays(lunarYear: Int, lunarMonth: Int) -> Int {
        guard let info = lunarYearInfo[safeIndex: lunarYear - 1900] else {
            assertionFailure()
            return 30
        }
        return ( (info & ( 0x10000 >> lunarMonth ) > 0) ? 30 : 29 )
    }

    // MARK: - 年月日别名&节日

    private func getAlias(year: Int, month: Int, day: Int, isLeap: Bool) -> (String, String, String) {
        let yearAlia = chineseZodiac[safeIndex: (year - 4) % 12] ?? ""
        var monthAlia = monthAlias[safeIndex: month - 1] ?? ""
        var dayAlia: String

        switch day {
        case 10:
            dayAlia = "初十"
        case 20:
            dayAlia = "二十"
        case 30:
            dayAlia = "三十"
        default:
            dayAlia = dayAliaTens[safeIndex: day / 10] ?? ""
            dayAlia += dayAliaOnes[safeIndex: day % 10] ?? ""
        }
        if isLeap {
            monthAlia = "闰" + monthAlia
        }
        return (yearAlia, monthAlia, dayAlia)
    }

    private let chineseZodiac = ["鼠", "牛", "虎", "兔", "龙", "蛇", "马", "羊", "猴", "鸡", "狗", "猪"]

    private let monthAlias = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]

    private let dayAliaTens = ["初", "十", "廿", "卅", "　"]

    private let dayAliaOnes = ["日", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    private func getFestival(year: Int, month: Int, day: Int) -> String {
        for festival in festivals {
            if festival.0 == month && festival.1 == day {
                return festival.2
            }
        }

        // 除夕，12月可能是29天或者30天
        if month == 12 {
            let lastDay = monthDays(lunarYear: year, lunarMonth: month)
            if day == lastDay {
                return "除夕"
            }
        }

        return ""
    }

    private let festivals = [
        (01, 01, "春节"),
        (01, 15, "元宵"),
        (02, 02, "龙头"),
        (05, 05, "端午"),
        (07, 07, "七夕"),
        (07, 15, "中元"),
        (08, 15, "中秋"),
        (09, 09, "重阳"),
        (12, 08, "腊八")
    ]

    // MARK: - 24节气相关

    func getTwentyFourSolarTerm(year: Int, month: Int, day: Int) -> String {
        // 0表示1月，11表示12月
        let month = month - 1

        let term1 = getSolarTermDayByIndexOfYear(year: year, index: month * 2)
        let term2 = getSolarTermDayByIndexOfYear(year: year, index: month * 2 + 1)
        if day == term1 {
            return twentyFourSolarTerms[safeIndex: month * 2] ?? ""
        }
        if day == term2 {
            return twentyFourSolarTerms[safeIndex: month * 2 + 1] ?? ""
        }
        return ""
    }

    private let twentyFourSolarTerms = ["小寒", "大寒", "立春", "雨水", "惊蛰", "春分", "清明", "谷雨", "立夏", "小满", "芒种", "夏至", "小暑", "大暑", "立秋", "处暑", "白露", "秋分", "寒露", "霜降", "立冬", "小雪", "大雪", "冬至"]

    // 对应年的第index个节气为几日(从0小寒起算)
    private func getSolarTermDayByIndexOfYear(year: Int, index: Int) -> Int {
        if let cacheValue = solarTermCache[IndexOfYear(year: year, index: index)] {
            return cacheValue
        }

        guard let infoOfYear = twentyFourSolarTermInfoList[safeIndex: year - 1900] else {
            assertionFailure()
            return 0
        }
        var infoOfYearList = [infoOfYear.subString(firstIndex: 0, length: 5)!,
                           infoOfYear.subString(firstIndex: 5, length: 5)!,
                           infoOfYear.subString(firstIndex: 10, length: 5)!,
                           infoOfYear.subString(firstIndex: 15, length: 5)!,
                           infoOfYear.subString(firstIndex: 20, length: 5)!,
                           infoOfYear.subString(firstIndex: 25, length: 5)!]
        infoOfYearList = infoOfYearList.map { String($0.hexStringToInt()!) }

        let row = index / 4
        let column = index % 4
        let infoOfFourTermStr = infoOfYearList[safeIndex: row] ?? ""
        let infoOfFourTermList = [infoOfFourTermStr.subString(firstIndex: 0, length: 1)!,
                                  infoOfFourTermStr.subString(firstIndex: 1, length: 2)!,
                                  infoOfFourTermStr.subString(firstIndex: 3, length: 1)!,
                                  infoOfFourTermStr.subString(firstIndex: 4, length: 2)!]

        let result = Int(infoOfFourTermList[safeIndex: column] ?? "")!
        solarTermCache[IndexOfYear(year: year, index: index)] = result
        return result
    }

    /*
    以16进制的形式记录了1900-2100年的24节气的日期，规则如下

    每个字符串代表一年的数据，每个字符串是由6个长度为5的16进制数组成的
    例如1901年：97b6b97bd19801ec9210c965cc920e，由97b6b，97bd1，9801e，c9210，c965c，c920e组成
    分别转为10进制后：621419，621521，622622，823824，824924，823822
    每个十进制数都代表着4个节气的日期，例如621419，表示本年的前4个节气分别为6日，21日，4日，19日
    这样，6个长度为5的16进制数就可以记录一年的24节气的日期
    补充一些历法知识：
    公历每个月固定有两个节气，第一个节气一定在10日之前，用1位数字表示，而第二个节气一定在10日之后（包含10日），用两位数字
    */
    private let twentyFourSolarTermInfoList = [
        "9778397bd097c36b0b6fc9274c91aa", "97b6b97bd19801ec9210c965cc920e", "97bcf97c3598082c95f8c965cc920f",
        "97bd0b06bdb0722c965ce1cfcc920f", "b027097bd097c36b0b6fc9274c91aa", "97b6b97bd19801ec9210c965cc920e",
        "97bcf97c359801ec95f8c965cc920f", "97bd0b06bdb0722c965ce1cfcc920f", "b027097bd097c36b0b6fc9274c91aa",
        "97b6b97bd19801ec9210c965cc920e", "97bcf97c359801ec95f8c965cc920f", "97bd0b06bdb0722c965ce1cfcc920f",
        "b027097bd097c36b0b6fc9274c91aa", "9778397bd19801ec9210c965cc920e", "97b6b97bd19801ec95f8c965cc920f",
        "97bd09801d98082c95f8e1cfcc920f", "97bd097bd097c36b0b6fc9210c8dc2", "9778397bd197c36c9210c9274c91aa",
        "97b6b97bd19801ec95f8c965cc920e", "97bd09801d98082c95f8e1cfcc920f", "97bd097bd097c36b0b6fc9210c8dc2",
        "9778397bd097c36c9210c9274c91aa", "97b6b97bd19801ec95f8c965cc920e", "97bcf97c3598082c95f8e1cfcc920f",
        "97bd097bd097c36b0b6fc9210c8dc2", "9778397bd097c36c9210c9274c91aa", "97b6b97bd19801ec9210c965cc920e",
        "97bcf97c3598082c95f8c965cc920f", "97bd097bd097c35b0b6fc920fb0722", "9778397bd097c36b0b6fc9274c91aa",
        "97b6b97bd19801ec9210c965cc920e", "97bcf97c3598082c95f8c965cc920f", "97bd097bd097c35b0b6fc920fb0722",
        "9778397bd097c36b0b6fc9274c91aa", "97b6b97bd19801ec9210c965cc920e", "97bcf97c359801ec95f8c965cc920f",
        "97bd097bd097c35b0b6fc920fb0722", "9778397bd097c36b0b6fc9274c91aa", "97b6b97bd19801ec9210c965cc920e",
        "97bcf97c359801ec95f8c965cc920f", "97bd097bd097c35b0b6fc920fb0722", "9778397bd097c36b0b6fc9274c91aa",
        "97b6b97bd19801ec9210c965cc920e", "97bcf97c359801ec95f8c965cc920f", "97bd097bd07f595b0b6fc920fb0722",
        "9778397bd097c36b0b6fc9210c8dc2", "9778397bd19801ec9210c9274c920e", "97b6b97bd19801ec95f8c965cc920f",
        "97bd07f5307f595b0b0bc920fb0722", "7f0e397bd097c36b0b6fc9210c8dc2", "9778397bd097c36c9210c9274c920e",
        "97b6b97bd19801ec95f8c965cc920f", "97bd07f5307f595b0b0bc920fb0722", "7f0e397bd097c36b0b6fc9210c8dc2",
        "9778397bd097c36c9210c9274c91aa", "97b6b97bd19801ec9210c965cc920e", "97bd07f1487f595b0b0bc920fb0722",
        "7f0e397bd097c36b0b6fc9210c8dc2", "9778397bd097c36b0b6fc9274c91aa", "97b6b97bd19801ec9210c965cc920e",
        "97bcf7f1487f595b0b0bb0b6fb0722", "7f0e397bd097c35b0b6fc920fb0722", "9778397bd097c36b0b6fc9274c91aa",
        "97b6b97bd19801ec9210c965cc920e", "97bcf7f1487f595b0b0bb0b6fb0722", "7f0e397bd097c35b0b6fc920fb0722",
        "9778397bd097c36b0b6fc9274c91aa", "97b6b97bd19801ec9210c965cc920e", "97bcf7f1487f531b0b0bb0b6fb0722",
        "7f0e397bd097c35b0b6fc920fb0722", "9778397bd097c36b0b6fc9274c91aa", "97b6b97bd19801ec9210c965cc920e",
        "97bcf7f1487f531b0b0bb0b6fb0722", "7f0e397bd07f595b0b6fc920fb0722", "9778397bd097c36b0b6fc9274c91aa",
        "97b6b97bd19801ec9210c9274c920e", "97bcf7f0e47f531b0b0bb0b6fb0722", "7f0e397bd07f595b0b0bc920fb0722",
        "9778397bd097c36b0b6fc9210c91aa", "97b6b97bd197c36c9210c9274c920e", "97bcf7f0e47f531b0b0bb0b6fb0722",
        "7f0e397bd07f595b0b0bc920fb0722", "9778397bd097c36b0b6fc9210c8dc2", "9778397bd097c36c9210c9274c920e",
        "97b6b7f0e47f531b0723b0b6fb0722", "7f0e37f5307f595b0b0bc920fb0722", "7f0e397bd097c36b0b6fc9210c8dc2",
        "9778397bd097c36b0b70c9274c91aa", "97b6b7f0e47f531b0723b0b6fb0721", "7f0e37f1487f595b0b0bb0b6fb0722",
        "7f0e397bd097c35b0b6fc9210c8dc2", "9778397bd097c36b0b6fc9274c91aa", "97b6b7f0e47f531b0723b0b6fb0721",
        "7f0e27f1487f595b0b0bb0b6fb0722", "7f0e397bd097c35b0b6fc920fb0722", "9778397bd097c36b0b6fc9274c91aa",
        "97b6b7f0e47f531b0723b0b6fb0721", "7f0e27f1487f531b0b0bb0b6fb0722", "7f0e397bd097c35b0b6fc920fb0722",
        "9778397bd097c36b0b6fc9274c91aa", "97b6b7f0e47f531b0723b0b6fb0721", "7f0e27f1487f531b0b0bb0b6fb0722",
        "7f0e397bd097c35b0b6fc920fb0722", "9778397bd097c36b0b6fc9274c91aa", "97b6b7f0e47f531b0723b0b6fb0721",
        "7f0e27f1487f531b0b0bb0b6fb0722", "7f0e397bd07f595b0b0bc920fb0722", "9778397bd097c36b0b6fc9274c91aa",
        "97b6b7f0e47f531b0723b0787b0721", "7f0e27f0e47f531b0b0bb0b6fb0722", "7f0e397bd07f595b0b0bc920fb0722",
        "9778397bd097c36b0b6fc9210c91aa", "97b6b7f0e47f149b0723b0787b0721", "7f0e27f0e47f531b0723b0b6fb0722",
        "7f0e397bd07f595b0b0bc920fb0722", "9778397bd097c36b0b6fc9210c8dc2", "977837f0e37f149b0723b0787b0721",
        "7f07e7f0e47f531b0723b0b6fb0722", "7f0e37f5307f595b0b0bc920fb0722", "7f0e397bd097c35b0b6fc9210c8dc2",
        "977837f0e37f14998082b0787b0721", "7f07e7f0e47f531b0723b0b6fb0721", "7f0e37f1487f595b0b0bb0b6fb0722",
        "7f0e397bd097c35b0b6fc9210c8dc2", "977837f0e37f14998082b0787b06bd", "7f07e7f0e47f531b0723b0b6fb0721",
        "7f0e27f1487f531b0b0bb0b6fb0722", "7f0e397bd097c35b0b6fc920fb0722", "977837f0e37f14998082b0787b06bd",
        "7f07e7f0e47f531b0723b0b6fb0721", "7f0e27f1487f531b0b0bb0b6fb0722", "7f0e397bd097c35b0b6fc920fb0722",
        "977837f0e37f14998082b0787b06bd", "7f07e7f0e47f531b0723b0b6fb0721", "7f0e27f1487f531b0b0bb0b6fb0722",
        "7f0e397bd07f595b0b0bc920fb0722", "977837f0e37f14998082b0787b06bd", "7f07e7f0e47f531b0723b0b6fb0721",
        "7f0e27f1487f531b0b0bb0b6fb0722", "7f0e397bd07f595b0b0bc920fb0722", "977837f0e37f14998082b0787b06bd",
        "7f07e7f0e47f149b0723b0787b0721", "7f0e27f0e47f531b0b0bb0b6fb0722", "7f0e397bd07f595b0b0bc920fb0722",
        "977837f0e37f14998082b0723b06bd", "7f07e7f0e37f149b0723b0787b0721", "7f0e27f0e47f531b0723b0b6fb0722",
        "7f0e397bd07f595b0b0bc920fb0722", "977837f0e37f14898082b0723b02d5", "7ec967f0e37f14998082b0787b0721",
        "7f07e7f0e47f531b0723b0b6fb0722", "7f0e37f1487f595b0b0bb0b6fb0722", "7f0e37f0e37f14898082b0723b02d5",
        "7ec967f0e37f14998082b0787b0721", "7f07e7f0e47f531b0723b0b6fb0722", "7f0e37f1487f531b0b0bb0b6fb0722",
        "7f0e37f0e37f14898082b0723b02d5", "7ec967f0e37f14998082b0787b06bd", "7f07e7f0e47f531b0723b0b6fb0721",
        "7f0e37f1487f531b0b0bb0b6fb0722", "7f0e37f0e37f14898082b072297c35", "7ec967f0e37f14998082b0787b06bd",
        "7f07e7f0e47f531b0723b0b6fb0721", "7f0e27f1487f531b0b0bb0b6fb0722", "7f0e37f0e37f14898082b072297c35",
        "7ec967f0e37f14998082b0787b06bd", "7f07e7f0e47f531b0723b0b6fb0721", "7f0e27f1487f531b0b0bb0b6fb0722",
        "7f0e37f0e366aa89801eb072297c35", "7ec967f0e37f14998082b0787b06bd", "7f07e7f0e47f149b0723b0787b0721",
        "7f0e27f1487f531b0b0bb0b6fb0722", "7f0e37f0e366aa89801eb072297c35", "7ec967f0e37f14998082b0723b06bd",
        "7f07e7f0e47f149b0723b0787b0721", "7f0e27f0e47f531b0723b0b6fb0722", "7f0e37f0e366aa89801eb072297c35",
        "7ec967f0e37f14998082b0723b06bd", "7f07e7f0e37f14998083b0787b0721", "7f0e27f0e47f531b0723b0b6fb0722",
        "7f0e37f0e366aa89801eb072297c35", "7ec967f0e37f14898082b0723b02d5", "7f07e7f0e37f14998082b0787b0721",
        "7f07e7f0e47f531b0723b0b6fb0722", "7f0e36665b66aa89801e9808297c35", "665f67f0e37f14898082b0723b02d5",
        "7ec967f0e37f14998082b0787b0721", "7f07e7f0e47f531b0723b0b6fb0722", "7f0e36665b66a449801e9808297c35",
        "665f67f0e37f14898082b0723b02d5", "7ec967f0e37f14998082b0787b06bd", "7f07e7f0e47f531b0723b0b6fb0721",
        "7f0e36665b66a449801e9808297c35", "665f67f0e37f14898082b072297c35", "7ec967f0e37f14998082b0787b06bd",
        "7f07e7f0e47f531b0723b0b6fb0721", "7f0e26665b66a449801e9808297c35", "665f67f0e37f1489801eb072297c35",
        "7ec967f0e37f14998082b0787b06bd", "7f07e7f0e47f531b0723b0b6fb0721", "7f0e27f1487f531b0b0bb0b6fb0722"]
}

// MARK: - 内部struct

private struct IndexOfYear: Hashable {
    let year: Int
    let index: Int
}

struct MonthDay {
    let year: Int
    let month: Int
    let day: Int
    let isLeap: Bool
}

private struct YearOffset {
    let year: Int
    let offset: Int
    let appendCount: Int
}

extension String {
    /// 16进制字符串转Int
    func hexStringToInt() -> Int? {
        let str = self.uppercased()
        var sum = 0
        for i in str.utf8 {
            guard (i >= 48 && i <= 57) || (i >= 65 && i <= 90) else {
                return nil
            }

            let i = i >= 65 ? i - 7 : i // 9是57，A是65，需去掉差值7来达到16进制的效果
            sum = sum * 16 + Int(i) - 48 // 0是48，这里每次*16相当于整体向左移1位
        }
        return sum
    }

    /// JavaScript风格的返回子字符串方法
    func subString(firstIndex: Int, length: Int) -> String? {
        guard firstIndex >= 0, length >= 0, firstIndex + length <= self.count else {
            return nil
        }
        let firstIndex = self.index(startIndex, offsetBy: firstIndex)
        let lastIndex = self.index(firstIndex, offsetBy: length - 1)
        return String(self[firstIndex...lastIndex])
    }
}

extension Date {
    /// 获得date的year、month、day
    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.gregorianCalendar) -> Int {
        return calendar.component(component, from: self)
    }
}
