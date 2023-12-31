//
//  EventEditDatePickerView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/5.
//

import UIKit
import LarkUIKit
import CTFoundation
import UniverseDesignDatePicker

final class EventEditDatePickerView: UIControl {

    enum Mode {
        enum HourStyle {
            /// 12-hour style
            case hour12
            /// 24-hour style
            case hour24
        }

        // Displays year, month, day, and week
        case allDay
        // Displays month, day, weekday, hour, minute
        case nonAllDay(hourStyle: HourStyle)
    }

    var date: Date
    var onDateSelected: ((Date) -> Void)?

    private var innerDatePicker: UDDateWheelPickerView?
    private var displayWidth: CGFloat?

    convenience init(initialDate: Date = Date(), mode: Mode = .nonAllDay(hourStyle: .hour24)) {
        self.init(displayWidth: nil, initialDate: initialDate, mode: mode)
    }

    init(displayWidth: CGFloat?, initialDate: Date = Date(), mode: Mode = .nonAllDay(hourStyle: .hour24)) {
        self.displayWidth = displayWidth
        self.date = initialDate
        super.init(frame: .zero)
        switch mode {
        case .allDay:
            setupAllDayDatePicker(initialDate: date)
        case .nonAllDay(let hourStyle):
            setupNonAllDayDatePicker(initialDate: date, hourStyle: hourStyle)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateDate(_ date: Date) {
        guard date != self.date,
              let innerDatePicker = self.innerDatePicker else { return }
        innerDatePicker.select(date: date)
    }

    private func setupAllDayDatePicker(initialDate: Date) {
        let config = UDWheelsStyleConfig(mode: .yearMonthDay,
                                         maxDisplayRows: 5,
                                         textFont: UIFont.ud.title4(.fixed),
                                         backgroundColor: UIColor.ud.bgFloat)
        let picker = UDDateWheelPickerView(date: initialDate,
                                           wheelConfig: config)
        picker.backgroundColor = UIColor.ud.bgFloat
        picker.dateChanged = { [weak self] (date) in
            guard let self = self else { return }
            self.date = date
            self.onDateSelected?(date)
        }
        addSubview(picker)
        picker.snp.makeConstraints {
            $0.trailing.leading.equalToSuperview().inset(16)
            $0.height.equalTo(254)
            $0.top.bottom.equalToSuperview()
        }
        innerDatePicker = picker
    }

    private func setupNonAllDayDatePicker(initialDate: Date, hourStyle: Mode.HourStyle) {
        let is12HourStyle: Bool
        switch hourStyle {
        case .hour12: is12HourStyle = true
        default: is12HourStyle = false
        }
        let minInterval = 5
        let maxTimeStamp = TimeInterval(Double(JulianDayUtil.startOfDay(for: JulianDayUtil.julianDayFrom2100_01_01,
                                                                        in: .current)) - Double(minInterval * 60))
        let maxDate = Date(timeIntervalSince1970: maxTimeStamp)
        let config = UDWheelsStyleConfig(mode: .dayHourMinute(twelveHourScale: [3.0, 1.0, 1.0, 1.0], twentyFourHourScale: [126.0, 109.0, 109.0]),
                                         maxDisplayRows: 5,
                                         is12Hour: is12HourStyle,
                                         minInterval: minInterval,
                                         textFont: UIFont.ud.title4(.fixed),
                                         backgroundColor: UIColor.ud.bgFloat)
        let picker = UDDateWheelPickerView(date: initialDate,
                                           maximumDate: maxDate,
                                           wheelConfig: config)
        picker.backgroundColor = UIColor.ud.bgFloat
        picker.dateChanged = { [weak self] (date) in
            guard let self = self else { return }
            self.date = date
            self.onDateSelected?(date)
        }
        addSubview(picker)
        picker.snp.makeConstraints {
            $0.trailing.leading.equalToSuperview()// .inset(16)
            $0.height.equalTo(254)
            $0.top.bottom.equalToSuperview()
        }
        innerDatePicker = picker
    }

}
