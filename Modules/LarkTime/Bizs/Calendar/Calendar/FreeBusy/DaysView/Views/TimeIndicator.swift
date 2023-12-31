//
//  TimeIndicator.swift
//  Calendar
//
//  Created by zhouyuan on 2018/9/11.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import SnapKit
import CalendarFoundation
import LarkLocalizations
import LarkTimeFormatUtils

final class TimeIndicator: UIView {
    typealias BackgroundStyle = CalendarViewStyle.Background
    typealias TimeRuler = CalendarViewStyle.TimeRuler
    let defaulindicatorWidth: CGFloat = 56.0
    // 首页未使用label，改为lazy就行
    private lazy var startTimeLabel: UILabel = {
        var maxLabelWidth: CGFloat = 0
        TimeIndicator.hours(isFor12Hour: is12HourStyle).map { (title) in
            maxLabelWidth = max(maxLabelWidth, title.getWidth(font: TimeRuler.TimeLabel.textFont))
        }
        let label = UILabel()
        label.isHidden = true
        label.textColor = TimeRuler.TimeLabel.textMoveColor
        label.font = TimeRuler.TimeLabel.textFont
        label.textAlignment = .right
        addSubview(label)
        label.snp.makeConstraints { (make) in
            self.startTimeCenterYConstraint = make.centerY.equalTo(0).constraint
            make.right.equalToSuperview().offset(-(defaulindicatorWidth - maxLabelWidth) / 2.0)
        }
        return label
    }()
    private lazy var endTimeLabel: UILabel = {
        let endTimeLabel = UILabel()
        endTimeLabel.isHidden = true
        endTimeLabel.textColor = TimeRuler.TimeLabel.textMoveColor
        endTimeLabel.font = TimeRuler.TimeLabel.textFont
        addSubview(endTimeLabel)
        endTimeLabel.snp.makeConstraints { (make) in
            self.endTimeCenterYConstraint = make.centerY.equalTo(0).constraint
            make.right.equalTo(startTimeLabel.snp.right)
        }
        return endTimeLabel
    }()
    private var startTimeCenterYConstraint: Constraint?
    private var endTimeCenterYConstraint: Constraint?
    let is12HourStyle: Bool

    init(frame: CGRect, is12HourStyle: Bool) {
        self.is12HourStyle = is12HourStyle
        var maxLabelWidth: CGFloat = 0
        let labels = TimeIndicator.hours(isFor12Hour: is12HourStyle).map { (title) -> UILabel in
            maxLabelWidth = max(maxLabelWidth,title.getWidth(font: TimeRuler.TimeLabel.textFont))
            let label = UILabel()
            label.textColor = TimeRuler.TimeLabel.textColor
            label.font = TimeRuler.TimeLabel.textFont
            label.text = title
            return label
        }
        super.init(frame: CGRect(x: frame.origin.x, y: frame.origin.y, width: defaulindicatorWidth, height: frame.size.height))
        var currentY = BackgroundStyle.topGridMargin// - 1.0
        labels.forEach { (label) in
            label.autoresizingMask = [.flexibleLeftMargin, .flexibleWidth]
            self.addSubview(label)
            label.sizeToFit()
            label.textAlignment = .center
            label.frame.center = CGPoint(x: self.frame.centerX, y: currentY)
            label.frame.size = CGSize(width: maxLabelWidth, height: label.bounds.height)
            currentY += BackgroundStyle.hourGridHeight
        }
        self.autoresizesSubviews = true
        let notificationName = Notification.Name(rawValue: "lark.calendar.editableViewFrameChange")
        NotificationCenter.default.addObserver(self, selector: #selector(showStartEndTimeNotification(_:)), name: notificationName, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func indicatorWidth(is12HourStyle: Bool) -> CGFloat {
        return 56.0
    }

    private static func hours(isFor12Hour: Bool) -> [String] {
        let date = Date(timeIntervalSince1970: 0)
        let calendar = Calendar(identifier: .gregorian)
        let ranges = calendar.range(of: .hour, in: .day, for: date) ?? 0..<24
        // 场景: 时间轴显示整点的时间格式
        // 时区使用的是 GMT+0 的时区
        let customOptions = Options(
            timeZone: TimeZone(secondsFromGMT: 0) ?? TimeZone.current,
            is12HourStyle: isFor12Hour,
            timePrecisionType: .minute,
            shouldRemoveTrailingZeros: true
        )
        let getStr = { (date: Date) -> String in
            return TimeFormatUtils.formatTime(from: date, with: customOptions)
        }
        var strings = ranges.map { (index) -> String in
            let date = (date + index.hour) ?? date
            return getStr(date)
        }
        let lastDate = (date + ((ranges.last ?? 23) + 1).hours) ?? date
        var lastDateString = getStr(lastDate)
        handleTrailingFormat(string: &lastDateString)
        strings.append(lastDateString)
        return strings
    }

    @objc
    private func showStartEndTimeNotification(_ notification: Notification) {
        addStartTime(notification.userInfo?["startTime"] as? Date)
        addEndTime(notification.userInfo?["endTime"] as? Date)
    }

    func showStartEndTime(_ startEndTime: (startTime: Date, endTime: Date)?) {
        guard let startEndTime = startEndTime else {
            addStartTime(nil)
            addEndTime(nil)
            return
        }
        addStartTime(startEndTime.startTime)
        addEndTime(startEndTime.endTime)
    }

    private func addStartTime(_ startTime: Date?) {
        if let startTime = startTime {
            startTimeLabel.isHidden = false
            let startTimeString = formatStringFromDate(startTime)
            let lastStartTimeString = (startTimeLabel.text != nil) ? startTimeLabel.text! : ""
            if lastStartTimeString != startTimeString {
                startTimeLabel.text = startTimeString
                startTimeCenterYConstraint?
                    .update(offset: yOffsetWithDate(startTime,
                                                    inTheDay: startTime))
            }
        } else {
            startTimeLabel.isHidden = true
        }
    }

    private func addEndTime(_ endTime: Date?) {
        if let endTime = endTime {
            endTimeLabel.isHidden = false
            var endTimeString = formatStringFromDate(endTime)
            // 侧边栏对"00:00"做过了特殊处理（本类96行），这里保持一致
            TimeIndicator.handleTrailingFormat(string: &endTimeString)
            let lastEndTimeString = (endTimeLabel.text != nil) ? endTimeLabel.text! : ""
            if endTimeString != lastEndTimeString {
                endTimeLabel.text = endTimeString
                // format会把零点解析为00:00，因此这个偏移量被计算到了最顶端
                var offset = yOffsetWithDate(endTime, inTheDay: endTime)
                let errorValue: CGFloat = 20
                if offset == errorValue {
                    offset = 1220
                }
                endTimeCenterYConstraint?
                    .update(offset: offset)
            }
        } else {
            endTimeLabel.isHidden = true
        }
    }

    private func formatStringFromDate(_ date: Date) -> String {
        // 功能: 单独 format 出起始和结束的整点时间
        // 时区使用的是系统当前时区
        let customOptions = Options(
            is12HourStyle: is12HourStyle,
            timePrecisionType: .minute,
            shouldRemoveTrailingZeros: true
        )

        return TimeFormatUtils.formatTime(from: date, with: customOptions)
    }

    private static func handleTrailingFormat(string: inout String) {
        // 从 CATimeFormatter 类中迁出来，这是个语言相关的特化逻辑
        if string == "00:00" {
            string = "24:00"
        }
    }
}
