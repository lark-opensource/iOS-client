//
//  TimePickerViewModel.swift
//  Todo
//
//  Created by 白言韬 on 2021/7/8.
//

import RxSwift
import RxCocoa
import LarkContainer
import LarkTimeFormatUtils
import CTFoundation
import EventKit

final class TimePickerViewModel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver

    var rxRange = BehaviorRelay<TimePickRangeData>(value: TimePickRangeData(selected: .due))
    var rxDueTime = BehaviorRelay<Date?>(value: nil)
    var rxStartTime = BehaviorRelay<Date?>(value: nil)
    var rxPickerState = BehaviorRelay<PickerState>(value: .none)
    var rxReminder = BehaviorRelay<ReminderType>(value: NonAllDayReminder.noAlert)
    var rxIsAllDay = BehaviorRelay<Bool>(value: false)
    var rxRRule = BehaviorRelay<String?>(value: nil)
    lazy var lastIsAllDay: Bool = rxIsAllDay.value
    // for track
    var guid: String? { detailExtra?.guid }
    // for display
    var isRruleReadable: Bool { detailExtra?.rrulePermission?.isReadable ?? true }
    var isRruleReadOnly: Bool { detailExtra?.rrulePermission?.isReadOnly ?? false }
    var isRruleVisible: Bool { detailExtra?.rrulePermission?.isVisible ?? true }

    private var detailExtra: DetailExtra?
    struct DetailExtra {
        var guid: String?
        var rrulePermission: PermissionOption?
    }

    private var startTimeFG: Bool {
        return FeatureGating(resolver: userResolver).boolValue(for: .startTime)
    }

    @ScopedInjectedLazy var timeService: TimeService?
    @ScopedInjectedLazy private var settingService: SettingService?

    var timeZone: TimeZone { timeService?.rxTimeZone.value ?? .current }
    var is12HourStyle: Bool { timeService?.rx12HourStyle.value ?? false }
    private var utcTimeZone: TimeZone { timeService?.utcTimeZone ?? .current }

    private var isUseDefaultDueTime = false
    private var outerReminder: OuterReminder?
    private let disposeBag = DisposeBag()

    init(
        resolver: UserResolver,
        tuple: DueRemindTuple? = nil,
        detailExtra: DetailExtra? = nil
    ) {
        self.userResolver = resolver
        self.detailExtra = detailExtra
        TimePicker.logger.info("enter timePicker with tuple: \(tuple?.logInfo ?? "nil")")
        var newTuple = tuple ?? defaultDueRemindTuple()
        newTuple = fixAllDayDueTime(newTuple)

        if let dueTime = newTuple.dueTime {
            rxDueTime.accept(Date(timeIntervalSince1970: TimeInterval(dueTime)))
        }
        if let startTime = newTuple.startTime {
            rxStartTime.accept(Date(timeIntervalSince1970: TimeInterval(startTime)))
        }
        if case .relativeToDueTime(let minutes) = newTuple.reminder {
            updateReminder(by: minutes, with: newTuple.isAllDay)
        } else {
            rxReminder.accept(NonAllDayReminder.noAlert)
        }
        rxIsAllDay.accept(newTuple.isAllDay)
        rxRRule.accept(newTuple.rrule)

        if !startTimeFG {
            //  跳过默认值
            rxIsAllDay.skip(1)
                .subscribe(onNext: { [weak self] isAllDay in
                    self?.rxPickerState.accept(.none)
                    self?.rxReminder.accept(
                        isAllDay ? AllDayReminder.onDayOfEventAt9am : NonAllDayReminder.atTimeOfEvent
                    )
                })
                .disposed(by: disposeBag)
        }
    }

    private func defaultDueRemindTuple() -> DueRemindTuple {
        isUseDefaultDueTime = true

        let timestamp = V3ListTimeGroup.DueTime.tomorrow.defaultDueTime(
            by: settingService?.defaultDueTimeDayOffset ?? 0,
            timeZone: timeZone,
            isAllDay: startTimeFG
        )
        var offset = settingService?.value(forKeyPath: \.dueReminderOffset) ?? 0
        if startTimeFG {
            offset = AllDayReminder.onDayofEventAt6pm.rawValue
        }
        offset = Utils.Reminder.fixReminder(by: timestamp, offset: offset)

        let tuple = DueRemindTuple(
            startTime: nil,
            dueTime: timestamp,
            reminder: .relativeToDueTime(offset),
            isAllDay: startTimeFG,
            rrule: nil
        )
        TimePicker.logger.info("use default tuple: \(tuple.logInfo)")
        return tuple
    }

    private func fixAllDayDueTime(_ timeTuple: DueRemindTuple) -> DueRemindTuple {
        guard timeTuple.isAllDay else { return timeTuple }
        isUseDefaultDueTime = true

        var startTime = timeTuple.startTime ?? 0
        if startTime > 0 {
            let julianDay = JulianDayUtil.julianDay(from: startTime, in: utcTimeZone)
            if startTime != JulianDayUtil.startOfDay(for: julianDay, in: utcTimeZone) {
                TimePicker.logger.info("satrt time of allDay must be 00:00:00 dueTime:\(startTime)")
            }
            startTime = JulianDayUtil.startOfDay(for: julianDay, in: timeZone)
        }

        var dueTime = timeTuple.dueTime ?? 0
        if dueTime > 0 {
            let julianDay = JulianDayUtil.julianDay(from: dueTime, in: utcTimeZone)
            if dueTime != JulianDayUtil.startOfDay(for: julianDay, in: utcTimeZone) {
                TimePicker.logger.info("dueTime of allDay must be 00:00:00 dueTime:\(dueTime)")
            }
            dueTime = JulianDayUtil.startOfDay(for: julianDay, in: timeZone)
        }

        let tuple = DueRemindTuple(
            startTime: startTime > 0 ? startTime : nil,
            dueTime: dueTime > 0 ? dueTime : nil,
            reminder: timeTuple.reminder,
            isAllDay: timeTuple.isAllDay,
            rrule: timeTuple.rrule
        )
        TimePicker.logger.info("fix all day. tuple: \(tuple.logInfo)")
        return tuple
    }

}

// MARK: - ReadOnly

extension TimePickerViewModel {

    var isRangeSelectStart: Bool {
        if case .due = rxRange.value.selected {
            return false
        }
        return true
    }

    /// 提醒是否有效
    var isReminderValid: Bool {
        if rxIsAllDay.value {
            guard (rxReminder.value as? AllDayReminder) != nil else {
                return false
            }
            return true
        } else {
            guard let reminder = rxReminder.value as? NonAllDayReminder else {
                return false
            }
            guard reminder != .noAlert else { return false }
            return true
        }
    }

    var hasReminderValue: Bool {
        if (rxReminder.value as? AllDayReminder) != nil {
            return true
        }
        if let reminder = rxReminder.value as? NonAllDayReminder, reminder != .noAlert {
            return true
        }
        return false
    }

}

// MARK: - View Data

extension TimePickerViewModel {
    func timeTile(_ dueTime: Date?) -> String? {
        guard let dueTime = dueTime else { return nil }
        guard !rxIsAllDay.value else { return nil }
        let options = Options(timeZone: timeZone,
                              is12HourStyle: is12HourStyle,
                              timePrecisionType: .minute,
                              shouldRemoveTrailingZeros: false)
        return TimeFormatUtils.formatTime(from: dueTime, with: options)
    }

    func weekdayTime(_ time: Date?) -> String? {
        guard let time = time else { return nil }
        let options = Options(
            timeZone: timeZone,
            is12HourStyle: is12HourStyle,
            timeFormatType: .short,
            datePrecisionType: .day
        )
        let date = TimeFormatUtils.formatDate(from: time, with: options)
        let weekDay = TimeFormatUtils.formatWeekday(from: time, with: options)
        return "\(date) \(weekDay)"
    }

    func updateTimeRangeData() {
        var data = rxRange.value
        data.startDateStr = weekdayTime(rxStartTime.value)
        data.startTimeStr = timeTile(rxStartTime.value)

        data.dueDateStr = weekdayTime(rxDueTime.value)
        data.dueTimeStr = timeTile(rxDueTime.value)

        rxRange.accept(data)
    }

    func updateReminderData(cause isAllDayChanged: Bool = false) {
        guard startTimeFG else { return }
        guard rxDueTime.value != nil else {
            rxReminder.accept(NonAllDayReminder.noAlert)
            return
        }
        guard isAllDayChanged else { return }
        // 提醒之前有值才需要切换默认值
        guard hasReminderValue else { return }

        var offset = settingService?.value(forKeyPath: \.dueReminderOffset) ?? 0
        if rxIsAllDay.value {
            offset = AllDayReminder.onDayofEventAt6pm.rawValue
        }
        updateReminder(by: offset, with: rxIsAllDay.value)
    }


    func updateReminder(by minutes: Int64, with isAllDay: Bool) {
        if isAllDay {
            let newReminder: ReminderType
            if let reminder = AllDayReminder(rawValue: minutes) {
                newReminder = reminder
            } else {
                let outer = OuterReminder(minutes: minutes)
                newReminder = outer
            }
            rxReminder.accept(newReminder)
        } else {
            let newReminder: ReminderType
            if let reminder = NonAllDayReminder(rawValue: minutes) {
                newReminder = reminder
            } else {
                let outer = OuterReminder(minutes: minutes)
                newReminder = outer
            }
            rxReminder.accept(newReminder)
        }
    }

    func reminderTitle(_ reminder: ReminderType) -> String {
        return Utils.Reminder.reminderStr(
            minutes: reminder.minutes,
            isAllDay: rxIsAllDay.value,
            is12HourStyle: is12HourStyle
        )
    }

    func rowOfCurReminder() -> Int {
        if startTimeFG, !hasReminderValue {
            didSeletedReminder(at: 0)
            return 0
        }
        guard let index = curReminders.firstIndex(where: { $0.minutes == rxReminder.value.minutes }) else {
            TimePicker.assertionFailure("reminder picker curReminders and rxReminder don't match", type: .outOfRange)
            didSeletedReminder(at: 0)
            return 0
        }
        return index
    }
}

// MARK: - View Action

extension TimePickerViewModel {

    var dueTimePickerValue: Date {
        if startTimeFG {
            return pickerValue(isStart: false)
        }
        return rxDueTime.value ?? Date()
    }

    var startTimePickerValue: Date { pickerValue(isStart: true) }

    private func pickerValue(isStart: Bool) -> Date {
        let defalutValue = isStart ? rxStartTime.value : rxDueTime.value
        let newDate = defalutValue ?? Date()
        // 全天任务或者没有值的时候需要加上offSet
        if rxIsAllDay.value || defalutValue == nil {
            return offSetDate(isStart: isStart, date: newDate)
        }
        return newDate
    }

    private func offSetDate(isStart: Bool, date: Date) -> Date {
        let offSet = isStart ? settingService?.defaultStartTimeDayOffset : settingService?.defaultDueTimeDayOffset
        //skipToday： 选择截止时间的时候，需要去校验今天截止是否超过默认的18点。选开始时间不需要验证今天的offset
        return Utils.DueTime.defaultDaytime(
            byOffset: offSet ?? 0,
            date: date,
            skipToday: isStart,
            timeZone: timeZone
        )
    }

    /// 去掉时间，变成全天
    func cleanTime(isStart: Bool) {
        rxIsAllDay.accept(true)
        rxPickerState.accept(.none)
        let date = isStart ? rxStartTime.value : rxDueTime.value
        guard let date = date else {
            TimePicker.logger.info("clean time but date is nil")
            return
        }
        setRxTime(isStart: isStart, date: startOfDate(date), skipOffset: true, changeIsAllDay: false)
    }

    /// 更新时分
    /// - Parameters:
    ///   - isStart: 是否开始时间
    ///   - date: 日期
    /// - Returns: 是否需要更新日期
    func onTimePickerUpdated(isStart: Bool, date: Date) -> Bool {
        TimePicker.logger.info("onTimePickerUpdated. start: \(isStart), date: \(date)")
        // 从无到有, 需要额外选中日历
        guard let oldTime = isStart ? rxStartTime.value : rxDueTime.value else {
            TimePicker.logger.info("currrent time is nil")
            return setRxTime(isStart: isStart, date: date)
        }
        let offset = date.timeIntervalSince(startOfDate(date))
        var newTime = startOfDate(oldTime).addingTimeInterval(offset)
        if is12HourStyle {
            if offset >= 0 && offset < Utils.TimeFormat.OneHour {
                /// 因为下午12:00选取为选中天的 16:xx +0000，实际上需要使用下一天的 16:xx +0000
                newTime = startOfDate(date).addingTimeInterval(Utils.TimeFormat.HalfDay + offset)
            } else if offset >= Utils.TimeFormat.HalfDay && offset < (Utils.TimeFormat.HalfDay + Utils.TimeFormat.OneHour) {
                /// 因为上午12:00选取为选中天的04:xx +0000，实际上需要使用上一天的 16:xx +0000
                newTime = startOfDate(date).addingTimeInterval(offset - Utils.TimeFormat.HalfDay)
            }
        }
        return setRxTime(isStart: isStart, date: newTime)
    }

    @discardableResult
    private func setRxTime(isStart: Bool, date: Date, skipOffset: Bool = false, changeIsAllDay: Bool = true) -> Bool {
        let tuple = checkTimeValid(isStart: isStart, date: date, skipOffset: skipOffset)
        if startTimeFG, changeIsAllDay {
            rxIsAllDay.accept(false)
        }
        if let start = tuple.start {
            rxStartTime.accept(start)
        }
        if let due = tuple.due {
            rxDueTime.accept(due)
        }
        return tuple.changd
    }

    private func checkTimeValid(isStart: Bool, date: Date, skipOffset: Bool) -> (start: Date?, due: Date?, changd: Bool) {
        if isStart {
            // 当有截止时间才需要校验
            if var due = rxDueTime.value {
                // 当需要更新时间，并且之前是全天任务的时候，需要额外加上offset
                if !skipOffset, rxIsAllDay.value {
                    due = offSetDate(isStart: false, date: due)
                }
                if date.compare(due) == .orderedDescending {
                    return (date, date, true)
                }
                return (date, due, false)
            }
            return (date, nil, false)
        } else {
            if var start = rxStartTime.value {
                if !skipOffset, rxIsAllDay.value {
                    start = offSetDate(isStart: true, date: start)
                }
                if start.compare(date) == .orderedDescending {
                    return (date, date, true)
                }
                return (start, date, false)
            }
            return (nil, date, false)
        }
    }

    // 只更新年月日
    @discardableResult
    func onCalendarUpdated(isStart: Bool, date: Date?) -> Bool {
        guard let date = date else {
            TimePicker.logger.info("did clean time")
            isStart ? rxStartTime.accept(nil) : rxDueTime.accept(nil)
            return false
        }
        TimePicker.logger.info("onCalendarUpdated. start: \(isStart), date: \(date)")
        guard let oldTime = isStart ? rxStartTime.value : rxDueTime.value else {
            TimePicker.logger.info("select calendar but time is nil")
            return setRxTime(
                isStart: isStart,
                date: offSetDate(isStart: isStart, date: date),
                skipOffset: true,
                changeIsAllDay: !rxIsAllDay.value
            )
        }
        let offset = oldTime.timeIntervalSince(startOfDate(oldTime))
        let newTime = startOfDate(date).addingTimeInterval(offset)
        return setRxTime(isStart: isStart, date: newTime, skipOffset: true, changeIsAllDay: !rxIsAllDay.value)
    }

    private func startOfDate(_ date: Date) -> Date {
        let timeZone = timeZone
        let day = JulianDayUtil.julianDay(from: date, in: timeZone)
        let startOfDay = JulianDayUtil.startOfDay(for: day, in: timeZone)
        return Date(timeIntervalSince1970: TimeInterval(startOfDay))
    }

    func onDueTimePickerToggle() {
        TimePicker.logger.info("onDueTimePickerToggle. \(rxPickerState.value)")
        if case .dueTime = rxPickerState.value {
            rxPickerState.accept(.none)
        } else {
            rxPickerState.accept(.dueTime)
        }
    }

    func onStartTimePickerToggle() {
        TimePicker.logger.info("onStartTimePickerToggle. \(rxPickerState.value)")
        if case .startTime = rxPickerState.value {
            rxPickerState.accept(.none)
        } else {
            rxPickerState.accept(.startTime)
        }
    }

    func onReminderPickerToggle() {
        TimePicker.logger.info("onReminderPickerToggle. \(rxPickerState.value)")
        if case .reminder = rxPickerState.value {
            rxPickerState.accept(.none)
        } else {
            rxPickerState.accept(.reminder)
        }
    }

    func canDisplayCloseIcon(_ state: PickerState) -> Bool {
        switch state {
        case .startTime:
            if case .startTime = rxPickerState.value {
                return false
            }
            if rxIsAllDay.value { return false }
            return rxStartTime.value != nil
        case .dueTime:
            if case .dueTime = rxPickerState.value {
                return false
            }
            if rxIsAllDay.value { return false }
            return rxDueTime.value != nil
        case .reminder:
            if case .reminder = rxPickerState.value {
                return false
            }
            return isReminderValid
        case .none:
            return true
        }
    }

    func getDueRemindTuple() -> DueRemindTuple {
        let reminder: Reminder?
        if rxReminder.value.minutes == NonAllDayReminder.noAlert.rawValue {
            reminder = nil
        } else {
            reminder = .relativeToDueTime(rxReminder.value.minutes)
        }
        let tuple = DueRemindTuple(
            startTime: getCurrentTime(isStart: true),
            dueTime: getCurrentTime(isStart: false),
            reminder: reminder,
            isAllDay: rxIsAllDay.value,
            rrule: rxRRule.value
        )
        TimePicker.logger.info("saving tuple: \(tuple.logInfo)")
        return tuple
    }

    func getCurrentTime(isStart: Bool) -> Int64 {
        let date = isStart ? rxStartTime.value : rxDueTime.value
        guard let date = date else { return 0 }
        var dueTime = Int64(date.timeIntervalSince1970)
        if rxIsAllDay.value {
            let julianDay = JulianDayUtil.julianDay(from: dueTime, in: timeZone)
            dueTime = JulianDayUtil.startOfDay(for: julianDay, in: utcTimeZone)
        }
        return dueTime
    }

    func cleanReminder() {
        rxPickerState.accept(.none)
        rxReminder.accept(NonAllDayReminder.noAlert)
    }

    // 更新重复
    func updateRRule(_ rrule: String?) {
        rxRRule.accept(rrule)
    }

    func switchRange(with type: TimePickRangeData.RangeType) {
        var viewData = rxRange.value
        viewData.selected = type
        rxRange.accept(viewData)
        // 重置状态
        rxPickerState.accept(.none)
    }

    func cleanRange(type: TimePickRangeData.RangeType) {
        if type == .due {
            rxReminder.accept(NonAllDayReminder.noAlert)
            updateRRule(nil)
        }
        rxPickerState.accept(.none)
    }
}

// MARK: - ReminderPicker

extension TimePickerViewModel {

    func reminderPickerItemCount() -> Int { curReminders.count }

    func reminderPickerItemTitle(at index: Int) -> String {
        guard reminderPickerIndexCheck(at: index) else { return "" }
        return reminderTitle(curReminders[index])
    }

    func didSeletedReminder(at index: Int) {
        guard reminderPickerIndexCheck(at: index) else { return }
        rxReminder.accept(curReminders[index])
    }

    private func reminderPickerIndexCheck(at index: Int) -> Bool {
        guard index > -1, index < curReminders.count else {
            TimePicker.assertionFailure("reminder picker out of index: \(index) cur count: \(curReminders.count)", type: .outOfRange)
            return false
        }
        return true
    }

    private var curReminders: [ReminderType] {
        let nonAllDayReminders: [NonAllDayReminder] = [
            .atTimeOfEvent,
            .fiveMinutesBefore,
            .aQuarterBefore,
            .halfAnHourBefore,
            .anHourBefore,
            .twoHoursBefore,
            .aDayBefore,
            .twoDaysBefore,
            .aWeekBefore
        ]
        var allDayReminders: [AllDayReminder] = [.aDayBeforeAt9am, .twoDaysBeforeAt9am, .aWeekBeforeAt9am]
        if startTimeFG {
            allDayReminders.insert(.onDayofEventAt6pm, at: 0)
        } else {
            allDayReminders.insert(.onDayOfEventAt9am, at: 0)
        }
        var value: [ReminderType] = rxIsAllDay.value ? allDayReminders : nonAllDayReminders
        if let outer = outerReminder {
            value.insert(
                outer,
                at: value.firstIndex(where: { $0.minutes > outer.minutes }) ?? value.endIndex
            )
        }
        if startTimeFG {
            return value
        }
        return [NonAllDayReminder.noAlert] + value
    }
}
