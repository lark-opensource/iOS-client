//
//  MonthDaysLoader.swift
//  Calendar
//
//  Created by zhuheng on 2020/7/14.
//

import Foundation
import RxSwift
import CalendarFoundation
import CTFoundation
import LarkContainer

protocol MonthLoader {
    var loaderUpdateSucess: PublishSubject<Void> { get }

    func prepareData(date: Date)

    func getInstance(start: Date, end: Date) -> [MonthItem]

    func getTimeBlock(start: Date, end: Date) -> [MonthItem]

    func active()

    func inactive()

    func eliminationCacheData(with date: Date)
}
extension MonthDaysLoader: InstanceCacheDelegateOld {
    func cacheElimnated() {
        if self.activeStatus.value == .active && self.dataStatus.value == .dirty {
            self.reloadCacheInstance()
        }
    }

    func getFirstScreenDayRange() -> JulianDayRange {
        let daysMaker = MonthPageMaker(firstWeekday: self.firstWeekday)
        let pageData = daysMaker.getPageData(date: Date())
        let startJulianDay = JulianDayUtil.julianDay(from: pageData.start, in: .current)
        let endJulianDay = JulianDayUtil.julianDay(from: pageData.end, in: .current)
        return startJulianDay ..< (endJulianDay + 1)
    }

    func getDiskCacheDayRange() -> JulianDayRange {
        return self.getFirstScreenDayRange()
    }

    func cacheChanged(instance: [CalendarEventInstanceEntity], timeZoneId: String) {
        let pbInstances = instance.map { $0.toPB() }
        self.instanceSnapshot.writeToDiskIfNeeded(instances: pbInstances, timeZoneId: timeZoneId, dayRange: getDiskCacheDayRange())
    }

}

final class MonthDaysLoader: BaseInstanceLoader, MonthLoader {
    // 更新结束通知
    lazy var loaderUpdateSucess: PublishSubject<Void> = {
        return self.blockOnReady
    }()

    private let eventViewSettingGetter: () -> EventViewSetting
    private let userReload = PublishSubject<Void>()
    var firstWeekday: Int {
        return self.eventViewSettingGetter().firstWeekday.rawValue
    }
    // 更新结束通知
    init(calendarApi: CalendarRustAPI,
         cache: InstanceCacheOld,
         instanceSnapshot: InstanceSnapshot,
         userResolver: UserResolver,
         visibleCalendarsIDs: @escaping () -> [String],
        eventViewSettingGetter: @escaping () -> EventViewSetting) {
        defer { self.cache.delegate = self }
        self.eventViewSettingGetter = eventViewSettingGetter
        super.init(cache: cache,
                   instanceSnapshot: instanceSnapshot,
                   calendarApi: calendarApi,
                   userResolver: userResolver,
                   timeZoneIdGetter: { TimeZone.current.identifier },
                   visibleCalendarsIDs: visibleCalendarsIDs)
    }

    func prepareData(date: Date) {
        let daysMaker = MonthPageMaker(firstWeekday: self.firstWeekday)
        let pageData = daysMaker.getPageData(date: date)
        let fakeDays = self.getExpectCacheDays(date: date)
        let requestDays = InstanceDateUtil.getJulianDays(start: pageData.start, end: pageData.end)
        let loadingDays = InstanceDateUtil.getJulianDays(start: fakeDays.start, end: fakeDays.end)
        let firstScreenRange = JulianDayUtil.makeJulianDayRange(min: requestDays.min(), max: requestDays.max())
        self.timeDataService?.prepareDiskData(firstScreenDayRange: firstScreenRange)
        self.load(requestDays: requestDays, nextRequestDays: loadingDays, timeZoneId: TimeZone.current.identifier)
    }

    func eliminationCacheData(with date: Date) {
        let days = self.getExpectCacheDays(date: date)
        let useDays = InstanceDateUtil.getJulianDays(start: days.start, end: days.end, timeZoneId: nil)
        let useDayRange = JulianDayUtil.makeJulianDayRange(min: useDays.min(), max: useDays.max())
        self.cache.updateCacheWindow(with: useDayRange)
    }

    func getInstance(start: Date, end: Date) -> [MonthItem] {
        let useDays = InstanceDateUtil.getJulianDays(start: start, end: end)
        let instances = self.getInstance(with: useDays, timeZoneID: TimeZone.current.identifier)
        guard !instances.isEmpty else { return [MonthEvent]() }
        TimerMonitorHelper.shared.launchTimeTracer?.handleInstance.start()
        defer {
            TimerMonitorHelper.shared.launchTimeTracer?.handleInstance.end()
        }
        return instances.map({ (instance) -> MonthEvent in
            return MonthEvent(instance: instance,
                              calendar: calendar(with: instance.calendarId),
                              eventViewSetting: self.eventViewSettingGetter())})
    }
    
    func getTimeBlock(start: Date, end: Date) -> [MonthItem] {
        let useDays = InstanceDateUtil.getJulianDays(start: start, end: end)
        let timeBlocks = self.getTimeBlock(with: useDays, timeZoneID: TimeZone.current.identifier)
        guard !timeBlocks.isEmpty else { return [] }
        return timeBlocks.map({ (timeBlock) -> MonthTimeBlock in
            return MonthTimeBlock(timeBlock: timeBlock,
                                  eventViewSetting: self.eventViewSettingGetter())})
    }

    func getExpectCacheDays(date: Date) -> (start: Date, end: Date) {
        let dasyMaker = MonthPageMaker(firstWeekday: firstWeekday)
        let lastMonthDays = dasyMaker.getPageData(date: (date - 1.month)!)
        let nextMonthDays = dasyMaker.getPageData(date: (date + 1.month)!)
        return (start: lastMonthDays.start, end: nextMonthDays.end)
    }
    private func calendar(with id: String) -> CalendarModel? {
        return self.calendarManager?.calendar(with: id)
    }

}

struct MonthPageData {
    let monthStart: Date
    let monthEnd: Date
    let offset: Int
    let start: Date
    let end: Date
    let rowNumber: Int
}

final class MonthPageMaker {
    private let firstWeekday: Int
    private let daysPreWeek = 7
    init(firstWeekday: Int) {
        self.firstWeekday = firstWeekday
    }

    func getPageData(date: Date) -> MonthPageData {
        let daysPerWeek = 7
        let monthStart = date.startOfMonth()
        let monthEnd = date.endOfMonth()
        let offset = (monthStart.weekday - self.firstWeekday + daysPerWeek) % daysPerWeek
        let start = (monthStart - offset.days)!
        let rowNumber = getRowNumber(startWeekDay: offset, monthEnd: monthEnd)
        let pageEndDate = (start + (rowNumber * daysPerWeek - 1).days)!

        return MonthPageData(monthStart: monthStart,
                             monthEnd: monthEnd,
                             offset: offset,
                             start: start,
                             end: pageEndDate.dayEnd(),
                             rowNumber: rowNumber)
    }

    private func getRowNumber(startWeekDay: Int, monthEnd: Date) -> Int {
        let daysPerWeek = 7
        let totalDays = startWeekDay - 1 + monthEnd.day
        return totalDays / daysPerWeek + 1
    }
}
