//
//  EventCustomRruleMonthWeekdayPicker.swift
//  Calendar
//
//  Created by 张威 on 2020/4/16.
//

import UIKit
import EventKit

final class EventCustomRruleMonthWeekdayPicker: UIControl, DayOfWeekPickerDelegate {

    static let desiredHeight: CGFloat = 156

    var weekday: EKRecurrenceDayOfWeek { innerPicker.currentWeekDay }

    var isPickingEnabled: Bool = true {
        didSet {
            innerPicker.isUserInteractionEnabled = isPickingEnabled
        }
    }

    private let innerPicker: DayOfWeekPicker

    init(frame: CGRect, weekOfMonth: Int = 0, weekday: Int = 1) {
        let innerPickerFrame = CGRect(x: 0, y: 0, width: frame.width, height: Self.desiredHeight)
        innerPicker = DayOfWeekPicker(
            frame: innerPickerFrame,
            weekOfMonth: weekOfMonth,
            maxWeekOfMonth: 5,
            weekday: weekday
        )
        super.init(frame: frame)

        innerPicker.backgroundColor = UIColor.ud.bgBody
        innerPicker.delegate = self
        addSubview(innerPicker)
        innerPicker.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: DayOfWeekPickerDelegate

    func dayOfWeekPicker(
        _ picker: DayOfWeekPicker,
        didSelectDayOfWeek dayOfWeek: EKRecurrenceDayOfWeek
    ) {
        sendActions(for: .valueChanged)
    }
}
