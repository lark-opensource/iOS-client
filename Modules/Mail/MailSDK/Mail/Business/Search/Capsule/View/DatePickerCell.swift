//
//  DatePickerCell.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/12/1.
//

import UIKit
import Foundation
import JTAppleCalendar
import UniverseDesignFont

enum DatePickerCellState {
    case enable(state: DatePickerCellEnableState)
    case disable
}

enum DatePickerCellEnableState {
    case currentMonth, notCurrentMonth, selected, todaySelected
}

final class DatePickerCell: JTAppleCell {
    private(set) var state: DatePickerCellState?

    private let dateLabel = UILabel()
    private let bgView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        dateLabel.font = UDFont.systemFont(ofSize: 16)
        addSubview(dateLabel)
        dateLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        bgView.clipsToBounds = true
        bgView.layer.cornerRadius = 14
        bgView.layer.ud.setBorderColor(UIColor.ud.primaryContentDefault)
        bgView.layer.borderWidth = 0
        addSubview(bgView)
        sendSubviewToBack(bgView)
        bgView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 28, height: 28))
            make.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(text: String, state: DatePickerCellState, isToday: Bool) {
        self.state = state

        dateLabel.text = text

        switch state {
        case .enable(state: let state):
            switch state {
            case .currentMonth:
                if isToday {
                    dateLabel.textColor = UIColor.ud.primaryContentDefault
                    bgView.isHidden = true
                    bgView.backgroundColor = nil
                    bgView.layer.borderWidth = 0
                } else {
                    dateLabel.textColor = UIColor.ud.textTitle
                    bgView.isHidden = true
                }
            case .notCurrentMonth:
                dateLabel.textColor = UIColor.ud.textPlaceholder
                bgView.isHidden = true
            case .selected:
                dateLabel.textColor = UIColor.ud.textTitle
                bgView.isHidden = false
                bgView.layer.borderWidth = 0
                bgView.backgroundColor = UIColor.ud.lineBorderCard
            case .todaySelected:
                dateLabel.textColor = UIColor.ud.primaryOnPrimaryFill
                bgView.isHidden = false
                bgView.layer.borderWidth = 0
                bgView.backgroundColor = UIColor.ud.primaryContentDefault
            }
        case .disable:
            dateLabel.textColor = UIColor.ud.textPlaceholder
            bgView.isHidden = true
            bgView.layer.borderWidth = 0
            bgView.backgroundColor = UIColor.ud.bgBody
        }
    }
}
