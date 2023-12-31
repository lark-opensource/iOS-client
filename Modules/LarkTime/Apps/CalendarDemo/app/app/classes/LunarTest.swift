//
//  LunarTest.swift
//  TestProject
//
//  Created by 白言韬 on 2020/2/14.
//  Copyright © 2020 yitl. All rights reserved.
//

import Foundation
@testable import Calendar

struct LunarDate: Decodable {
    var festival: String
    var lunarFestival: String
    var lunarYear: Int
    var lunarMonth: Int
    var lunarDate: Int
    var zodiac: String
    var displayLunarMonth: String
    var displayLunarDate: String
    var ganzhiYear: String
    var ganzhiMonth: String
    var ganzhiDate: String
    var isLeap: Bool
    var term: String
}

class LunarTest {

//    func testOneDay() {
//        let startTime = getTimeStamp()
//        let count = 10000
//        for _ in 1...count {
//            _ = AlternateCalendarFactory.getAlternateCalendarDateByType(date: Date(), alternateCalendarType: .chineseCalendar)
//        }
//        let endTime = getTimeStamp()
//        print("共测试\(count)次, 单次耗时: \((endTime - startTime)/count)微秒")
//    }

    // 测试入口
    // gap一般是86_400，即一天的意思
    // 测试json文件中1900和2100的case不全，这里不纳入测试范围
    // 同时测试了新的缓存方案和最初的方案
    func mainTest(beginYear: Int = 1901, endYear: Int = 2098, gap: Double = 86400) {
        guard beginYear >= 1901, endYear <= 2099 else {
            print("invalid parameter")
            return
        }

        // 记录测试数据相关
        let startTime = getCurrentTimeStamp()
        var totalCount = 0
        var successCount = 0
        var failureCount = 0
        
        // 提取json文件中的数据为map
        let lunarDateMap = getLunarDataMap()

        for testYear in beginYear...endYear {
            let testDates = getTestDatesOfTestYear(testYear: testYear, gap: gap)
            for date in testDates {
                totalCount += 1
                
                let key = "\(date.get(.year))-\(date.get(.month))-\(date.get(.day))"
                let lunarDate = lunarDateMap?[key]

                let offsetInDay = AlternateCalendarUtil.chineseCalendar.getOffsetInDay(date: date)
                let newMonthDay = AlternateCalendarUtil.chineseCalendar.getLunarYearMonthDay(dayOffset: offsetInDay!)
                let oldMonthDay = AlternateCalendarUtil.chineseCalendar.getMonthDay(offsetInDay: offsetInDay!)

                if !compare(lunar: lunarDate!, monthDay: newMonthDay!) {
                    failureCount += 1
                    print("date: \(date)")
                    print("ios: \(newMonthDay!)")
                    print("pc: \(lunarDate!)")
                    continue
//                    return
                }
                if !compare(lunar: lunarDate!, monthDay: oldMonthDay) {
                    failureCount += 1
                    print("date: \(date)")
                    print("ios: \(oldMonthDay)")
                    print("pc: \(lunarDate!)")
                    continue
//                    return
                }
                successCount += 1
            }
            print("Test year: \(testYear)")
        }

        let endTime = getCurrentTimeStamp()
        print("Test finished, cost time: \(endTime - startTime)")
        print("totalCount: \(totalCount) successCount: \(successCount) failureCount: \(failureCount)")
    }

    // 同时测试了新的缓存方案的初始化的场景
    func mainTest2(beginYear: Int = 1901, endYear: Int = 2098, gap: Double = 86400) {
        guard beginYear >= 1901, endYear <= 2099 else {
            print("invalid parameter")
            return
        }

        // 记录测试数据相关
        let startTime = getCurrentTimeStamp()
        var totalCount = 0
        var successCount = 0
        var failureCount = 0
        
        // 提取json文件中的数据为map
        let lunarDateMap = getLunarDataMap()

        for testYear in beginYear...endYear {
            let testDates = getTestDatesOfTestYear(testYear: testYear, gap: gap)
            for date in testDates {
                totalCount += 1
                
                let key = "\(date.get(.year))-\(date.get(.month))-\(date.get(.day))"
                let lunarDate = lunarDateMap?[key]

                let offsetInDay = AlternateCalendarUtil.chineseCalendar.getOffsetInDay(date: date)
                AlternateCalendarUtil.chineseCalendar.resetYearCacheList()
                let newMonthDay = AlternateCalendarUtil.chineseCalendar.getLunarYearMonthDay(dayOffset: offsetInDay!)

                if !compare(lunar: lunarDate!, monthDay: newMonthDay!) {
                    failureCount += 1
                    print("date: \(date)")
                    print("ios: \(newMonthDay!)")
                    print("pc: \(lunarDate!)")
                    continue
//                    return
                }
                successCount += 1
            }
            print("Test year: \(testYear)")
        }

        let endTime = getCurrentTimeStamp()
        print("Test finished, cost time: \(endTime - startTime)")
        print("totalCount: \(totalCount) successCount: \(successCount) failureCount: \(failureCount)")
    }
    
    func getCurrentTimeStamp() -> Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }

    func getTimeStamp() -> Int {
        return Int(Date().timeIntervalSince1970 * 1000_000)
    }
    
    func getLunarDataMap() -> [String:LunarDate]? {
        let jsonPath = Bundle.main.path(forResource: "testData", ofType: "json")
        if let jsonPath = jsonPath {
            let data = NSData.init(contentsOfFile: jsonPath)
            if let data = data {
                do {
                    let lunarDateMap = try JSONDecoder().decode([String:LunarDate].self, from: data as Data)
                    return lunarDateMap
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        return nil
    }

    func getTestDatesOfTestYear(testYear: Int, gap: Double) -> [Date] {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        let startTime = formatter.date(from: "\(testYear)-01-01")!.timeIntervalSince1970
        let endTime = formatter.date(from: "\(testYear)-12-31")!.timeIntervalSince1970
        var result = [Date]()
        
        var time = startTime
        while time <= endTime {
            let date = Date(timeIntervalSince1970: time)
            result.append(date)
            time += gap
        }
        return result
    }

    func compare(lunar: LunarDate, monthDay: MonthDay) -> Bool {
        if lunar.lunarYear != monthDay.year {
            print("error here: lunarYear")
            assertionFailure()
            return false
        }
        if lunar.lunarMonth != monthDay.month {
            print("error here: lunarMonth")
            assertionFailure()
            return false
        }
        if lunar.lunarDate != monthDay.day {
            print("error here: lunarDate")
            assertionFailure()
            return false
        }
        if lunar.isLeap != monthDay.isLeap {
            print("error here: isLeap")
            assertionFailure()
            return false
        }
        return true
    }
    
}
