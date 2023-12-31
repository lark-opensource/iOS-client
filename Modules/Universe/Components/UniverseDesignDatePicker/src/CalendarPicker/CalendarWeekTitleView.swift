//
//  CalendarWeekTitleView.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2021/3/17.
//

import Foundation
import UIKit
import LarkTimeFormatUtils
import UniverseDesignFont
import EventKit

class CalendarWeekTitleView: UIView {
    private let textFont = UDFont.systemFont(ofSize: 12)
    private let normalColor = UDDatePickerTheme.calendarPickerCurrentMonthTextColor
    private let highlightColor = UDDatePickerTheme.calendarPickerWeekSelectedTextColor

    private let stackView = UIStackView()
    private var firstWeekday: EKWeekday

    init(firstWeekday: EKWeekday) {
        self.firstWeekday = firstWeekday
        super.init(frame: .zero)
        backgroundColor = UDDatePickerTheme.wheelPickerBackgroundColor
        layoutStackView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutStackView() {
        addSubview(stackView)
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .fillEqually

        stackView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.lessThanOrEqualToSuperview().offset(5)
            make.right.greaterThanOrEqualToSuperview().offset(-6)
        }

        (0..<7).forEach {
            let label = UILabel()
            label.font = textFont
            label.textAlignment = .center
            label.textColor = normalColor

            let weekday = ($0 + firstWeekday.rawValue - 1) % 7 + 1
            let title = TimeFormatUtils.weekdayAbbrString(weekday: weekday)
            label.text = title
            label.tag = weekday
            stackView.addArrangedSubview(label)
        }
    }

    func refreshHighlightedLabel(todayWeekday: EKWeekday, isHighlight: Bool) {
        let index = (7 + todayWeekday.rawValue - firstWeekday.rawValue) % 7
        guard index < stackView.arrangedSubviews.count,
              let today = stackView.arrangedSubviews[index] as? UILabel else {
            assertionFailure("未取到正确的 weekLabel")
            return
        }
        today.textColor = isHighlight ? highlightColor : normalColor
    }
}
