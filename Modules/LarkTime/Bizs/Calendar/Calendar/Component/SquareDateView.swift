//
//  SquareDateView.swift
//  CalendarInChat
//
//  Created by zoujiayi on 2019/8/11.
//

import UIKit
import LarkTimeFormatUtils
import CalendarFoundation
import UniverseDesignFont

public struct SquareDateViewLocationInfo {
    public var minY: CGFloat
    public var maxY: CGFloat
    // Initialization
    var monthString: String = ""
    var dateString: String = ""
    var isLaterThanToday: Bool?
    public init(minY: CGFloat,
                maxY: CGFloat,
                eventDate: Date) {
        self.minY = minY
        self.maxY = maxY
        let today = Date()
        let isToday = Calendar(identifier: .gregorian).isDate(eventDate, inSameDayAs: today)
        self.isLaterThanToday = isToday ? nil : eventDate > today
        let customOptions = Options(timeFormatType: .short)
        dateString = CalendarTimeFormatter.formatDayWithLeadingZero(from: eventDate)
        monthString = TimeFormatUtils.formatMonth(from: eventDate, with: customOptions)
    }
}

public final class SquareDateView: UIView {
    public var topInset: CGFloat = 5

    private let weekDayLabel = UILabel()
    private let monthDayLabel = UILabel()

    public init(item: SquareDateViewLocationInfo?) {
        super.init(frame: CGRect.zero)
        layoutWeekDayLabel(weekDayLabel)
        layoutDateLabel(monthDayLabel)
        guard let item = item else {
            assertionFailureLog()
            return
        }
        update(item: item)
    }

    public func update(item: SquareDateViewLocationInfo) {
        weekDayLabel.text = item.monthString
        monthDayLabel.text = item.dateString
        updateLabelColor(label: weekDayLabel, isLaterThanToday: item.isLaterThanToday)
        updateLabelColor(label: monthDayLabel, isLaterThanToday: item.isLaterThanToday)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutWeekDayLabel(_ label: UILabel) {
        label.font = UIFont.cd.semiboldFont(ofSize: 12)
        self.addSubview(label)
        label.textColor = UIColor.ud.N900
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: topInset, width: 57, height: 17.0)
    }

    private func layoutDateLabel(_ label: UILabel) {
        self.addSubview(label)
        if UDFontAppearance.isCustomFont {
            label.font = UIFont.cd.mediumFont(ofSize: 20)
        } else {
            label.font = UDFont.dinBoldFont(ofSize: 26)
        }
        label.textColor = UIColor.ud.N900
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: 17 + topInset, width: 57, height: 31.0)
    }

    private func updateLabelColor(label: UILabel, isLaterThanToday: Bool?) {
        // nil 表示今天
        guard let isLater = isLaterThanToday else {
            label.textColor = UIColor.ud.colorfulBlue
            return
        }
        label.textColor = isLater ? UIColor.ud.N900 : UIColor.ud.N400
    }
}
