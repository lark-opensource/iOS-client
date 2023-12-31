//
//  DayNonAllDayViewModel+ViewDataManager.swift
//  Calendar
//
//  Created by 张威 on 2020/9/20.
//

import UIKit
import Foundation
import EventKit

/// DayScene - NonAllDay - ViewModel: ViewDataManager

extension DayNonAllDayViewModel {
    final class ViewDataManager {
        typealias CalendarGetter = (_ calanedarId: String) -> CalendarModel?
        typealias VersionedPageViewData = (version: Int, pageViewData: PageViewData)

        private(set) var timeZone: TimeZone
        private(set) var currentDay: JulianDay
        private(set) var viewSetting: EventViewSetting
        private let calendarGetter: CalendarGetter
        private let pageDrawRectFunc: DayNonAllDayViewModel.PageDrawRectFunc
        private var storage = [JulianDay: VersionedPageViewData]()

        init(
            timeZone: TimeZone,
            currentDay: JulianDay,
            viewSetting: EventViewSetting,
            calendarGetter: @escaping CalendarGetter,
            pageDrawRectFunc: @escaping PageDrawRectFunc
        ) {
            self.timeZone = timeZone
            self.currentDay = currentDay
            self.viewSetting = viewSetting
            self.calendarGetter = calendarGetter
            self.pageDrawRectFunc = pageDrawRectFunc
        }

        func updateCurrentDay(_ newCurrentDay: JulianDay) {
            assert(Thread.isMainThread)
            currentDay = newCurrentDay
            for day in storage.keys {
                storage[day]?.pageViewData.backgroundColor = bgColorForPage(forDay: day)
            }
        }

        // 更新目标 day 的 instance 的 maskOpacity
        func updateMaskOpacity(in day: JulianDay) {
            assert(Thread.isMainThread)
            let itemsCount = storage[day]?.pageViewData.instanceItems.count ?? 0
            guard itemsCount > 0 else { return }
            for i in 0..<itemsCount {
                storage[day]?.pageViewData.instanceItems[i].updateMaskOpacity(with: viewSetting)
            }
        }

        // 更新所有 instance 的 maskOpacity
        func updateMaskOpacityForAll() {
            assert(Thread.isMainThread)
            storage.keys.forEach(updateMaskOpacity(in:))
        }

        func updateViewSetting(_ newViewSetting: EventViewSetting) {
            assert(Thread.isMainThread)
            viewSetting = newViewSetting
            for day in storage.keys {
                storage[day]?.pageViewData.setNeedsUpdateViewSetting(newViewSetting)
            }
        }

        func updateTimeZone(_ newTimeZone: TimeZone) {
            assert(Thread.isMainThread)
            timeZone = newTimeZone
            storage.removeAll()
        }

        func hasViewData(for day: JulianDay, in timeZone: TimeZone, version: Int) -> Bool {
            assert(Thread.isMainThread)
            guard self.timeZone.identifier == timeZone.identifier else { return false }
            return storage[day]?.version == version
        }

        func pageViewData(for day: JulianDay, in timeZone: TimeZone) -> VersionedPageViewData? {
            assert(Thread.isMainThread)
            if self.timeZone.identifier != timeZone.identifier {
                return nil
            }
            storage[day]?.pageViewData.updateViewSettingIfNeeded()
            return storage[day]
        }

        func makePageViewData(
            from instances: [DayNonAllDayLayoutedInstance],
            forDay julianDay: JulianDay,
            is12HourStyle: Bool
        ) -> PageViewData {
            let bgColor = bgColorForPage(forDay: julianDay)
            guard !instances.isEmpty else {
                return PageViewData(julianDay: julianDay, backgroundColor: bgColor, instanceItems: [])
            }
            var existViewDataMap = [String: DayNonAllDayItemDataType]()
            let setupMapInMainThread = {
                self.storage[julianDay]?.pageViewData.instanceItems.forEach { instanceViewData in
                    existViewDataMap[instanceViewData.viewData.uniqueId] = instanceViewData
                }
            }
            if Thread.isMainThread {
                setupMapInMainThread()
            } else {
                // 使用 semaphore 保护，确保 storage 在主线程被访问，保证数据访问安全。
                // Q: 为什么不直接对 storage 的所有操作加锁？
                // A: 效率起见，storage 的访问频率非常高，主要是在主线程访问，唯有 `makePageViewData` 可能在非主线访问，
                //    因此在此处加保护即可，同时保证 storage 的访问效率和数据安全。
                let semaphore = DispatchSemaphore(value: 0)
                DispatchQueue.main.async {
                    setupMapInMainThread()
                    semaphore.signal()
                }
                semaphore.wait()
            }
            let instanceItems = instances.compactMap { item -> DayNonAllDayItemDataType? in
                return item.instance.process { type in
                    switch type {
                    case .event(let instance):
                        return processInstaceViewData(instance: instance)
                    case .timeBlock(let timeBlock):
                        return TimeBlockViewData(timeBlockData: timeBlock,
                                                 viewSetting: viewSetting,
                                                 layout: item.layout,
                                                 pageDrawRect: pageDrawRectFunc(),
                                                 is12HourStyle: is12HourStyle)
                    case .instanceEntity, .none:
                        return nil
                    }
                }
                func processInstaceViewData(instance: Instance) -> DayNonAllDayItemDataType {
                    var calendar: CalendarModel?
                    switch instance {
                    case .local(let localInstance):
                        calendar = calendarGetter(localInstance.calendar.calendarIdentifier)
                    case .rust(let rustInstance):
                        calendar = calendarGetter(rustInstance.calendarID)
                    }
                    let semiViewData = SemiInstanceViewData(
                        instance: instance,
                        calendar: calendar,
                        layout: item.layout,
                        pageDrawRect: pageDrawRectFunc(),
                        viewSetting: viewSetting
                    )
                    if var existViewData = existViewDataMap[semiViewData.uniqueId] as? InstanceViewData,
                        existViewData.hashValues.coreContent == semiViewData.hashValues.coreContent,
                        existViewData.hashValues.decoration == semiViewData.hashValues.decoration {
                        existViewData.semiViewData = semiViewData
                        return existViewData
                    }
                    return InstanceViewData(semiViewData: semiViewData)
                }
            }
            return PageViewData(
                julianDay: julianDay,
                backgroundColor: bgColor,
                instanceItems: instanceItems
            )
        }

        /// 缓存 pageViewData
        @discardableResult
        func updatePageViewData(
            _ pageViewData: PageViewData,
            for day: JulianDay,
            in timeZone: TimeZone,
            version: Int,
            loggerModel: CaVCLoggerModel,
            file: String = #fileID,
            function: String = #function,
            line: Int = #line
        ) -> Bool {
            assert(Thread.isMainThread)
            guard timeZone.identifier == self.timeZone.identifier else { return false }
            if let num = storage[day]?.version, num > version {
                return false
            }
            DayScene.logger.info("targetViewDataVersion => updatePageViewData - save version with \(version)",
                                 file: file,
                                 function: function,
                                 line: line)
            loggerModel.logEnd("targetViewDataVersion => updatePageViewData - save version with \(version) file = \(file), function = \(function), line = \(line)")
            storage[day] = (version, pageViewData)
            return true
        }

        func dropAllPageViewData() {
            assert(Thread.isMainThread)
            storage.removeAll()
        }

        // 淘汰 viewData 缓存
        func dropPageViewData(
            withVisiblePageRange visiblePageRange: PageRange,
            firstWeekday: EKWeekday
        ) {
            assert(Thread.isMainThread)
            // 淘汰策略：
            //  - currentDay 对应的 week 的 viewData 不淘汰
            //  - visibleDayRange 包含的 week、以及相临两周 week 的 viewData 不淘汰
            var protectedDays = Set<JulianDay>()

            DayScene.julianDayRange(inSameWeekAs: currentDay, with: firstWeekday).forEach {
                protectedDays.insert($0)
            }

            var startDay = DayScene.julianDay(from: visiblePageRange.lowerBound) - DayScene.daysPerWeek * 2
            var endDay = DayScene.julianDay(from: visiblePageRange.upperBound - 1) + DayScene.daysPerWeek * 2
            startDay = DayScene.julianDayRange(inSameWeekAs: startDay, with: firstWeekday).lowerBound
            endDay = DayScene.julianDayRange(inSameWeekAs: endDay, with: firstWeekday).upperBound - 1
            (startDay...endDay).forEach { protectedDays.insert($0) }

            for day in storage.keys where !protectedDays.contains(day) {
                storage.removeValue(forKey: day)
            }
        }

        private func bgColorForPage(forDay day: JulianDay) -> UIColor {
            return currentDay == day ? PageViewData.backgroundColors.today : PageViewData.backgroundColors.normal
        }

    }
}
