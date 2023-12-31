//
//  MonthViewCell.swift
//  MyDemo
//
//  Created by zhouyuan on 2018/8/2.
//  Copyright © 2018年 zhouyuan. All rights reserved.
//

import UIKit
import SnapKit
import JTAppleCalendar
import CalendarFoundation
import UniverseDesignFont

final class MonthViewCell: JTAppleCell {
    static let alternateCalendarCellHeight: CGFloat = 62
    static let normalCellHeight: CGFloat = 37

    static let dayFont = UDFontAppearance.isCustomFont ? UIFont.cd.mediumFont(ofSize: 16) : UIFont.cd.dinBoldFont(ofSize: 18)
    private let selectViewWidth: CGFloat

    private let selectedView = UIView()
    private let dayLabel = UILabel()
    private let alternateCalendarLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 11)
        return label
    }()
    private let pointStackView = UIStackView()
    private var pointViews = [UIView]()

    private let isAlternateCalOpen: Bool

    override init(frame: CGRect) {
        self.isAlternateCalOpen = frame.height.isEqual(to: MonthViewCell.alternateCalendarCellHeight - 20)
        self.selectViewWidth = isAlternateCalOpen ? 28 : 32
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        self.layoutSelectedView(selectedView)
        self.layoutDayLabel(dayLabel)
        if isAlternateCalOpen {
            self.layoutalternateCalendarLabel(alternateCalendarLabel)
        }
        self.layoutStackView(pointStackView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutSelectedView(_ view: UIView) {
        view.layer.cornerRadius = selectViewWidth / 2
        view.layer.allowsEdgeAntialiasing = true
        self.addSubview(view)
        if isAlternateCalOpen {
            view.snp.makeConstraints { (make) in
                make.top.equalToSuperview()
                make.centerX.equalToSuperview()
                make.height.width.equalTo(selectViewWidth)
            }
        } else {
            view.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.height.width.equalTo(selectViewWidth)
            }
        }
    }

    private func layoutDayLabel(_ label: UILabel) {
        label.textAlignment = .center
        label.font = MonthViewCell.dayFont
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalTo(selectedView.snp.center)
        }
    }

    private func layoutalternateCalendarLabel(_ label: UILabel) {
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(selectedView.snp.bottom).offset(0.5)
        }
    }

    private func layoutStackView(_ stackView: UIStackView) {
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.spacing = 2
        stackView.distribution = .fill
        self.addSubview(stackView)
        if isAlternateCalOpen {
            stackView.snp.makeConstraints { (make) in
                make.top.equalTo(alternateCalendarLabel.snp.bottom).offset(3)
                make.centerX.equalToSuperview()
            }
        } else {
            stackView.snp.makeConstraints { (make) in
                make.top.equalTo(dayLabel.snp.bottom)
                make.centerX.equalToSuperview()
            }
        }
        setPointViews()
    }

    private func setPointViews() {
        (0..<4).forEach { (_) in
            let view = getPointView()
            pointViews.append(view)
            view.snp.makeConstraints { (make) in
                make.width.equalTo(4).priority(.medium)
                make.height.equalTo(4)
            }
            pointStackView.addArrangedSubview(view)
        }
    }

    private func getPointView() -> UIView {
        let view = UIView()
        view.frame.size = CGSize(width: 4, height: 4)
        view.layer.cornerRadius = 2
        view.layer.masksToBounds = true
        return view
    }

    func setContent(text: String, colors: [UIColor]?, alternateCalendarText: String?) {
        dayLabel.text = text
        if let text = alternateCalendarText {
            alternateCalendarLabel.text = text
        }
        pointStackView.subviews.forEach { (view) in
            view.isHidden = true
        }
        guard let colors = colors,
            !colors.isEmpty else {
                return
        }
        // 同样的颜色 只显示一次
        let colorSet = Set(colors.map { $0 })
        for (index, color) in colorSet.enumerated() {
            if index >= 4 { return }
            let view = pointViews[index]
            view.backgroundColor = color
            view.isHidden = false
        }
    }

    func setSelected(isSelected: Bool) {
        self.selectedView.isHidden = !isSelected
        self.pointStackView.isHidden = isSelected
    }

    func setDayLabelColor(color: UIColor) {
        self.dayLabel.textColor = color
    }

    func setAlternateCalLabelColor(color: UIColor) {
        self.alternateCalendarLabel.textColor = color
    }

    func setSelectViewColor(color: UIColor) {
        self.selectedView.backgroundColor = color
    }

    func setCellDisabled() {
        dayLabel.textColor = UIColor.ud.textDisable
        selectedView.isHidden = false
        selectedView.backgroundColor = UIColor.ud.N300
    }
}
