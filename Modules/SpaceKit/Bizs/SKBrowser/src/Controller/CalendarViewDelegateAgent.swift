//
//  CalendarViewDelegateAgent.swift
//  SpaceKit
//
//  Created by nine on 2019/3/20.
//  Copyright © 2019 nine. All rights reserved.
//

import Foundation
import UIKit
import JTAppleCalendar
import SKCommon
import SKResource
import UniverseDesignColor

struct TodayCellInfo {
    var date: Date
    var cell: MonthViewCell
}

class CalendarViewDelegateAgent {
    weak var calendarView: JTAppleCalendarView?
    weak var context: ReminderContext?

    var statisticsCallBack: ((String) -> Void)?
    var callBack: ((_ selectedDate: Date, _ isManual: Bool) -> Void)?

    private var cellInfo: TodayCellInfo?
    private var selectedTime: Date?

    lazy var monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = BundleI18n.SKResource.Doc_Reminder_DateFormat
        return formatter
    }()

    lazy var dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()

    lazy var secondFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm:ss"
        return formatter
    }()
    
    private enum Const {
        static let dateYear = 9999
        static let dateMonth = 12
        static let dateDay = 31
        static let dateHour = 23
        static let dateMinute = 59
        static let dateSecond = 59
        static let dateAddingStartValue = -20
        static let dateAddingEndValue = 20
        static let startDateTime = 0
    }

    init(_ calendarView: JTAppleCalendarView, context: ReminderContext) {
        self.calendarView = calendarView
        self.context = context
        self.selectedTime = Date(timeIntervalSince1970: context.expireTime)
    }

}

extension CalendarViewDelegateAgent: JTAppleCalendarViewDataSource {
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        let currentCalendar = Calendar.current
        var startDate = currentCalendar.date(byAdding: .year, value: Const.dateAddingStartValue, to: Date())!
        var endDate = currentCalendar.date(byAdding: .year, value: Const.dateAddingEndValue, to: Date())!
        if let selectedTime = selectedTime {
            startDate = currentCalendar.date(byAdding: .year, value: Const.dateAddingStartValue, to: selectedTime)!
            endDate = currentCalendar.date(byAdding: .year, value: Const.dateAddingEndValue, to: selectedTime)!
            startDate = max(startDate, Date(timeIntervalSince1970: 0))
            endDate = min(endDate, Date(year: Const.dateYear, month: Const.dateMonth, day: Const.dateDay, hour: Const.dateHour, minute: Const.dateMinute, second: Const.dateSecond))
        }

        return ConfigurationParameters(startDate: startDate,
                                       endDate: endDate,
                                       calendar: Calendar.current)
    }
}

extension CalendarViewDelegateAgent: JTAppleCalendarViewDelegate {
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        handleCellConfiguration(cell: cell, cellState: cellState)
    }

    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        guard let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "MonthViewCell", for: indexPath) as? MonthViewCell else {
            return JTAppleCell()
        }
        cell.setContent(text: cellState.text)
        handleCellConfiguration(cell: cell, cellState: cellState)
        return cell
    }

    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        if let currentMonthData = visibleDates.monthDates.first?.0 {
            statisticsCallBack?("select_month")
            context?.dateLabel.text = monthFormatter.string(from: currentMonthData)
        }
    }

    // 选中回调
    func calendar(_ calendar: JTAppleCalendarView,
                  didSelectDate date: Date,
                  cell: JTAppleCell?,
                  cellState: CellState) {
        callBack?(cellState.date, cellState.selectionType == .userInitiated)
        handleCellConfiguration(cell: cell, cellState: cellState)
        if cellState.dateBelongsTo != .thisMonth {
            calendarView?.scrollToDate(cellState.date)
        }
    }

    // 取消选中
    func calendar(_ calendar: JTAppleCalendarView,
                  didDeselectDate date: Date,
                  cell: JTAppleCell?,
                  cellState: CellState) {
        handleCell(cellState.cell(), cellState: cellState, isSelected: false)
    }
}

private extension CalendarViewDelegateAgent {
    private func handleCellConfiguration(cell: JTAppleCell?, cellState: CellState) {
        handleCellTextColor(view: cell, cellState: cellState)
    }

    private func handleCellTextColor(view: JTAppleCell?, cellState: CellState) {
        handleCell(view, cellState: cellState, isSelected: nil)
    }

    private func handleCell(_ cell: JTAppleCell?, cellState: CellState, isSelected: Bool?) {
        guard let myCustomCell = cell as? MonthViewCell, let context = context  else { return }
        let isSelected = isSelected ?? cellState.isSelected

        // 这个方法会调用2次，第一次为被取消的cell，第二次会选中的cell
        // 被选中的cell
        if isSelected {
            if let hour = selectedTime?.sk.hour, let min = selectedTime?.sk.minute {
                let newDay = cellState.date.sk.day
                let newMonth = cellState.date.sk.month
                let newYear = cellState.date.sk.year
                // 替换为选中的那天
                selectedTime = secondFormatter.date(from: "\(newYear)-\(newMonth)-\(newDay) \(hour):\(min):00")
            }
            // 是今天，保存cell动态改颜色
            if dayFormatter.string(from: cellState.date) == dayFormatter.string(from: Date()) {
                cellInfo = TodayCellInfo(date: cellState.date, cell: myCustomCell)
            }
            configSelectedCell(myCustomCell, cellState: cellState)
        } else {
            // 置为空，防止非今天也去设置颜色，非今天都用之前的逻辑
            cellInfo = nil
            myCustomCell.setSelectViewColor(color: .clear)
            // 处理是否选择的是这个月
            if cellState.dateBelongsTo == .thisMonth {
                myCustomCell.setDayLabelColor(color: context.config.titleColor.currentMonth)
            } else {
                myCustomCell.setDayLabelColor(color: context.config.titleColor.otherMonth)
            }
            // 今天的日期cell
            if dayFormatter.string(from: cellState.date) == dayFormatter.string(from: Date()) {
                myCustomCell.setDayLabelColor(color: context.config.titleColor.isSeleted)
                myCustomCell.setSelectViewColor(color: context.config.selectColor.today)
            }
        }
    }

    private func configSelectedCell(_ cell: MonthViewCell, cellState: CellState) {
        guard let context = context  else { return }
        cell.setDayLabelColor(color: context.config.titleColor.isSeleted)
        let now = Date()
        let time = selectedTime ?? cellState.date
        if let currentDate = secondFormatter.date(from: "\(now.sk.year)-\(now.sk.month)-\(now.sk.day) \(now.sk.hour):\(now.sk.minute):\(now.sk.second)") {
            let days = time.timeIntervalSince(currentDate) / (3600 * 24)
            if days >= 7 {
                cell.setSelectViewColor(color: context.config.selectColor.lasterDay)
            } else if days < 7 && days >= 0 {
                cell.setSelectViewColor(color: context.config.selectColor.rencent6Day)
            } else {
                cell.setSelectViewColor(color: context.config.selectColor.pastDay)
            }
        }
        setColor()
    }

    private func setColor() {
        guard let info = cellInfo, let time = selectedTime, let context = context else { return }

        switch time.compare(Date()) {
        case .orderedDescending:
            info.cell.setSelectViewColor(color: context.config.selectColor.rencent6Day)
        case .orderedSame:
            break
        case .orderedAscending:
            info.cell.setSelectViewColor(color: context.config.selectColor.pastDay)
        }
    }
}

extension CalendarViewDelegateAgent: ReminderViewControllerDelegate {
    func reminderViewControllerDidSelectedTime(time: Date) {
        // fix: 选中回调的日期不对，但是时分是对的
        if let year = selectedTime?.sk.year, let month = selectedTime?.sk.month, let day = selectedTime?.sk.day {
            selectedTime = time
            selectedTime = secondFormatter.date(from: "\(year)-\(month)-\(day) \(time.sk.hour):\(time.sk.minute):00")
        }
        setColor()
        if let selectedTime {
            calendarView?.reloadDates([selectedTime])
        }
    }
}
