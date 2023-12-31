//
//  MailScheduleDatePickerView.swift
//  MailSDK
//
//  Created by majx on 2020/12/5.
//

import Foundation
import UIKit
import LarkDatePickerView
import LarkTimeFormatUtils
import LarkLocalizations

protocol MailMinutesDatePickerViewDelegate: AnyObject {
    func minutesDatePicker(_ picker: MailMinutesDatePickerView, didSelectDate date: Date)
    func calculateLocalDateWithTimeZone(_ sourceDate: Date) -> Date
}

class MailMinutesDatePickerView: MailPickerView {
    private var now: Date
    private var benchmarkHour: Int
    private var benchmarkMinutes: Int
    private static let minutesInterval: Int = 5
    private let is12HourStyle: Bool
    private var lastHour: Int   // 记录上一次滑动到的时间点
    private var lastHourChangeTag: Int = 0 // 记录上次切换小时的偏移量
    /// AM/PM 时间区分缩写统称为 Meridiem Indicator
    private let isMeridiemIndicatorAheadOfTime = TimeFormatUtils.languagesListForAheadMeridiemIndicator.contains(LanguageManager.currentLanguage)
    var symbolView: DateSymbolView?

    weak var delegate: MailMinutesDatePickerViewDelegate?

    init(frame: CGRect, selectedDate: Date) {
        self.now = selectedDate
        self.benchmarkHour = selectedDate.hour
        self.benchmarkMinutes = MailMinutesDatePickerView.getMultipleOfMinutesInterval(selectedDate.minute)
        self.is12HourStyle = !Date.lf.is24HourTime
        lastHour = benchmarkHour // 当前时间记录为lastHour的初始值
        super.init(frame: frame)
        if is12HourStyle {
            addDateSymbolPicker(isAm: selectedDate.isAM())
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func getMultipleOfMinutesInterval(_ minute: Int) -> Int {
        let minutesInterval = MailMinutesDatePickerView.minutesInterval
        if minute % minutesInterval != 0 {
            return (minute / minutesInterval) * minutesInterval
        }
        return minute
    }

    func setDate(_ date: Date) {
        self.now = date
        self.benchmarkHour = date.hour
        self.benchmarkMinutes = MailMinutesDatePickerView.getMultipleOfMinutesInterval(date.minute)
        self.resetScrollViews()
        self.symbolView?.setIsAm(date.isAM())
    }

    override func scrollViewFrame(index: Int) -> CGRect {
        // 24小时制 2:1:1
        // 12小时制 3:1:1:1
        switch index {
        case 1:
            return dayPickerFrame()
        case 2:
            return hourPickerFrame()
        case 3:
            return minutesPickerFrame()
        default:
            assertionFailure()
            return .zero
        }
    }

    private func dayPickerFrame() -> CGRect {
        return CGRect(origin: .zero, size: CGSize(width: self.bounds.width * 0.5, height: self.bounds.height))
    }

    private func hourPickerFrame() -> CGRect {
        if !is12HourStyle {
            let origin = CGPoint(x: self.bounds.width * 0.5, y: 0)
            let size = CGSize(width: self.bounds.width * 0.25, height: self.bounds.height)
            return CGRect(origin: origin, size: size)
        }

        let size = CGSize(width: self.bounds.width * (1.0 / 6.0), height: self.bounds.height)
        let origin = CGPoint(
            x: self.bounds.width * (isMeridiemIndicatorAheadOfTime ? 4.0 / 6.0 : 0.5),
            y: 0
        )
        return CGRect(origin: origin, size: size)
    }

    private func minutesPickerFrame() -> CGRect {
        let hourFrame = hourPickerFrame()
        let size: CGSize
        if is12HourStyle {
            size = CGSize(width: self.bounds.width * (1.0 / 6.0), height: self.bounds.height)
        } else {
            size = CGSize(width: self.bounds.width * (1.0 / 4.0), height: self.bounds.height)
        }
        let origin: CGPoint = CGPoint(x: hourFrame.origin.x + hourFrame.width, y: 0)
        return CGRect(origin: origin, size: size)
    }

    private func dateSymbolPickerFrame() -> CGRect {
        guard is12HourStyle else {
            assertionFailure()
            return .zero
        }
        let size = CGSize(width: self.bounds.width * (1.0 / 6.0), height: self.bounds.height)
        let origin = CGPoint(
            x: self.bounds.width * (isMeridiemIndicatorAheadOfTime ? 0.5 : 5.0 / 6.0),
            y: 0
        )
        return CGRect(origin: origin, size: size)
    }

    private func addDateSymbolPicker(isAm: Bool) {
        let symbolView = DateSymbolView(isAm: isAm, frame: dateSymbolPickerFrame())
        insertSubview(symbolView, at: 0)
        symbolView.selectedAction = { [weak self] (isAm: Bool) -> Void in
            guard let self = self else { return }
            let selectedDate = self.generateSelectedDate()
            self.delegate?.minutesDatePicker(self, didSelectDate: selectedDate)
        }
        symbolView.snp.makeConstraints({make in
            make.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(1.0 / 6.0)
            if isMeridiemIndicatorAheadOfTime {
                make.left.equalTo(self.snp.centerX)
            } else {
                make.right.equalToSuperview()
            }
        })

        self.symbolView = symbolView
    }

    // MARK: scroll view delegate
    override func infiniteScrollView(scrollView: InfiniteScrollView, willDisplay view: UIView, at index: Int) {
        guard let cell = view as? MailOOODatePickerCell else {
            return
        }
        let currentDate = Date()
        let offSet = index
        /// willDisplay的时间，用来判断是否valid
        var compareInvalidDate = now
        /// 当前选中的时间
        let selectedDate = generateSelectedDate()
        /// willDisplay的和selected的offset
        let selectedOffset = index - (centerCell(of: scrollView)?.tag ?? 0)
        switch scrollView {
        case firstScrollView:
            // 场景: 编辑页非全天日程选择
            // 使用设备当前时区
            // 当天有可选项，则该选项 enable
            compareInvalidDate = (selectedDate.changed(hour: 23, minute: 59) ?? selectedDate) + DateComponents(day: selectedOffset) ?? Date()
            let customOptions = Options(
                timeFormatType: .short,
                datePrecisionType: .day
            )
            cell.label.text = TimeFormatUtils.formatDate(from: compareInvalidDate, with: customOptions) + " " + TimeFormatUtils.formatWeekday(from: compareInvalidDate, with: customOptions)
        case secondScrollView:
            let hour = self.hour(withBenchmark: self.benchmarkHour, offSet: offSet, is12HourStyle: is12HourStyle)
            cell.label.text = String(format: "%02d", hour)

            let compareHour: Int
            if !is12HourStyle {
                compareHour = hour
            } else {
                let isAm = symbolView?.getIsAm() ?? true
                if isAm {
                    if hour == 12 {
                        compareHour = 0
                    } else {
                        compareHour = hour
                    }
                } else {
                    if hour == 12 {
                        compareHour = 12
                    } else {
                        compareHour = hour + 12
                    }
                }
            }
            // 当前小时有可选项，则该选项 enable
            compareInvalidDate = selectedDate.changed(hour: compareHour, minute: 59) ?? compareInvalidDate
        case thirdScrollView:
            let minutes = self.minutes(withBenchmark: self.benchmarkMinutes, offSet: offSet * MailMinutesDatePickerView.minutesInterval)
            cell.label.text = String(format: "%02d", minutes)

            compareInvalidDate = selectedDate.changed(minute: minutes) ?? compareInvalidDate
        default:
            assertionFailure()
        }

        let minu = MailMinutesDatePickerView.getMultipleOfMinutesInterval(compareInvalidDate.minute)
        compareInvalidDate = compareInvalidDate.changed(minute: minu) ?? compareInvalidDate
        compareInvalidDate = delegate?.calculateLocalDateWithTimeZone(compareInvalidDate) ?? compareInvalidDate

        let isValid = MailScheduleSendController.scheduledDateIsValid(scheduleDate: compareInvalidDate, nowDate: currentDate)
        cell.label.textColor = isValid ? normalTextColor : invalidTextColor
    }

    override func scrollEndScroll(scrollView: InfiniteScrollView) {
        super.scrollEndScroll(scrollView: scrollView)
        let selectedDate = self.generateSelectedDate()
        self.delegate?.minutesDatePicker(self, didSelectDate: selectedDate)
        [firstScrollView, secondScrollView, thirdScrollView].forEach({ $0.reloadData() })
    }

    private func generateSelectedDate() -> Date {
        if let date = self.selectedDay().changed(hour: self.selectedHour())?.changed(minute: self.selectedMinutes()) {
            return date
        }
        return now
    }

    private func selectedDay() -> Date {
        guard let centerCell = self.centerCell(of: firstScrollView) else {
            return now
        }
        return now + DateComponents(day: centerCell.tag) ?? Date()
    }

    private func selectedHour() -> Int {
        guard let centerCell = self.centerCell(of: secondScrollView) else {
            return now.hour
        }
        let hour = self.hour(withBenchmark: self.benchmarkHour, offSet: centerCell.tag, is12HourStyle: is12HourStyle)
        var isAm = symbolView?.getIsAm() ?? true
        // 判断是否需要改变AM / PM
        if needChangeSymbol(lastHour: lastHour, hourChangeTag: centerCell.tag - lastHourChangeTag) {
            symbolView?.setIsAm(!isAm)
        }
        lastHourChangeTag = centerCell.tag // 记录本次偏移量
        if !is12HourStyle {
            return hour
        }
        isAm = symbolView?.getIsAm() ?? true
        lastHour = hour // 记录本次调整后的时间
        if isAm {
            if hour == 12 { return 0 }
            return hour
        } else { // PM
            if hour == 12 { return 12 }
            return hour + 12
        }
    }

    private func selectedMinutes() -> Int {
        guard let centerCell = self.centerCell(of: thirdScrollView) else {
            return now.minute
        }
        return self.minutes(withBenchmark: self.benchmarkMinutes, offSet: centerCell.tag * MailMinutesDatePickerView.minutesInterval)
    }

    // MARK: methods
    private func minutes(withBenchmark mark: Int, offSet: Int) -> Int {
        let modNumber = 60
        var mark = (mark + offSet) % modNumber
        if mark < 0 { mark += modNumber }
        return mark
    }

    private func hour(withBenchmark mark: Int, offSet: Int, is12HourStyle: Bool) -> Int {
        let modNumber = is12HourStyle ? 12 : 24
        var mark = (mark + offSet) % modNumber
        if mark < 0 { mark += modNumber }
        if is12HourStyle, mark == 0 {
            mark = 12
        }
        return mark
    }

    // 是否切换AM / PM
    private func needChangeSymbol(lastHour: Int, hourChangeTag: Int) -> Bool {
        if lastHour < 12 && lastHour + hourChangeTag >= 12
            || lastHour + hourChangeTag < 0
            || lastHour == 12 && hourChangeTag < 0 {
            return true
        }
        return false
    }
}
