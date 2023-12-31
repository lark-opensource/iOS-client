//
//  DayAllDayViewModel+ViewDataManager.swift
//  Calendar
//
//  Created by 张威 on 2020/9/23.
//

import Foundation
import CTFoundation

/// DayScene - AllDay - ViewModel: ViewDataManager

extension DayAllDayViewModel {

    final class ViewDataManager {
        typealias CalendarGetter = (_ calanedarId: String) -> CalendarModel?
        typealias VersionedSectionViewData = (version: Int, sectionViewData: SectionViewData)

        private(set) var timeZone: TimeZone
        private(set) var currentDay: JulianDay
        private(set) var viewSetting: EventViewSetting
        private let calendarGetter: CalendarGetter
        private let itemDrawRectFunc: DayAllDayViewModel.ItemDrawRectFunc
        private var storage = [Int: VersionedSectionViewData]()

        init(
            timeZone: TimeZone,
            currentDay: JulianDay,
            viewSetting: EventViewSetting,
            calendarGetter: @escaping CalendarGetter,
            itemDrawRectFunc: @escaping ItemDrawRectFunc
        ) {
            self.timeZone = timeZone
            self.currentDay = currentDay
            self.viewSetting = viewSetting
            self.calendarGetter = calendarGetter
            self.itemDrawRectFunc = itemDrawRectFunc
        }

        func updateCurrentDay(_ newCurrentDay: JulianDay) {
            assert(Thread.isMainThread)
            guard currentDay != newCurrentDay else { return }
            currentDay = newCurrentDay
            guard viewSetting.showCoverPassEvent else { return }
            let startOfCurrentDay = JulianDayUtil.startOfDay(for: newCurrentDay, in: timeZone)
            for key in storage.keys {
                storage[key]?.sectionViewData.setNeedsUpdateMaskOpacity(startOfCurrentDay)
            }
        }

        func updateViewSetting(_ newViewSetting: EventViewSetting) {
            assert(Thread.isMainThread)
            viewSetting = newViewSetting
            let startOfCurrentDay = JulianDayUtil.startOfDay(for: currentDay, in: timeZone)
            for day in storage.keys {
                storage[day]?.sectionViewData.setNeedsUpdateViewSetting(newViewSetting)
                storage[day]?.sectionViewData.setNeedsUpdateMaskOpacity(startOfCurrentDay)
            }
        }

        func updateTimeZone(_ newTimeZone: TimeZone) {
            assert(Thread.isMainThread)
            timeZone = newTimeZone
            storage.removeAll()
        }

        func sectionViewData(in section: Int, timeZone: TimeZone) -> VersionedSectionViewData? {
            assert(Thread.isMainThread)
            guard timeZone.identifier == self.timeZone.identifier else { return nil }
            storage[section]?.sectionViewData.updateViewSettingIfNeeded()
            return storage[section]
        }

        /// 缓存 pageViewData
        @discardableResult
        func updateSectionViewData(
            _ sectionViewData: SectionViewData,
            in section: Section,
            version: Int
        ) -> Bool {
            assert(Thread.isMainThread)
            guard timeZone.identifier == self.timeZone.identifier else { return false }
            if let num = storage[section]?.version, num > version {
                return false
            }
            storage[section] = (version, sectionViewData)
            return true
        }

        // dayRange 并不是 instance 真正的 range，可能被截断
        private typealias InstanceInDayRange = (instance: BlockDataProtocol, dayRange: JulianDayRange)
        private typealias InstanceWithLayout = (instance: BlockDataProtocol, layout: DayAllDayPageItemLayout)

        /// 根据 [Instance] 获取 [InstanceViewData]
        ///
        /// - Parameters:
        ///   - instances: 来自 SDK 的 instances
        ///   - limitDayRange: 用于限制 instances，譬如 instance 的 dayRange 为 `1..<10`,
        ///     `limitDayRange` 为 `2..<13`，则对应 viewData 的 dayRange 为 `2..<10`
        ///   - getters: 辅助生成 ViewData
        /// - Returns: instances 对应的 viewData，注意内部有过滤逻辑，返回的数组数量和输入不一样
        func makeSectionViewData(
            from instances: [BlockDataProtocol],
            clampedTo limitDayRange: JulianDayRange,
            in section: Int
        ) -> SectionViewData {
            /// phase 1: [Instance] -> [InstanceInDayRange] -> [InstanceInDayRange] (sorted)

            let instanceInDayRangeArr = instances.compactMap { model -> InstanceInDayRange? in
                guard model.shouldTreatedAsAllDay() else { return nil }
                let (startDay, endDay): (JulianDay, JulianDay)
                if let instance = model as? Instance {
                    switch instance {
                    case .local(let localInstance):
                        startDay = JulianDayUtil.julianDay(from: localInstance.startDate, in: timeZone)
                        endDay = JulianDayUtil.julianDay(from: localInstance.endDate, in: timeZone)
                    case .rust(let rustInstance):
                        startDay = JulianDay(rustInstance.startDay)
                        endDay = JulianDay(rustInstance.endDay)
                    }
                } else if let timeBlock = model as? TimeBlockModel {
                    startDay = JulianDay(timeBlock.startDay)
                    endDay = JulianDay(timeBlock.endDay)
                } else {
                    return nil
                }
                guard endDay >= startDay else {
                    assertionFailure("endDay should greater than or equal to startDay.")
                    return nil
                }
                let fromDay = max(limitDayRange.lowerBound, startDay)
                let toDay = min(limitDayRange.upperBound, endDay + 1)
                guard fromDay < toDay else { return nil }
                return (instance: model, dayRange: fromDay..<toDay)
            }.sorted(by: { tuple1, tuple2 in
                TimeBlockUtils.sortBlock(lhs: tuple1.instance.transfromToSortModel(), rhs: tuple2.instance.transfromToSortModel())
            })
            /// phase 2: [InstanceInDayRange] -> [InstanceWithLayout]

            // 记录每一行的可用 ranges
            var availablesRanges = Array(repeating: limitDayRange, count: instanceInDayRangeArr.count)
            var instanceWithLayoutArr = [InstanceWithLayout]()
            for tuple in instanceInDayRangeArr {
                let (instance, dayRange) = tuple
                var row = availablesRanges.count - 1
                for i in 0..<availablesRanges.count {
                    let availablesRange = availablesRanges[i]
                    if availablesRange.lowerBound <= dayRange.lowerBound
                        && availablesRange.upperBound >= dayRange.upperBound {
                        availablesRanges[i] = dayRange.upperBound..<availablesRange.upperBound
                        row = i
                        break
                    }
                }
                let pageRange = DayScene.pageRange(from: dayRange)
                instanceWithLayoutArr.append((
                    instance: instance,
                    layout: DayAllDayPageItemLayout(pageRange: pageRange, row: row)
                ))
            }

            var existViewDataMap = [String: DayAllDayInstanceViewDataType]()
            let setupMapInMainThread = {
                self.storage[section]?.sectionViewData.expandedItems.forEach { item in
                    if case .instanceViewData(let viewData) = item {
                        if let instanceViewData = viewData as? InstanceViewData {
                            existViewDataMap[instanceViewData.uniqueId] = instanceViewData
                        } else if let data = viewData as? TimeBlockViewData {
                            existViewDataMap[data.uniqueId] = data
                        }
                    }
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

            // phase 3: [InstanceWithLayout] -> [InstanceViewData]
            let instanceViewDataList = instanceWithLayoutArr.compactMap { tuple -> DayAllDayInstanceViewDataType? in
                let (model, layout) = tuple
                if let instance = model as? Instance {
                    return processInstanceViewData(instance: instance,
                                                   layout: layout,
                                                   existViewDataMap: existViewDataMap)
                }
                if let timeBlock = model as? TimeBlockModel {
                    return processTimeBlockViewData(model: timeBlock,
                                                    viewSetting: viewSetting,
                                                    layout: layout)
                }
                return nil
            }
            let pageRange = DayScene.pageRange(from: limitDayRange)
            let collapsedItems = self.collapsedItems(from: instanceViewDataList, in: pageRange)
            return SectionViewData(
                expandedItems: instanceViewDataList.map { .instanceViewData($0) },
                collapsedItems: collapsedItems
            )
        }
        
        // 处理instance为InstanceViewData
        private func processInstanceViewData(instance: Instance,
                                             layout: DayAllDayPageItemLayout,
                                             existViewDataMap: [String: DayAllDayInstanceViewDataType]) -> InstanceViewData {
            let dayRange: JulianDayRange
            var calendar: CalendarModel?
            switch instance {
            case .local(let localInstance):
                calendar = calendarGetter(localInstance.calendar.calendarIdentifier)
                let startDay = JulianDayUtil.julianDay(from: localInstance.startDate, in: timeZone)
                let endDay = JulianDayUtil.julianDay(from: localInstance.endDate, in: timeZone)
                dayRange = startDay..<endDay

            case .rust(let rustInstance):
                calendar = calendarGetter(rustInstance.calendarID)
                dayRange = JulianDay(rustInstance.startDay)..<JulianDay(rustInstance.endDay + 1)
            }
            let semiViewData = SemiInstanceViewData(
                instance: instance,
                calendar: calendar,
                layout: layout,
                outOfDay: dayRange.upperBound - 1 < currentDay,
                drawRect: itemDrawRectFunc(layout.pageRange.count),
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
        
        // 处理instance为TimeBlockViewData
        private func processTimeBlockViewData(model: TimeBlockModel,
                                              viewSetting: EventViewSetting,
                                              layout: DayAllDayPageItemLayout) -> TimeBlockViewData {
            let dayRange = JulianDay(model.startDay)..<JulianDay(model.endDay + 1)
            return TimeBlockViewData(timeBlockData: model,
                                     viewSetting: viewSetting,
                                     layout: layout,
                                     outOfDay: dayRange.upperBound - 1 < currentDay,
                                     drawRect: itemDrawRectFunc(layout.pageRange.count))
        }

        func dropAllSectionViewData() {
            assert(Thread.isMainThread)
            storage.removeAll()
        }

        // collapsed（收起）阈值
        private let collapsedThresholdRow = 2

        private func collapsedItems(
            from items: [DayAllDayInstanceViewDataType],
            in pageRange: PageRange
        ) -> [SectionItem] {
            var itemWithHiddens = [(item: SectionItem, isHidden: Bool)]()
            items.forEach { itemWithHiddens.append((item: .instanceViewData($0), isHidden: false)) }

            let baseIndex = pageRange.lowerBound
            // 记录 page 被 collapsed 日程块的数量，pageCollapsedInstanceCounts[index] 表示：
            // baseIndex + index 对应的 page 的被收起的日程块数量
            var pageCollapsedInstanceCounts = [Int](repeating: 0, count: pageRange.count)

            // row > collapsedThresholdRow 的日程块一定会被 collapsed
            for i in 0..<itemWithHiddens.count where itemWithHiddens[i].item.layout.row > collapsedThresholdRow {
                itemWithHiddens[i].isHidden = true
                itemWithHiddens[i].item.layout.pageRange.forEach {
                    pageCollapsedInstanceCounts[$0 - baseIndex] += 1
                }
            }

            // row == collapsedThresholdRow 的日程块可能会被 collapsed
            let isPageCollapsed = { pageIndex -> Bool in  pageCollapsedInstanceCounts[pageIndex - baseIndex] > 0 }
            for i in 0..<itemWithHiddens.count where itemWithHiddens[i].item.layout.row == collapsedThresholdRow {
                if itemWithHiddens[i].item.layout.pageRange.contains(where: isPageCollapsed) {
                    itemWithHiddens[i].isHidden = true
                    itemWithHiddens[i].item.layout.pageRange.forEach {
                        pageCollapsedInstanceCounts[$0 - baseIndex] += 1
                    }
                }
            }

            for i in 0..<pageCollapsedInstanceCounts.count where pageCollapsedInstanceCounts[i] > 0 {
                let item = CollapsedTip(
                    title: BundleI18n.Calendar.Calendar_Plural_EventLeft(count: pageCollapsedInstanceCounts[i]),
                    layout: DayAllDayPageItemLayout(
                        pageRange: (i + baseIndex)..<(i + baseIndex + 1),
                        row: collapsedThresholdRow
                    )
                )
                itemWithHiddens.append((item: .collapsedTip(item), isHidden: false))
            }

            return itemWithHiddens.compactMap { itemWithHidden -> SectionItem? in
                guard !itemWithHidden.isHidden else { return nil }
                return itemWithHidden.item
            }
        }

    }

}
