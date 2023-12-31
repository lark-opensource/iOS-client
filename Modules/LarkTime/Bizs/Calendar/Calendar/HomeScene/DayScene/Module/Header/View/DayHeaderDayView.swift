//
//  DayHeaderDayView.swift
//  Calendar
//
//  Created by 张威 on 2020/7/29.
//

/// DayScene - Header - DayItemView
/// 日视图 Header 部分的 day view，每一天对应一个 `DayHeaderDayView`

import UIKit
import LarkExtensions
import UniverseDesignFont

protocol DayHeaderDayViewDataType {
    var weekText: String { get }
    var dayText: String { get }
    var alternateDayText: String? { get }
    var status: JulianDayStatus { get }
}

final class DayHeaderDayView: UIView, ViewDataConvertible {
    var viewData: DayHeaderDayViewDataType? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            if let oldViewData = oldValue,
                oldViewData.weekText == viewData.weekText,
                oldViewData.dayText == viewData.dayText,
                oldViewData.alternateDayText == viewData.alternateDayText,
                oldViewData.status == viewData.status {
                return
            }
            isHidden = false
            weekLabel.text = viewData.weekText
            dayLabel.text = viewData.dayText
            alternateDayLabel.text = viewData.alternateDayText
            let (color1, color2, color3): (UIColor, UIColor, UIColor)
            switch viewData.status {
            case .past: (color1, color2, color3) = (UIColor.ud.textPlaceholder, UIColor.ud.textPlaceholder, UIColor.ud.textPlaceholder)
            case .today: (color1, color2, color3) = (UIColor.ud.primaryContentDefault, UIColor.ud.primaryContentDefault, UIColor.ud.primaryContentDefault)
            case .future: (color1, color2, color3) = (UIColor.ud.textPlaceholder, UIColor.ud.textTitle, UIColor.ud.textPlaceholder)
            }
            weekLabel.textColor = color1
            dayLabel.textColor = color2
            alternateDayLabel.textColor = color3
            setNeedsLayout()
        }
    }

    private let weekLabel = UILabel()
    private let dayLabel = UILabel()
    private let alternateDayLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        weekLabel.font = UIFont.cd.regularFont(ofSize: 12)
        addSubview(weekLabel)

        if UDFontAppearance.isCustomFont {
            dayLabel.font = UIFont.cd.mediumFont(ofSize: 20)
        } else {
            dayLabel.font = UDFont.dinBoldFont(ofSize: 24)
        }
        addSubview(dayLabel)

        alternateDayLabel.font = UIFont.cd.regularFont(ofSize: 11)
        addSubview(alternateDayLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        weekLabel.frame = CGRect(x: 8, y: 13, width: bounds.width - 16, height: 17)
        dayLabel.sizeToFit()
        dayLabel.frame = CGRect(x: 8, y: weekLabel.frame.bottom, width: ceil(dayLabel.frame.width), height: 28)

        if !(alternateDayLabel.text?.isEmpty ?? true) {
            alternateDayLabel.frame = CGRect(
                x: dayLabel.frame.right + 6,
                y: weekLabel.frame.bottom + 9,
                width: bounds.width - dayLabel.frame.right - 14,
                height: 15
            )
        }
    }

}
