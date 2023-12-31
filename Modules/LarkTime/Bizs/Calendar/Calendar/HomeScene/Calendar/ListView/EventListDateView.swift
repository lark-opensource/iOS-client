//
//  EventListDateView.swift
//  Calendar
//
//  Created by zoujiayi on 2019/6/19.
//

import UIKit
import Foundation
import CalendarFoundation
import UniverseDesignFont

struct EventListDateViewLocationInfo {
    var minY: CGFloat
    var maxY: CGFloat
    var firstItem: BlockListEventItem?
}

final class EventListDateView: UIView {
    private let weekDayLabel = UILabel()
    private let monthDayLabel = UILabel()
    private let alternateCalendarLabel = UILabel()

    private let alternateCalendar: AlternateCalendarEnum
    private let isAlternateCalOpen: Bool

    init(item: BlockListEventItem?, alternateCalendar: AlternateCalendarEnum) {
        self.alternateCalendar = alternateCalendar
        self.isAlternateCalOpen = alternateCalendar != .noneCalendar
        super.init(frame: CGRect.zero)
        layoutWeekDayLabel(weekDayLabel)
        layoutDateLabel(monthDayLabel)
        if isAlternateCalOpen {
            layoutalternateCalendarLabel(alternateCalendarLabel)
        }
        guard let item = item else {
            assertionFailureLog()
            return
        }
        update(item: item)
    }

    func update(item: BlockListEventItem) {
        weekDayLabel.text = item.weekDay
        monthDayLabel.text = item.monthDay
        updateLabelColor(label: weekDayLabel, isLaterThanToday: item.isLaterThanToday)
        updateLabelColor(label: monthDayLabel, isLaterThanToday: item.isLaterThanToday)
        // eventDate是当天的23:59:59
        if isAlternateCalOpen {
            DispatchQueue.global().async {
                let text = AlternateCalendarUtil.getDisplayElement(date: item.eventDate,
                                                                   type: self.alternateCalendar)
                DispatchQueue.main.async {
                    self.alternateCalendarLabel.text = text
                    self.updateAlternateCalendarLabelColor(label: self.alternateCalendarLabel, isLaterThanToday: item.isLaterThanToday)
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutWeekDayLabel(_ label: UILabel) {
        label.font = UIFont.cd.semiboldFont(ofSize: 12)
        self.addSubview(label)
        label.textColor = UIColor.ud.N800
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: 0, width: 57, height: 17.0)
    }

    private func layoutDateLabel(_ label: UILabel) {
        self.addSubview(label)
        // 西文字体开关
        if UDFontAppearance.isCustomFont {
            label.font = UIFont.cd.mediumFont(ofSize: 20)
        } else {
            label.font = UDFont.dinBoldFont(ofSize: 26)
        }
        label.textColor = UIColor.ud.N800
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: 17, width: 57, height: 31.0)
    }

    private func layoutalternateCalendarLabel(_ label: UILabel) {
        label.font = UIFont.cd.semiboldFont(ofSize: 11)
        self.addSubview(label)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: 48, width: 57, height: 17.0)
    }

    private func updateAlternateCalendarLabelColor(label: UILabel, isLaterThanToday: Bool?) {
        // nil 表示今天
        guard let isLater = isLaterThanToday else {
            label.textColor = UIColor.ud.primaryContentDefault
            return
        }
        label.textColor = isLater ? UIColor.ud.textPlaceholder : UIColor.ud.textDisable
    }

    private func updateLabelColor(label: UILabel, isLaterThanToday: Bool?) {
        // nil 表示今天
        guard let isLater = isLaterThanToday else {
            label.textColor = UIColor.ud.primaryContentDefault
            return
        }
        label.textColor = isLater ? UIColor.ud.N800 : UIColor.ud.textDisable
    }
}
