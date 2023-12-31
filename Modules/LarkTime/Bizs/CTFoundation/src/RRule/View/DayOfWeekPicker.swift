//
//  DayOfWeekPicker.swift
//  Calendar
//
//  Created by zhuchao on 2018/3/23.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import EventKit
import LarkDatePickerView
import LarkTimeFormatUtils

protocol DayOfWeekPickerDelegate: AnyObject {
    func dayOfWeekPicker(_ picker: DayOfWeekPicker, didSelectDayOfWeek dayOfWeek: EKRecurrenceDayOfWeek)
}

final class DayOfWeekPicker: PickerView {

    private var defaultWeekNumber: Int = 2
    private var defaultWeekday: Int = 2

    private var maxWeekNumber: Int = 4
    private var maxDaysNumber: Int = 7

    weak var delegate: DayOfWeekPickerDelegate?

    init(frame: CGRect, weekOfMonth: Int = 2, maxWeekOfMonth: Int = 4, weekday: Int = 2) {
        defaultWeekNumber = weekOfMonth
        maxWeekNumber = maxWeekOfMonth
        defaultWeekday = weekday
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func scrollViewFrame(index: Int) -> CGRect {
        assertLog(self.bounds.width > 0 && self.bounds.height > 0)
        let minutesLeftWheelWidth: CGFloat = 10
        let minutesMiddleWheelWidth: CGFloat = self.bounds.width / 2.0
        let minutesRightWheelWidth: CGFloat = self.bounds.width / 2.0

        switch index {
        case 1:
            return CGRect(x: 0, y: 0, width: minutesLeftWheelWidth, height: self.bounds.height)
        case 2:
            return CGRect(x: minutesLeftWheelWidth, y: 0, width: minutesMiddleWheelWidth, height: self.bounds.height)
        case 3:
            return CGRect(x: minutesLeftWheelWidth + minutesMiddleWheelWidth, y: 0, width: minutesRightWheelWidth, height: self.bounds.height)
        default:
            assertionFailureLog()
            return .zero
        }
    }

    // MARK: scroll view delegate
    override func infiniteScrollView(scrollView: InfiniteScrollView, willDisplay view: UIView, at index: Int) {
        guard let cell = view as? DatePickerCell else {
            return
        }
        let offSet = index
        switch scrollView {
        case firstScrollView:
            break
        case secondScrollView:
            let number = self.recycledNumber(withBenchmark: self.defaultWeekNumber, offSet: offSet, modNumber: maxWeekNumber)
            cell.label.text = self.rankString(rankNumber: number)
        case thirdScrollView:
            let number = self.recycledNumber(withBenchmark: self.defaultWeekday, offSet: offSet, modNumber: maxDaysNumber)
            cell.label.text = TimeFormatUtils.weekdayFullString(weekday: number)
        default:
            assertionFailureLog()
        }
    }

    override func scrollEndScroll(scrollView: InfiniteScrollView) {
        super.scrollEndScroll(scrollView: scrollView)
        self.delegate?.dayOfWeekPicker(self, didSelectDayOfWeek: self.currentWeekDay)
    }

    // MARK: methods
    private func selectedWeekNumber() -> Int {
        guard let centerCell = self.centerCell(of: secondScrollView) else {
            return self.defaultWeekNumber
        }
        return self.recycledNumber(withBenchmark: self.defaultWeekNumber, offSet: centerCell.tag, modNumber: self.maxWeekNumber)
    }

    private func selectedWeekday() -> Int {
        guard let centerCell = self.centerCell(of: thirdScrollView) else {
            return self.defaultWeekday
        }
        return self.recycledNumber(withBenchmark: self.defaultWeekday,
                                         offSet: centerCell.tag,
                                         modNumber: self.maxDaysNumber)
    }

    var currentWeekDay: EKRecurrenceDayOfWeek {
        return EKRecurrenceDayOfWeek(EKWeekday(rawValue: self.selectedWeekday())!, weekNumber: self.selectedWeekNumber())
    }

    private func rankString(rankNumber: Int) -> String {
        switch rankNumber {
        case 1:
            return BundleI18n.RRule.Calendar_RRule_First
        case 2:
            return BundleI18n.RRule.Calendar_RRule_Second
        case 3:
            return BundleI18n.RRule.Calendar_RRule_Third
        case 4:
            return BundleI18n.RRule.Calendar_RRule_Fourth
        case 5:
            return BundleI18n.RRule.Calendar_RRule_Fifth
        default:
            assertionFailureLog()
            return ""
        }
    }
}
