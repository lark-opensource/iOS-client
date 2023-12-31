//
//  DatePickerHeaderView.swift
//  LarkSearch
//
//  Created by SuPeng on 4/23/19.
//

import UIKit
import Foundation
import JTAppleCalendar
import LarkTimeFormatUtils
import UniverseDesignFont

final class DatePickerHeaderView: JTAppleCollectionReusableView {
    private let stackView = UIStackView()
    private let labels: [UILabel]

    override init(frame: CGRect) {

        labels = Array(1...7)
            .map { (weekday) -> UILabel in
                let title = TimeFormatUtils.weekdayAbbrString(weekday: weekday)
                let label = UILabel()
                label.font = UDFont.systemFont(ofSize: 12)
                label.textColor = UIColor.ud.textTitle
                label.text = title
                label.textAlignment = .center
                return label
            }

        super.init(frame: frame)

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        labels.forEach { (label) in
            stackView.addArrangedSubview(label)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setRange(start: Date, end: Date) {
        let date = Date()
        if date.ls.greatOrEqualTo(date: start) && date.ls.lessOrEqualTo(date: end) {
            setColorFor(weekIndex: date.week - 1)
        } else {
            setColorFor(weekIndex: nil)
        }
    }

    private func setColorFor(weekIndex: Int?) {
        let weekIndex = weekIndex ?? Int.max
        labels.enumerated().forEach { (index, label) in
            if index == weekIndex {
                label.textColor = UIColor.ud.functionInfoContentDefault
            } else {
                label.textColor = UIColor.ud.textTitle
            }
        }
    }
}
