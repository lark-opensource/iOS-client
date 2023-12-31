//
//  MailDatePickerView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/2/23.
//

import Foundation
import UIKit
import LarkDatePickerView
import LarkTimeFormatUtils

protocol MailDatePickerViewDelegate: AnyObject {
    func datePicker(_ picker: MailDatePickerView, didSelectDate date: Date)
}

class MailDatePickerView: MailPickerView {

    private var benchmarkYear: Int
    private var benchmarkMonth: Int
    private var benchmarkDay: Int
    private var numberOfDays: Int
    private var weekdayComponents = DateComponents()

    weak var delegate: MailDatePickerViewDelegate?
    init(frame: CGRect, selectedDate: Date) {
        self.benchmarkYear = selectedDate.year
        self.benchmarkMonth = selectedDate.month
        self.benchmarkDay = selectedDate.day
        self.numberOfDays = MailDatePickerView.numberOfDays(year: self.benchmarkYear, month: self.benchmarkMonth)
        self.weekdayComponents.year = self.benchmarkYear
        self.weekdayComponents.month = self.benchmarkMonth
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setDate(_ date: Date) {
        self.parseValues(withDate: date)
        self.resetScrollViews()
    }

    func parseValues(withDate date: Date) {
        self.benchmarkYear = date.year
        self.benchmarkMonth = date.month
        self.benchmarkDay = date.day
        self.numberOfDays = MailDatePickerView.numberOfDays(year: self.benchmarkYear, month: self.benchmarkMonth)
        self.weekdayComponents.year = self.benchmarkYear
        self.weekdayComponents.month = self.benchmarkMonth
    }

    override func scrollViewFrame(index: Int) -> CGRect {
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
            return .zero
        }
    }

    // MARK: scroll view delegate
    lazy var monthFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.setCurrentLocale()
        return formatter
    }()

    override func infiniteScrollView(scrollView: InfiniteScrollView, willDisplay view: UIView, at index: Int) {
        guard let cell = view as? MailOOODatePickerCell else {
            return
        }
        /// 当前选中的时间
        let selectedDate = generateSelectedDate()
        /// willDisplay的时间，用来判断是否valid
        var compareInvalidDate = selectedDate
        /// willDisplay的和selected的offset
        let offSet = index
        switch scrollView {
        case firstScrollView:
            let year = self.year(withBenchmarkYear: self.benchmarkYear, offSet: offSet)
            cell.label.text = year >= 0 ? "\(year)\(BundleI18n.MailSDK.Mail_TimeFormat_YearOnlyChinese)" : "- -"
            compareInvalidDate = selectedDate.changed(year: year) ?? compareInvalidDate
        case secondScrollView:
            let month = self.month(withBenchmarkMonth: self.benchmarkMonth, offSet: offSet)
            cell.label.text = TimeFormatUtils.monthAbbrString(month: month)
            compareInvalidDate = selectedDate.changed(month: month) ?? compareInvalidDate
        case thirdScrollView:
            let day = self.day(withBenchmarkDay: self.benchmarkDay, offSet: offSet, numberOfDays: self.numberOfDays)
            self.weekdayComponents.day = day
            let weekDay = self.getWeekDay(withDate: self.getDate(components: self.weekdayComponents))
            cell.label.text = "\(day)\(BundleI18n.MailSDK.Mail_RRule_EnglishSpace)\(BundleI18n.MailSDK.Mail_RRule_Day2) \(weekDay)"
            compareInvalidDate = selectedDate.changed(day: day) ?? compareInvalidDate
        default:
            assertionFailure()
        }
        /// 小于今天的日期，置灰
        let currentDate = Date()
        let compareResult = Calendar.current.compare(compareInvalidDate, to: currentDate, toGranularity: .day)
        let isValid = compareResult != .orderedAscending
        cell.label.textColor = isValid ? normalTextColor : invalidTextColor
    }

    override func scrollEndScroll(scrollView: InfiniteScrollView) {
        super.scrollEndScroll(scrollView: scrollView)
        if scrollView !== thirdScrollView {
            self.updateWeekDayComponent(year: self.selectedYear(), month: self.selectedMonth())
            self.updateNumberOfDays()
        }
        self.delegate?.datePicker(self, didSelectDate: self.generateSelectedDate())
        [firstScrollView, secondScrollView, thirdScrollView].forEach({ $0.reloadData() })
    }

    // MARK: methods
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
            assertionFailure()
            return
        }
        var newStartDay = 0
        for i in 1...numberOfDays where self.day(withBenchmarkDay: i, offSet: centerCell.tag, numberOfDays: numberOfDays) == selectedDay {
            newStartDay = i
        }
        // assertLog(newStartDay > 0)
        self.benchmarkDay = newStartDay
    }

    private func generateSelectedDate() -> Date {
        let now = Date()
        if let selectedDate = now.changed(year: self.selectedYear())?.changed(month: self.selectedMonth())?.changed(day: self.selectedDay()) {
            return selectedDate
        }
        assertionFailure()
        return now
    }

    private func selectedYear() -> Int {
        let offSet = centerCell(of: firstScrollView)?.tag ?? 0
        return self.year(withBenchmarkYear: self.benchmarkYear, offSet: offSet)
    }

    private func selectedMonth() -> Int {
        let offSet = centerCell(of: secondScrollView)?.tag ?? 0
        return self.month(withBenchmarkMonth: self.benchmarkMonth, offSet: offSet)
    }

    private func selectedDay() -> Int {
        let offSet = centerCell(of: thirdScrollView)?.tag ?? 0
        return self.day(withBenchmarkDay: self.benchmarkDay, offSet: offSet, numberOfDays: self.numberOfDays)
    }

    private func currentNumberOfDays() -> Int {
        return MailDatePickerView.numberOfDays(year: self.selectedYear(), month: self.selectedMonth())
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
        assertionFailure()
        return Date()
    }

    private func getWeekDay(withDate date: Date) -> String {
        let weekDay = Calendar.gregorianCalendar.component(.weekday, from: date)
        switch weekDay {
        case 2:
            return BundleI18n.MailSDK.Mail_RRule_MondayAbbr
        case 3:
            return BundleI18n.MailSDK.Mail_RRule_TuesdayAbbr
        case 4:
            return BundleI18n.MailSDK.Mail_RRule_WednesdayAbbr
        case 5:
            return BundleI18n.MailSDK.Mail_TimeFormat_Thursday
        case 6:
            return BundleI18n.MailSDK.Mail_RRule_FridayAbbr
        case 7:
            return BundleI18n.MailSDK.Mail_RRule_SaturdayAbbr
        case 1:
            return BundleI18n.MailSDK.Mail_RRule_SundayAbbr
        default:
            assertionFailure()
            return BundleI18n.MailSDK.Mail_RRule_Weekday
        }
    }

    lazy private var disableMask: UIView = {
        let view = UIView()
        self.addSubview(view)
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.7)
        view.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        return view
    }()
}
