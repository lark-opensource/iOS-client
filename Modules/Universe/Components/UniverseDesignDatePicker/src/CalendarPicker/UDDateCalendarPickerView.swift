//
//  UDDateCalendarPickerView.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2021/3/17.
//

import Foundation
import UIKit
import EventKit

public protocol UDDatePickerViewDelegate: AnyObject {
    /// customize CalendarCell，组件提供默认实现
    /// - Parameters:
    ///   - calendarCell: 自定义 cell，这里是一个空壳子 UDCalendarPickerCell，对自定义的子类进行配置即可
    ///   - date: cell 对应 Date
    ///   - cellState: cell 对应内容
    ///   - indexPath: cell 坐标
    func customizeCalendarCell(_ calendarCell: UDCalendarPickerCell,
                               cellForItemAt date: Date,
                               cellState: CellState) -> UDCalendarPickerCell

    /// 传出当前停留页信息
    ///  若 autoSelectedDate == true，参数 date 同 dateChanged 参数相同，
    ///  若 autoSelectedDate == false，date 为当前月的第一天（或当前「周」与当前选中日期 weekday 相同的那天）或 选中的那天
    /// - Parameter date: 代表页面改变后对应「月/周」信息的一天
    func calendarScrolledTo(_ date: Date, _ sender: UDDateCalendarPickerView)

    /// 日期选中改变
    /// - Parameter date: 勾选日期
    func dateChanged(_ date: Date, _ sender: UDDateCalendarPickerView)

    /// 取消选中
    func deselectDate(_ sender: UDDateCalendarPickerView)
}

extension UDDatePickerViewDelegate {
    /// customize CalendarCell，默认无操作
    public func customizeCalendarCell(_ calendarCell: UDCalendarPickerCell,
                                      cellForItemAt date: Date,
                                      cellState: CellState) -> UDCalendarPickerCell {
        return calendarCell
    }
    /// 传出当前停留页信息，默认无操作
    public func calendarScrolledTo(_ date: Date, _ sender: UDDateCalendarPickerView) { }

    public func deselectDate(_ sender: UDDateCalendarPickerView) { }
}

public final class UDDateCalendarPickerView: UIView {
    var calendarModel: DateCalendarContentModel
    var calendarPicker: UDCalendarPickerView
    let calendarStyle: UDCalendarStyleConfig
    let throttler = Throttler(delay: 0.2)

    public weak var delegate: UDDatePickerViewDelegate?

    /// UDDateCalendarPickerView init
    /// - Parameters:
    ///   - date: 初始化时间，默认 Date(), nil为不默认选中
    ///   - timeZone: 时区，默认 .current
    ///   - calendarConfig: 月历相关配置，有默认配置
    public init(date: Date? = Date(),
                timeZone: TimeZone = .current,
                calendarConfig: UDCalendarStyleConfig = UDCalendarStyleConfig()) {
        calendarModel = DateCalendarContentModel(selectedDate: date,
                                                 timeZone: timeZone,
                                                 firstWeekday: calendarConfig.firstWeekday)
        calendarPicker = UDCalendarPickerView(firstWeekday: calendarConfig.firstWeekday,
                                              dayCellClass: calendarConfig.dayCellClass,
                                              dayCellHeight: calendarConfig.dayCellHeight)
        calendarStyle = calendarConfig
        super.init(frame: .zero)
        calendarPicker.delegate = self
        calendarPicker.dataSource = self
        addSubview(calendarPicker)
        calendarPicker.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        let defaultSelectedDay = calendarModel.selectedDay ?? calendarModel.today
        let initYMD = JulianDayUtil.yearMonthDay(from: defaultSelectedDay)
        let calendarIndex: CalendarIndex
        if case .singleRow = calendarModel.monthCalendarMode {
            calendarIndex = (defaultSelectedDay - calendarModel.offset) / 7
        } else {
            calendarIndex = initYMD.year * 12 + initYMD.month - 1
        }
        calendarPicker.scroll(to: calendarIndex)
        refresh(titleView: calendarPicker.weekdayTitle, with: calendarIndex)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 选中对应 Date
    /// - Parameters:
    ///   - date: 要勾选的 date，默认 Date(), nil 为取消选中
    ///   - withAnimate: 是否需要翻页动画，默认 true
    public func select(date: Date? = Date(), withAnimate: Bool = true) {
        let pagingDate = date ?? Date()
        let julianday = JulianDayUtil.julianDay(from: pagingDate, in: calendarModel.timeZone)
        let (year, month, _) = JulianDayUtil.yearMonthDay(from: julianday)
        let calendarIndex: CalendarIndex
        switch calendarModel.monthCalendarMode {
        case .multipleRows:
            calendarIndex = year * 12 + month - 1
        case .singleRow:
            calendarIndex = (julianday - calendarModel.offset) / 7
        }
        calendarModel.selectedDay = date == nil ? nil : julianday
        calendarPicker.scroll(to: calendarIndex, animate: withAnimate)
        refresh(titleView: calendarPicker.weekdayTitle, with: calendarIndex)
        if date == nil {
            delegate?.deselectDate(self)
        } else {
            delegate?.dateChanged(JulianDayUtil.date(from: julianday, in: calendarModel.timeZone), self)
        }
        delegate?.calendarScrolledTo(JulianDayUtil.date(from: julianday, in: calendarModel.timeZone), self)
    }

    /// 翻到上一页
    /// - Parameter withAnimate: 是否需要翻页动画，默认 false
    public func scrollToPrev(withAnimate: Bool = false) {
        guard let calendarIndex = calendarPicker.calendarIndex else {
            assertionFailure("未取到 calendarIndex")
            return
        }
        let prevCalendarIndex = calendarIndex - 1
        var preSelected = preSelectedDay(in: prevCalendarIndex)
        if calendarStyle.autoSelectedDate {
            select(date: JulianDayUtil.date(from: preSelected, in: calendarModel.timeZone))
        } else {
            throttler.call { [weak self] in
                guard let self = self else { return }
                self.calendarPicker.scrollToPre(withAnimate: withAnimate)
                self.refresh(titleView: self.calendarPicker.weekdayTitle, with: prevCalendarIndex)
                self.delegate?.calendarScrolledTo(JulianDayUtil.date(from: preSelected, in: self.calendarModel.timeZone), self)
            }
        }
    }

    /// 翻到下一页
    /// - Parameter withAnimate: 是否需要翻页动画，默认 false
    public func scrollToNext(withAnimate: Bool = false) {
        guard let calendarIndex = calendarPicker.calendarIndex else {
            assertionFailure("未取到 calendarIndex")
            return
        }
        let nextCalendarIndex = calendarIndex + 1
        let preSelected = preSelectedDay(in: nextCalendarIndex)
        if calendarStyle.autoSelectedDate {
            select(date: JulianDayUtil.date(from: preSelected))
        } else {
            throttler.call { [weak self] in
                guard let self = self else { return }
                self.calendarPicker.scrollToNext(withAnimate: withAnimate)
                self.refresh(titleView: self.calendarPicker.weekdayTitle, with: nextCalendarIndex)
                self.delegate?.calendarScrolledTo(JulianDayUtil.date(from: preSelected), self)
            }
        }
    }

    /// 切换单行多行，即月历态和周状态（仅支持 autoSelectedDate == true）
    public func switchCalendarMode() {
        let isSingle = calendarModel.monthCalendarMode == .singleRow
        calendarModel.monthCalendarMode = isSingle ? .multipleRows : .singleRow
        calendarModel.data.removeAll()
        let selectedDate = JulianDayUtil.date(from: calendarModel.selectedDay ?? calendarModel.today)
        select(date: selectedDate, withAnimate: false)
        calendarPicker.reload()
    }

    private func julianDayRange(inSameMonthPage refJulianDay: JulianDay,
                                with firstWeekday: EKWeekday = .sunday) -> JulianDayRange {
        let refYearMonthDay = JulianDayUtil.yearMonthDay(from: refJulianDay)
        let julianDayOne = refJulianDay - refYearMonthDay.day + 1
        var julianDayLast: JulianDay {
            for monthDays in [31, 30, 29, 28] {
                let calculatedMonth = JulianDayUtil.yearMonthDay(from: julianDayOne + monthDays - 1).month
                let isSameMonth = calculatedMonth == refYearMonthDay.month
                if isSameMonth {
                    return julianDayOne + monthDays - 1
                }
            }
            return 0
        }
        guard let start = JulianDayUtil.julianDayRange(inSameWeekAs: julianDayOne, with: firstWeekday).first,
              let end = JulianDayUtil.julianDayRange(inSameWeekAs: julianDayLast, with: firstWeekday).last else {
            return refJulianDay..<refJulianDay + 28
        }
        return start..<end + 1
    }

    private func refresh(titleView: CalendarWeekTitleView, with calendarIndex: CalendarIndex) {
        switch calendarModel.monthCalendarMode {
        case .singleRow:
            // 加5是因为 base 为 1600/01/01，对应 julianday % 7 == 5，这里逆运算补齐
            let anchorJulianday = calendarIndex * 7 + 5
            let weekRange = JulianDayUtil.julianDayRange(inSameWeekAs: anchorJulianday,
                                                         with: calendarModel.firstWeekday)
            let isCurrentWeek = weekRange.contains(calendarModel.today)
            let todayWeekday = JulianDayUtil.weekday(from: calendarModel.today)
            titleView.refreshHighlightedLabel(todayWeekday: todayWeekday, isHighlight: isCurrentWeek)
        case .multipleRows:
            let (year, month, _) = JulianDayUtil.yearMonthDay(from: calendarModel.today)
            let isCurrentMonth = year * 12 + month - 1 == calendarIndex
            let todayWeekday = JulianDayUtil.weekday(from: calendarModel.today)
            titleView.refreshHighlightedLabel(todayWeekday: todayWeekday, isHighlight: isCurrentMonth)
        }
    }

    private func preSelectedDay(in calendarIndex: CalendarIndex) -> JulianDay {
        switch calendarModel.monthCalendarMode {
        case .singleRow:
            let selectedDay = calendarModel.selectedDay ?? calendarModel.today
            let selectedCalendarIndex = (selectedDay - calendarModel.offset) / 7
            return selectedDay - (selectedCalendarIndex - calendarIndex) * 7
        case .multipleRows:
            return JulianDayUtil.julianDay(fromYear: calendarIndex / 12,
                                           month: calendarIndex % 12 + 1,
                                           day: 1)
        }
    }

    private func configCalendarCell(_ calendarCell: UDCalendarPickerCell,
                                    cellForItemAt date: Date,
                                    cellState: CellState) -> UDCalendarPickerCell {
        calendarCell.dayLabelText = cellState.text
        calendarCell.type = cellState.dateBelongsTo
        let isToday = calendarModel.calendar.isDateInToday(date)
        if cellState.isSelected {
            if isToday {
                calendarCell.setupSelectedBgView(withColor: UDDatePickerTheme.calendarPickerTodaySelectedBgColor)
                calendarCell.setupDayLabel(withColor: UDDatePickerTheme.calendarPickerTodaySelectedTextColor)
            } else {
                calendarCell.setupSelectedBgView(withColor: UDDatePickerTheme.calendarPickerCurrentMonthBgColor)
            }
        } else {
            if isToday {
                calendarCell.setupDayLabel(withColor: UDDatePickerTheme.calendarPickerTodayTextColor)
            }
        }
        guard let customCell = delegate?.customizeCalendarCell(calendarCell,
                                                               cellForItemAt: date,
                                                               cellState: cellState) else {
            assertionFailure("delegate 为空")
            return calendarCell
        }
        return customCell
    }
}

// MARK: UDCalendarPickerViewDataSource
extension UDDateCalendarPickerView: UDCalendarPickerViewDataSource {
    func calendar(_ calendar: UDCalendarPickerView, cellForItemAt index: CalendarIndex,
                  indexPath: IndexPath, cell: UICollectionViewCell) -> UDCalendarPickerCell {
        let cellIndex: Int
        if case .singleRow = calendarModel.monthCalendarMode {
            cellIndex = indexPath.row
        } else {
            cellIndex = indexPath.section * 7 + indexPath.row
        }
        guard let dayCells = calendarModel.data[index], dayCells.count > cellIndex else {
            assertionFailure("未取到对应 page 的 cell 数据")
            return UDCalendarPickerCell()
        }
        var dayContent = dayCells[cellIndex]
        let date = JulianDayUtil.date(from: dayContent.julianDay, in: calendarModel.timeZone)
        if let selectedDay = calendarModel.selectedDay {
            dayContent.isSelected = dayContent.julianDay == selectedDay
        } else {
            dayContent.isSelected = false
        }
        guard let originCell = cell as? UDCalendarPickerCell else {
            assertionFailure("未取到对应 cell")
            return UDCalendarPickerCell()
        }
        return configCalendarCell(originCell, cellForItemAt: date,
                                  cellState: dayContent)
    }

    func calendar(_ calendar: UDCalendarPickerView, numberOfRowsInItem index: CalendarIndex) -> Int {
        switch calendarModel.monthCalendarMode {
        case .singleRow:
            return 1
        case .multipleRows:
            guard let dayNum = calendarModel.data[index]?.count else {
                assertionFailure("error: 未取到对应 pageIndex 的数据")
                return 6
            }
            return calendarStyle.rowNumFixed ? 6 : dayNum / 7
        }
    }

    func configureIsSingleLine(_ calendar: UDCalendarPickerView) -> Bool {
        return calendarModel.monthCalendarMode == .singleRow
    }
}

// MARK: UDCalendarPickerViewDelegate
extension UDDateCalendarPickerView: UDCalendarPickerViewDelegate {
    // 出现页面方式
    // 1、勾选任意天
    // 2、勾选下个月某一天，跳转
    // 3、翻页
    func calendar(_ calendar: UDCalendarPickerView, willLoad calendarItem: UIView, at index: CalendarIndex) {
        // 无缓存
        if calendarModel.data[index] == nil {
            switch calendarModel.monthCalendarMode {
            case .singleRow:
                // 加5是因为 base 为 1600/01/01，对应 julianday % 7 == 5，这里逆运算补齐
                let anchorJulianday = 7 * index + 5
                let dayRange = JulianDayUtil.julianDayRange(inSameWeekAs: anchorJulianday,
                                                            with: calendarModel.firstWeekday)

                let daysContent: [DayContent] = dayRange.map {
                    let text = String(JulianDayUtil.yearMonthDay(from: $0).day)
                    return DayContent(julianDay: $0, owner: .currentPage, text: text)
                }
                calendarModel.data[index] = daysContent
            case .multipleRows:
                let year = index / 12
                let month = index % 12 + 1
                let firstDayOfMonth = JulianDayUtil.julianDay(fromYear: year, month: month, day: 1)
                let dayRange: JulianDayRange
                if calendarStyle.rowNumFixed {
                    let firstWeek = JulianDayUtil.julianDayRange(inSameWeekAs: firstDayOfMonth,
                                                                 with: calendarModel.firstWeekday)
                    guard let pageFirstDay = firstWeek.first else {
                        assertionFailure("当页第一天未取到")
                        return
                    }
                    dayRange = pageFirstDay..<pageFirstDay + 6 * 7
                } else {
                    dayRange = julianDayRange(inSameMonthPage: firstDayOfMonth, with: calendarModel.firstWeekday)
                }

                let daysContent: [DayContent] = dayRange.map {
                    let currentMonth = JulianDayUtil.yearMonthDay(from: $0).month
                    var dayType: DateOwner
                    if currentMonth + 1 == month {
                        dayType = .previousPage
                    } else if currentMonth == month {
                        dayType = .currentPage
                    } else {
                        dayType = .nextPage
                    }
                    let text = String(JulianDayUtil.yearMonthDay(from: $0).day)
                    return DayContent(julianDay: $0, owner: dayType, text: text)
                }
                calendarModel.data[index] = daysContent
            }
        }
    }

    func calendar(_ calendar: UDCalendarPickerView, didUnload calendarItem: UIView, at index: CalendarIndex) {
        if calendarModel.data.count > 6 {
            calendarModel.data[index] = nil
        }
    }

    // 翻页滚动停止，仅翻页会走到这里
    func calendar(_ calendar: UDCalendarPickerView, beginFixingIndex index: CalendarIndex) {
        let preSelected = preSelectedDay(in: index)
        let preSelectedDate = JulianDayUtil.date(from: preSelected)
        let selectedDay = calendarModel.selectedDay ?? calendarModel.today
        switch calendarModel.monthCalendarMode {
        case .singleRow:
            let indexChanged = (selectedDay - calendarModel.offset) / 7 != index
            if  calendarStyle.autoSelectedDate && indexChanged {
                calendarModel.selectedDay = preSelected
                delegate?.dateChanged(preSelectedDate, self)
            }
        case .multipleRows:
            let (selectedYear, selectedMonth, _) = JulianDayUtil.yearMonthDay(from: selectedDay)
            let indexChanged = (selectedYear * 12 + selectedMonth - 1) != index
            if calendarStyle.autoSelectedDate && indexChanged {
                calendarModel.selectedDay = preSelected
                delegate?.dateChanged(preSelectedDate, self)
            }
        }
        refresh(titleView: calendar.weekdayTitle, with: index)
        delegate?.calendarScrolledTo(preSelectedDate, self)
    }

    func calendar(_ calendar: UDCalendarPickerView, didSelect cell: UDCalendarPickerCell,
                  index: CalendarIndex, indexPath: IndexPath) {
        switch calendarModel.monthCalendarMode {
        case .singleRow:
            guard let dayCells = calendarModel.data[index], dayCells.count > indexPath.row else {
                assertionFailure("select 未取到对应 page 的 cell 数据")
                return
            }
            let cellDay = dayCells[indexPath.row]
            calendarModel.selectedDay = cellDay.julianDay
            delegate?.dateChanged(JulianDayUtil.date(from: cellDay.julianDay), self)
        case .multipleRows:
            // 数据层面
            let cellIndex = indexPath.section * 7 + indexPath.row
            guard let dayCells = calendarModel.data[index], dayCells.count > cellIndex, cellIndex > -1 else {
                assertionFailure("select 未取到对应 page 的 cell 数据")
                return
            }
            let cellDay = dayCells[cellIndex]
            switch cellDay.dateBelongsTo {
            case .previousPage:
                select(date: JulianDayUtil.date(from: cellDay.julianDay, in: calendarModel.timeZone))
            case .currentPage:
                calendarModel.selectedDay = cellDay.julianDay
                delegate?.dateChanged(JulianDayUtil.date(from: cellDay.julianDay, in: calendarModel.timeZone), self)
            case .nextPage:
                select(date: JulianDayUtil.date(from: cellDay.julianDay, in: calendarModel.timeZone))
            }
        }
    }
}
