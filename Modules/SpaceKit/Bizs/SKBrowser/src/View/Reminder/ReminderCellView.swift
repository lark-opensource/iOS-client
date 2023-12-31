//
//  MonthViewCell.swift
//  SpaceKit
//
//  Created by zhouyuan on 2018/8/2.
//  Copyright © 2018年 zhouyuan. All rights reserved.
//

import UIKit
import JTAppleCalendar
import UniverseDesignColor

class MonthViewCell: JTAppleCell {

    static let dayFont = UIFont(name: "DINAlternate-Bold", size: 16)
    static let selectViewWidth: CGFloat = 32

    private let selectedView = UIView()
    private let dayLabel = UILabel()
    private var pointViews = [UIView]()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.layoutSelectedView(selectedView)
        self.layoutDayLabel(dayLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutSelectedView(_ view: UIView) {
        view.layer.cornerRadius = MonthViewCell.selectViewWidth / 2
        view.layer.allowsEdgeAntialiasing = true
        contentView.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.width.equalTo(MonthViewCell.selectViewWidth)
        }
    }

    private func layoutDayLabel(_ label: UILabel) {
        label.textAlignment = .center
        label.font = MonthViewCell.dayFont
        selectedView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.height.width.equalTo(MonthViewCell.selectViewWidth)
            make.center.equalToSuperview()
        }
    }

    func setContent(text: String) {
        dayLabel.text = text
    }
    
    func setDayLabelColor(color: UIColor) {
        self.dayLabel.textColor = color
        if color == UDColor.bgBody {
            dayLabel.docs.removeAllPointer()
            selectedView.docs.removeAllPointer()
            selectedView.docs.addStandardLift()
        } else {
            dayLabel.docs.removeAllPointer()
            selectedView.docs.removeAllPointer()
            dayLabel.docs.addHighlight(with: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), radius: MonthViewCell.selectViewWidth / 2)
        }
    }

    func setSelectViewColor(color: UIColor) {
        self.selectedView.backgroundColor = color
        if self.selectedView.backgroundColor == UIColor.white {
            self.selectedView.backgroundColor = .clear
        }
    }
}
