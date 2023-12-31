//
//  WeekHeaderView.swift
//  SpaceKit
//
//  Created by nine on 2019/3/19.
//  Copyright © 2019 nine. All rights reserved.
//

import Foundation
import UIKit
import JTAppleCalendar
import SKCommon
import SKResource
import LarkTimeFormatUtils
import UniverseDesignColor

class WeekHeaderView: UIView {

    private let textFont = UIFont.systemFont(ofSize: 12)
    private let normalColor = UDColor.N600
    private let stackView = UIStackView()

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        layoutStackView(stackView)
        layoutLabels(stackView: stackView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func weekInfo(index: Int) -> (String, Int) {
        let weekday = (index) % 7 + 1
        let string = weekString(weekday: weekday)
        return (string, weekday)
    }

    private func layoutStackView(_ stackView: UIStackView) {
        self.addSubview(stackView)
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .fillEqually

        stackView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(3)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
    }

    private func layoutLabels(stackView: UIStackView) {
        for i in 0..<7 {
            let (weekString, weekday) = self.weekInfo(index: i)
            let label = weeklabel(weekString)
            label.tag = weekday
            stackView.addArrangedSubview(label)
        }
    }

    private func weeklabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = textFont
        label.textAlignment = .center
        label.text = text
        label.textColor = normalColor
        return label
    }

    func weekString(weekday: Int) -> String {
        guard weekday >= 1, weekday <= 7 else {
            assertionFailure()
            return " "
        }
        
        return TimeFormatUtils.weekdayAbbrString(weekday: weekday)
    }
}
