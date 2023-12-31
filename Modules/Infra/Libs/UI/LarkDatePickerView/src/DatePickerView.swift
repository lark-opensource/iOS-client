//
//  DatePickerView.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/22.
//  Copyright © 2017年 EE. All rights reserved.
//

import Foundation
import UIKit
import CalendarFoundation
import LarkTimeFormatUtils

public protocol DatePickerViewDelegate: AnyObject {
    func datePicker(_ picker: DatePickerView, didSelectDate date: Date)
}

public final class DatePickerView: PickerView {

    private var benchmarkYear: Int!
    private var benchmarkMonth: Int!
    private var benchmarkDay: Int!
    private var numberOfDays: Int!
    private var weekdayComponents = DateComponents()

    public weak var delegate: DatePickerViewDelegate?
    public init(frame: CGRect, selectedDate: Date) {
        self.benchmarkYear = selectedDate.year
        self.benchmarkMonth = selectedDate.month
        self.benchmarkDay = selectedDate.day
        self.numberOfDays = DatePickerView.numberOfDays(year: self.benchmarkYear, month: self.benchmarkMonth)
        self.weekdayComponents.year = self.benchmarkYear
        self.weekdayComponents.month = self.benchmarkMonth
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setDate(_ date: Date) {
        self.parseValues(withDate: date)
        self.resetScrollViews()
    }

    public func parseValues(withDate date: Date) {
        self.benchmarkYear = date.year
        self.benchmarkMonth = date.month
        self.benchmarkDay = date.day
        self.numberOfDays = DatePickerView.numberOfDays(year: self.benchmarkYear, month: self.benchmarkMonth)
        self.weekdayComponents.year = self.benchmarkYear
        self.weekdayComponents.month = self.benchmarkMonth
    }

    public override func scrollViewFrame(index: Int) -> CGRect {
        assertLog(self.bounds.width > 0 && self.bounds.height > 0)
        let dayLeftWheelWidth: CGFloat = (63.0 + 80.0) / 375.0 * self.bounds.width
        let dayMiddleWheelWidth: CGFloat = (36.0 + 30.0) / 375.0 * self.bounds.width
        let dayRightWheelWidth: CGFloat = self.bounds.width - dayLeftWheelWidth - dayMiddleWheelWidth
        switch index {
        case 1:
            return CGRect(x: 0, y: 0, width: dayLeftWheelWidth, height: self.bounds.height)
        case 2:
            return CGRect(x: dayLeftWheelWidth, y: 0, width: dayMiddleWheelWidth, height: self.bounds.height)
        case 3:
            return CGRect(x: dayLeftWheelWidth + dayMiddleWheelWidth, y: 0, width: dayRightWheelWidth, height: self.bounds.height)
        default:
            assertionFailureLog()
            return .zero
        }
    }

    // MARK: scroll view delegate
    lazy var monthFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: TimeFormatUtils.languageIdentifier)
        return formatter
    }()

    override public func infiniteScrollView(scrollView: InfiniteScrollView, willDisplay view: UIView, at index: Int) {
        guard let cell = view as? DatePickerCell else {
            return
        }
        let offSet = index
        switch scrollView {
        case firstScrollView:
            let year = self.year(withBenchmarkYear: self.benchmarkYear, offSet: offSet)
            cell.label.text = year >= 0 ? BundleI18n.LarkDatePickerView.Calendar_StandardTime_YearOnlyString(year) : "- -"
        case secondScrollView:
            let month = self.month(withBenchmarkMonth: self.benchmarkMonth, offSet: offSet)
            let labelText = monthFormatter.shortMonthSymbols[month - 1]
            cell.label.text = labelText
        case thirdScrollView:
            let day = self.day(withBenchmarkDay: self.benchmarkDay, offSet: offSet, numberOfDays: self.numberOfDays)
            self.weekdayComponents.day = day
            let date = self.getDate(components: self.weekdayComponents)
            // 时区默认当前设备时区 - 获取当前星期缩写
            let coustomOptions = Options(timeFormatType: .short)
            let weekdayString = TimeFormatUtils.formatWeekday(from: date, with: coustomOptions)
            cell.label.text = "\(BundleI18n.LarkDatePickerView.Calendar_StandardTime_DayOnlyString(day)) (\(weekdayString))"
        default:
            assertionFailureLog()
        }
    }

    public override func scrollEndScroll(scrollView: InfiniteScrollView) {
        super.scrollEndScroll(scrollView: scrollView)
        if scrollView !== thirdScrollView {
            self.updateWeekDayComponent(year: self.selectedYear(), month: self.selectedMonth())
            self.updateNumberOfDays()
            thirdScrollView.reloadData()
        }
        self.delegate?.datePicker(self, didSelectDate: self.generateSelectedDate())
    }

    // MARK: methods
    public func currentSelectedDate() -> Date {
        return self.generateSelectedDate()
    }

    private func updateNumberOfDays() {
        let newNumberOfDays = self.currentNumberOfDays()
        if newNumberOfDays != self.numberOfDays {
            var selectedDay = self.selectedDay()
            if selectedDay > newNumberOfDays {
                selectedDay = newNumberOfDays
            }
            self.numberOfDays = newNumberOfDays
            self.refreshDaysView(numberOfDays: newNumberOfDays, selectedDay: selectedDay)
        }
    }

    private func refreshDaysView(numberOfDays: Int, selectedDay: Int) {
        guard let centerCell = self.centerCell(of: thirdScrollView) else {
            assertionFailureLog()
            return
        }
        var newStartDay = 0
        for i in 1...numberOfDays where self.day(withBenchmarkDay: i, offSet: centerCell.tag, numberOfDays: numberOfDays) == selectedDay {
            newStartDay = i
        }
        assertLog(newStartDay > 0)
        self.benchmarkDay = newStartDay
    }

    private func generateSelectedDate() -> Date {
        let now = Date()
        if let selectedDate = now.changed(year: self.selectedYear(), month: self.selectedMonth(), day: self.selectedDay()) {
            return selectedDate
        }
        assertionFailureLog()
        return now
    }

    private func selectedYear() -> Int {
        guard let centerCell = self.centerCell(of: firstScrollView) else {
            assertionFailureLog()
            return Date().year
        }
        return self.year(withBenchmarkYear: self.benchmarkYear, offSet: centerCell.tag)
    }

    private func selectedMonth() -> Int {
        guard let centerCell = self.centerCell(of: secondScrollView) else {
            assertionFailureLog()
            return Date().month
        }
        return self.month(withBenchmarkMonth: self.benchmarkMonth, offSet: centerCell.tag)
    }

    private func selectedDay() -> Int {
        guard let centerCell = self.centerCell(of: thirdScrollView) else {
            assertionFailureLog()
            return Date().day
        }
        return self.day(withBenchmarkDay: self.benchmarkDay, offSet: centerCell.tag, numberOfDays: self.numberOfDays)
    }

    private func currentNumberOfDays() -> Int {
        return DatePickerView.numberOfDays(year: self.selectedYear(), month: self.selectedMonth())
    }

    private func updateWeekDayComponent(year: Int, month: Int) {
        self.weekdayComponents.year = year
        self.weekdayComponents.month = month
    }

    // MARK: helper
    private static func numberOfDays(year: Int, month: Int) -> Int {
        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.gregorianCalendar
        let date = calendar.date(from: dateComponents)!
        let range = calendar.range(of: .day, in: .month, for: date)!
        return range.count
    }

    private func year(withBenchmarkYear year: Int, offSet: Int) -> Int {
        return year + offSet
    }

    private func month(withBenchmarkMonth month: Int, offSet: Int) -> Int {
        var month = (month + offSet) % 12
        if month < 0 { month += 12 }
        return month == 0 ? 12 : month
    }

    private func day(withBenchmarkDay day: Int, offSet: Int, numberOfDays: Int) -> Int {
        var day = (day + offSet) % numberOfDays
        if day < 0 { day += numberOfDays }
        return day == 0 ? numberOfDays : day
    }

    private func getDate(components: DateComponents) -> Date {
        if let date = Calendar.gregorianCalendar.date(from: components) {
            return date
        }
        assertionFailureLog()
        return Date()
    }

    lazy private var disableMask: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.7)
        view.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        return view
    }()

    public func showDisableMask(isShow: Bool) {
        self.topGradientView.isHidden = isShow
        self.bottomGradientView.isHidden = isShow
        if isShow {
            self.bringSubviewToFront(disableMask)
            disableMask.isHidden = false
        } else {
            disableMask.isHidden = true
        }
    }
}
