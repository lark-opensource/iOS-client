//
//  EventPickDateViewModel.swift
//  Calendar
//
//  Created by 张威 on 2020/3/30.
//

import CalendarFoundation
import RxSwift
import RxCocoa
import LarkTimeFormatUtils
import RustPB

// Input: EditItem; Output: EditItem
final class EventPickDateViewModel {

    typealias DateRange = (start: Date, end: Date)

    struct EditItem {
        var dateRange: DateRange
        var rrule: String
        var isAllDay: Bool
        var timeZone: TimeZone  // 日程时区
        var originalTime: Int64
    }

    let rxIsAllDay = BehaviorRelay(value: false)
    let rxIs12HourStyle: BehaviorRelay<Bool>
    private let attendees: [UserAttendeeBaseDisplayInfo]

    internal private(set) var editItem: EditItem

    lazy var rxDateRangeViewData = setupDateRangeViewData()
    lazy var rxTimeZoneViewData = setupTimeZoneViewData()

    let rxDateRange: BehaviorRelay<DateRange>
    let rxTimeZone: BehaviorRelay<TimeZone>
    let rxTimeZoneModel: BehaviorRelay<TimeZoneModel>

    let rxTimezoneDisplayType: BehaviorRelay<TimezoneDisplayType>
    let rxTimezoneTip: BehaviorRelay<String?> = .init(value: nil)

    private var timeZoneCellItems: [TimeZoneCellItem] = []
    let rxReloadTableView = PublishRelay<Void>()

    // 当前选中的：startDate or endDate
    typealias DateSwitchState = EventEditDateRangeSwitchView.State
    let dateState: BehaviorRelay<DateSwitchState>

    private let disposeBag = DisposeBag()

    // For meeting room
    private let originalEvent: EventEditModel?
    private let meetingRooms: [CalendarMeetingRoom]
    private let calendarApi: CalendarRustAPI

    // Original Time-related info
    let originalIsAllDay: Bool
    private let originalDateRange: DateRange
    private let orignialTimeZone: TimeZone
    var showAllDayView: Bool {
        !isWebinarScene
    }
    let isWebinarScene: Bool
    init(
        editItem: EditItem,
        calendarApi: CalendarRustAPI,
        attendees: [UserAttendeeBaseDisplayInfo],
        meetingRooms: [CalendarMeetingRoom],
        originalEvent: EventEditModel? = nil,
        is12HourStyle: BehaviorRelay<Bool>,
        rxTimezoneDisplayType: BehaviorRelay<TimezoneDisplayType>,
        startSelected: Bool = true,
        isWebinarScene: Bool = true
    ) {
        var editItem = editItem
        if editItem.isAllDay {
            editItem.dateRange.end = Self.fixedEndDateForAllDay(
                orignalEndDate: editItem.dateRange.end,
                timeZone: editItem.timeZone
            )
        }

        self.editItem = editItem
        self.calendarApi = calendarApi
        self.attendees = attendees
        self.originalEvent = originalEvent
        self.meetingRooms = meetingRooms
        self.originalDateRange = editItem.dateRange
        self.originalIsAllDay = editItem.isAllDay
        self.orignialTimeZone = editItem.timeZone
        self.dateState = BehaviorRelay(value: startSelected ? .start : .end)
        self.isWebinarScene = isWebinarScene

        self.rxTimezoneDisplayType = rxTimezoneDisplayType

        rxIs12HourStyle = is12HourStyle
        rxDateRange = BehaviorRelay(value: editItem.dateRange)
        rxTimeZone = BehaviorRelay(value: editItem.timeZone)
        rxTimeZoneModel = BehaviorRelay(value: rxTimeZone.value)
        rxTimeZone.map { $0 as TimeZoneModel }.bind(to: rxTimeZoneModel).disposed(by: disposeBag)

        updateIsAllDay(editItem.isAllDay)

        typealias CellItemRelatedTuple = (dateRange: DateRange, isAllDay: Bool, timeZone: TimeZone, timezoneDisplayType: TimezoneDisplayType, is12HourStyle: Bool)
        Observable.combineLatest(rxDateRange, rxIsAllDay, rxTimeZone, self.rxTimezoneDisplayType, rxIs12HourStyle)
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged { (before: CellItemRelatedTuple, after: CellItemRelatedTuple) -> Bool in
                return before.dateRange.start == after.dateRange.start
                    && before.dateRange.end == after.dateRange.end
                    && before.isAllDay == after.isAllDay
                    && before.timeZone.identifier == after.timeZone.identifier
                    && before.timezoneDisplayType == after.timezoneDisplayType
                    && before.is12HourStyle == after.is12HourStyle
            }
            .bind(onNext: { [weak self] (tuple: CellItemRelatedTuple) in
                self?.updateCellItems(timeZone: tuple.timezoneDisplayType == .eventTimezone ? tuple.timeZone : .current)
                self?.rxReloadTableView.accept(())
                self?.updateTimezoneTip(timezoneDisplayType: tuple.timezoneDisplayType,
                                        eventTimezone: tuple.timeZone,
                                        startDate: tuple.dateRange.start,
                                        endDate: tuple.dateRange.end,
                                        is12HourStyle: tuple.is12HourStyle)
            })
            .disposed(by: disposeBag)

        Observable.combineLatest(rxDateRange, rxIsAllDay, rxTimeZone)
            .bind { [weak self] tuple in
                guard let self = self else { return }
                let (dateRange, isAllDay, timeZone) = tuple
                var fixedDateRange = dateRange
                if isAllDay {
                    fixedDateRange.start = fixedDateRange.start.dayStart()
                    fixedDateRange.end = fixedDateRange.end.dayEnd()
                }
                var newEditItem = self.editItem
                newEditItem.dateRange = fixedDateRange
                newEditItem.isAllDay = isAllDay
                newEditItem.timeZone = timeZone
                self.editItem = newEditItem
            }
            .disposed(by: disposeBag)
    }

    private func updateTimezoneTip(timezoneDisplayType: TimezoneDisplayType,
                                   eventTimezone: TimeZone,
                                   startDate: Date,
                                   endDate: Date,
                                   is12HourStyle: Bool) {
        if self.isTimezoneDiff {
            let tip = timezoneDisplayType == .deviceTimezone ? BundleI18n.Calendar.Calendar_G_InEventTimeZone : BundleI18n.Calendar.Calendar_G_InDeviceTimeZone
            let opt = Options(timeZone: timezoneDisplayType == .deviceTimezone ? eventTimezone : .current,
                              is12HourStyle: is12HourStyle,
                              shouldShowGMT: true,
                              timePrecisionType: .minute,
                              datePrecisionType: .day)
            let timedate = CalendarTimeFormatter.formatTimeOrDateTimeRange(startFrom: startDate,
                                                                           endAt: endDate,
                                                                           mirrorTimezone: (timezoneDisplayType == .deviceTimezone) ? TimeZone.current : eventTimezone,
                                                                           with: opt)
            rxTimezoneTip.accept("\(tip) \(timedate)")
        } else {
            rxTimezoneTip.accept(nil)
        }

    }

    private func updateCellItems(timeZone: TimeZone) {
        let (dateRange, isAllDay, is12HourStyle) =
            (rxDateRange.value, rxIsAllDay.value, rxIs12HourStyle.value)
        guard !isAllDay else {
            timeZoneCellItems = []
            return
        }

        // 根据 offset，对 attendees 进行聚合
        let timeZoneAttendeeItems = resetGroupedTimeZoneAttendeeItems(with: dateRange.start)
        let currentTimeZoneOffset = timeZone.getSecondsFromGMT(date: dateRange.start)
        var set: Set<Int> = Set(timeZoneAttendeeItems.map { $0.offset })
        set.insert(currentTimeZoneOffset)
        guard set.count > 1 else {
            timeZoneCellItems = []
            return
        }
        let localTimeZoneOffset = TimeZone.current.secondsFromGMT(for: dateRange.start)

        var cellItems = [TimeZoneCellItem]()
        for item in timeZoneAttendeeItems {
            let cellItem = TimeZoneCellItem(
                dateRange: dateRange,
                timeZone: item.offset != -1 ? item.timeZone : nil,
                is12HourStyle: is12HourStyle,
                isSameDay: isSameDay(for: dateRange, accordingTo: item.timeZone),
                isLocal: localTimeZoneOffset == item.offset,
                attendees: item.attendees
            )
            cellItems.append(cellItem)
        }
        cellItems.sort { (lhs, rhs) -> Bool in
            // 本地优先
            if lhs.isLocal { return true }
            if rhs.isLocal { return false }
            // 隐藏排最后
            guard let lhsTZ = lhs.timeZone, let rhsTZ = rhs.timeZone else { return lhs.timeZone != nil }
            // 根据 start 排序
            return lhsTZ.secondsFromGMT(for: lhs.startDate) <= rhsTZ.secondsFromGMT(for: rhs.startDate)
        }

        timeZoneCellItems = cellItems
    }

    private func isSameDay(for dateRange: DateRange, accordingTo timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.isDate(dateRange.start, equalTo: dateRange.end, toGranularity: .day)
    }

}

// MARK: Utils

extension EventPickDateViewModel {

    // 全天日程的 endDate，如果是 2020.05.21 00:00:00，则调整为前一天的最后一秒
    //   譬如：2020.05.21 00:00:00
    //   调为：2020.05.20 23:59:59
    class func fixedEndDateForAllDay(
        orignalEndDate: Date,
        timeZone: TimeZone
    ) -> Date {
        var calendar = Calendar.gregorianCalendar
        calendar.timeZone = timeZone
        let startOfDay = calendar.startOfDay(for: orignalEndDate)
        if Int64(startOfDay.timeIntervalSince1970) == Int64(orignalEndDate.timeIntervalSince1970) {
            return orignalEndDate.addingTimeInterval(-1)
        } else {
            return orignalEndDate
        }
    }

    class func isSameDay(for dateRange: DateRange) -> Bool {
        Calendar.gregorianCalendar.isDate(dateRange.start, inSameDayAs: dateRange.end)
    }

    class func isValid(for dateRange: DateRange, isAllDay: Bool) -> Bool {
        if isAllDay {
            return isSameDay(for: dateRange) || dateRange.end >= dateRange.start
        }
        return dateRange.end >= dateRange.start
    }

    class func transformedDate(for source: Date, from: TimeZoneModel, to: TimeZoneModel) -> Date {
        TimeZoneUtil.dateTransForm(
            srcDate: source,
            srcTzId: from.identifier,
            destTzId: to.identifier
        )
    }

    class func transformedDateRange(
        for source: DateRange,
        from: TimeZoneModel,
        to: TimeZoneModel
    ) -> DateRange {
        let start = transformedDate(for: source.start, from: from, to: to)
        let end = transformedDate(for: source.end, from: from, to: to)
        return (start, end)
    }
}

// MARK: Grouped Attendees

extension EventPickDateViewModel {

    struct GroupedTimeZoneAttendeeItem {
        var offset: Int
        var timeZone: TimeZone
        var attendees: [UserAttendeeBaseDisplayInfo]
    }

    private func resetGroupedTimeZoneAttendeeItems(with date: Date) -> [GroupedTimeZoneAttendeeItem] {
        let offsetSet = TimeZoneUtil.groupedGmtOffset(for: attendees.map { $0.timeZone })
        var itemMap = [Int: GroupedTimeZoneAttendeeItem]()
        for offset in offsetSet {
            itemMap[offset] = GroupedTimeZoneAttendeeItem(
                offset: offset,
                timeZone: TimeZone(secondsFromGMT: offset) ?? TimeZone.current,
                attendees: []
            )
        }
        let localTimeZoneOffset = TimeZone.current.secondsFromGMT(for: date)
        if itemMap[localTimeZoneOffset] == nil {
            itemMap[localTimeZoneOffset] = GroupedTimeZoneAttendeeItem(
                offset: localTimeZoneOffset,
                timeZone: TimeZone.current,
                attendees: []
            )
        }

        for attendee in attendees {
            let offset = attendee.timeZone?.getSecondsFromGMT(date: date) ?? TimeZoneUtil.HiddenOffsetFlag
            itemMap[offset]?.attendees.append(attendee)
        }

        return Array(itemMap.values)
    }
}

// MARK: check change
extension EventPickDateViewModel {
    func hasSomeChange() -> Bool {
        let dateRangeChanged = editItem.dateRange != originalDateRange
        let allDayChanged = editItem.isAllDay != originalIsAllDay
        let timeZoneChanged = editItem.timeZone != orignialTimeZone
        return dateRangeChanged || allDayChanged || timeZoneChanged
    }
}

// MARK: Check Date Valid

extension EventPickDateViewModel {

    func isDateValid() -> Bool {
        return EventPickDateViewModel.isValid(
            for: editItem.dateRange,
            isAllDay: editItem.isAllDay
        )
    }

}

// MARK: for IsAllDay

extension EventPickDateViewModel {

    // 切换「全天」 <-> 「非全天」
    func updateIsAllDay(_ isAllDay: Bool) {
        guard rxIsAllDay.value != isAllDay else { return }
        rxIsAllDay.accept(isAllDay)
        // 如果是全天日程，且时区并非设备时区，则主动将时区切换到本地时区
        if isAllDay && rxTimeZone.value.identifier != TimeZone.current.identifier {
            updateTimeZone(TimeZone.current)
        }
    }

}

// MARK: for DateRangeView

extension EventPickDateViewModel {

    struct DateRangeViewData: EventEditDateRangeSwitchViewDateType {
        var startDate: Date
        var endDate: Date
        var isAllDay: Bool
        var isEndDateValid: Bool
        var timeZone: TimeZone
        var is12HourStyle: Bool
    }

    private func setupDateRangeViewData() -> Observable<EventEditDateRangeSwitchViewDateType> {
        Observable.combineLatest(rxIs12HourStyle, rxDateRange, rxIsAllDay, rxTimeZone, rxTimezoneDisplayType)
            .map { tuple in
                let (is12HourStyle, dateRange, isAllDay, timeZone, timezoneDisplayType) = tuple
                let isEndDateValid = Self.isValid(for: dateRange, isAllDay: isAllDay)

                return DateRangeViewData(
                    startDate: dateRange.start,
                    endDate: dateRange.end,
                    isAllDay: isAllDay,
                    isEndDateValid: isEndDateValid,
                    timeZone: timezoneDisplayType == .eventTimezone ? timeZone : .current,
                    is12HourStyle: is12HourStyle
                )
            }
    }

    func updateDateRange(_ dateRange: DateRange) {
        guard rxDateRange.value != dateRange else { return }
        rxDateRange.accept(dateRange)
    }
}

// MARK: for DatePickerView

extension EventPickDateViewModel {

    // DatePicker 不支持 TimeZone，为了正确显示，需要转一下 date

    var startDateForDatePicker: Date {
        Self.transformedDate(for: rxDateRange.value.start, from: self.displayedTimezone(eventTimezone: rxTimeZone.value), to: TimeZone.current)
    }

    var endDateForDatePicker: Date {
        Self.transformedDate(for: rxDateRange.value.end, from: self.displayedTimezone(eventTimezone: rxTimeZone.value), to: TimeZone.current)
    }

    func updateStartDate(_ date: Date) {
        let fixedDate = Self.transformedDate(for: date, from: TimeZone.current, to: self.displayedTimezone(eventTimezone: rxTimeZone.value))
        var dateRange = rxDateRange.value
        if Self.isValid(for: dateRange, isAllDay: rxIsAllDay.value) {
            let diff = dateRange.end.timeIntervalSince(dateRange.start)
            dateRange.end = fixedDate + diff
        }
        dateRange.start = fixedDate
        rxDateRange.accept(dateRange)
    }

    func updateEndDate(_ date: Date) {
        let fixedDate = Self.transformedDate(for: date, from: TimeZone.current, to: self.displayedTimezone(eventTimezone: rxTimeZone.value))
        var dateRange = rxDateRange.value
        dateRange.end = fixedDate
        rxDateRange.accept(dateRange)
    }

}

// MARK: for TimeZoneView

extension EventPickDateViewModel {

    private func setupTimeZoneViewData() -> Observable<String> {
        Observable.combineLatest(rxTimeZone, rxDateRange, dateState, rxTimezoneDisplayType)
            .map { (timeZone, dateRange, dateState, timezoneDisplayType) in
                let anchorDate = dateState == .start ? dateRange.start : dateRange.end
                let displayedTimezone = timezoneDisplayType == .eventTimezone ? timeZone : .current
                return displayedTimezone.standardName(for: anchorDate)
            }
    }

    func updateTimeZone(_ timeZone: TimeZoneModel) {
        let timeZone = timeZone as? TimeZone
            ?? TimeZone(identifier: timeZone.identifier)
            ?? TimeZone(secondsFromGMT: timeZone.secondsFromGMT)
            ?? TimeZone.current
        let dateRange = Self.transformedDateRange(for: rxDateRange.value, from: rxTimeZone.value, to: timeZone)
        switchToEventTimezone()
        rxTimeZone.accept(timeZone)
        rxDateRange.accept(dateRange)
    }

    func switchToEventTimezone() {
        EventEdit.logger.info("switchToEventTimezone, timezone display type: \(rxTimezoneDisplayType.value)")
        if rxTimezoneDisplayType.value == .deviceTimezone {
            rxTimezoneDisplayType.accept(.eventTimezone)
        }
    }

    var shouldSwitchToEventTimezone: Bool {
        let isDiff = isTimezoneDiff
        let isDeviceTimezone = rxTimezoneDisplayType.value == .deviceTimezone
        EventEdit.logger.info("shouldSwitchToEventTimezone, isDeviceTimezone: \(isDeviceTimezone), timezone diff: \(isDiff)")
        return isDeviceTimezone && isDiff
    }

    var isTimezoneDiff: Bool {
        TimeZoneUtil.areTimezonesDifferent(timezones: [.current, rxTimeZone.value])
    }

    func displayedTimezone(eventTimezone: TimeZone) -> TimeZone {
        switch rxTimezoneDisplayType.value {
        case .eventTimezone:
            return eventTimezone
        default:
            return .current
        }
    }

    var timezoneDisplayType: TimezoneDisplayType {
        rxTimezoneDisplayType.value
    }

    var pbEvent: RustPB.Calendar_V1_CalendarEvent? {
        originalEvent?.getPBModel()
    }
}

// MARK: TimeZone TableView

extension EventPickDateViewModel {

    typealias TimeZoneCellDataType = EventEditDatePickerAttendeeTimeZoneCellDataType

    struct TimeZoneCellItem: TimeZoneCellDataType {
        var dateRange: DateRange
        var timeZone: TimeZone?
        var is12HourStyle: Bool
        var isSameDay: Bool
        var isLocal: Bool
        var attendees: [UserAttendeeBaseDisplayInfo]

        var startDate: Date { dateRange.start }
        var endDate: Date { dateRange.end }
        var avatars: [Avatar] { attendees.map { $0.avatar } }
    }

    var shouldShowAttendeeTimeZoneTableView: Bool { !timeZoneCellItems.isEmpty }

    func numberOfRows() -> Int { timeZoneCellItems.count }

    func cellData(forRowAt index: Int) -> TimeZoneCellDataType? {
        guard index >= 0 && index < timeZoneCellItems.count else {
            return nil
        }
        return timeZoneCellItems[index]
    }

    typealias DateRangeAttendeesPair = (dateRange: DateRange, attendees: [UserAttendeeBaseDisplayInfo])
    func dateRangeAttendeesPair(at index: Int) -> DateRangeAttendeesPair? {
        guard index >= 0 && index < timeZoneCellItems.count else {
            return nil
        }
        let cellItem = timeZoneCellItems[index]
        return (cellItem.dateRange, cellItem.attendees)
    }

}

// MARK: for Meeting Room
extension EventPickDateViewModel {
    func resetCellItemsData() {
        updateIsAllDay(originalIsAllDay)
        updateTimeZone(orignialTimeZone)
        updateDateRange(originalDateRange)
    }

}
