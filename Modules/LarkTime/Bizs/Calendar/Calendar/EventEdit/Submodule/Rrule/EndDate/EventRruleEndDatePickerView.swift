//
//  EventRruleEndDatePickerView.swift
//  Calendar
//
//  Created by Lianghongbin on 2021/9/7.
//

import UIKit
import Foundation
import UniverseDesignDatePicker

final class EventRruleEndDatePickerView: UIView {

    private let endlessLabel = UILabel()
    let titleCell = UIView()
    private let datePickerTitle: UILabel = {
        let label = UILabel()
        label.font = EventEditUIStyle.Font.smallText
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.Calendar.Calendar_Edit_EndsDate
        return label
    }()
    private var divdeView: UIView?
    let endlessSwitch = UISwitch.blueSwitch()
    let datePicker: UDDateWheelPickerView

    init(endDate: Date) {
        let pickerConfig = UDWheelsStyleConfig(mode: .yearMonthDayWeek,
                                               maxDisplayRows: 5,
                                               showSepeLine: false,
                                               textFont: UIFont.ud.title4(.fixed),
                                               backgroundColor: EventEditUIStyle.Color.viewControllerBackground)
        datePicker = .init(date: endDate, wheelConfig: pickerConfig)
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setBgColor(_ color: UIColor) {
        backgroundColor = color
        datePicker.backgroundColor = color
        titleCell.backgroundColor = color
    }

    private func setupViews() {
        //titleCell.backgroundColor = UIColor.ud.bgBody
        addSubview(titleCell)
        titleCell.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(52)
        }

        titleCell.addSubview(endlessSwitch)
        endlessSwitch.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.height.equalTo(28)
            $0.width.equalTo(46)
            $0.right.equalToSuperview().offset(-16)
        }

        endlessLabel.textColor = UIColor.ud.textTitle
        endlessLabel.font = EventEditUIStyle.Font.normalText
        endlessLabel.text = BundleI18n.Calendar.Calendar_RRule_NeverEnds
        titleCell.addSubview(endlessLabel)
        endlessLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalTo(endlessSwitch.snp.left).offset(-12)
            $0.left.equalToSuperview().inset(16)
            $0.height.equalTo(24)
        }

        let view = titleCell.addBottomBorder(inset: UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 0),
                                  lineHeight: EventEditUIStyle.Layout.horizontalSeperatorHeight,
                                  bgColor: UIColor.ud.lineDividerDefault)
        self.divdeView = view
        addSubview(datePickerTitle)
        addSubview(datePicker)
        datePickerTitle.snp.makeConstraints {
            $0.top.equalTo(view).inset(22)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(datePicker.snp.top).offset(-4)
        }
        datePicker.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(256)
        }
    }

    func updateDisableMask(show: Bool) {
        datePicker.isHidden = show
        datePickerTitle.isHidden = show
        divdeView?.isHidden = show
    }

    func updateWarningState(isWarning: Bool) {
        guard endlessSwitch.isOn else {
            endlessLabel.textColor = UIColor.ud.textTitle
            return
        }
        endlessLabel.textColor = isWarning ? UIColor.ud.functionDanger500 : UIColor.ud.textTitle
    }
}
