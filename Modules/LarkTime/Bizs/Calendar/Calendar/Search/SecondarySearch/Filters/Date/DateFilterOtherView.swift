//
//  DateFilterCalendarView.swift
//  Calendar
//
//  Created by sunxiaolei on 2019/8/13.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignCheckBox
import UniverseDesignFont
import Foundation

final class DateFilterOtherView: UIView {
    var backClickCallback: ( () -> Void )?
    var forwardClickCallback: ( () -> Void )?
    var noLimitClickCallback: ( (Bool) -> Void )?

    private let dateLabel = UILabel()
    private let leftButton = UIButton()
    private let rightButton = UIButton()
    private let noLimitButton: UDCheckBox = {
        let checkbox = UDCheckBox(boxType: .multiple)
        checkbox.isSelected = false
        return checkbox
    }()
    private let noLimitLabel = UILabel()

    init(date: Date, noLimitSelected: Bool) {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody

        let topLayoutGuide = UILayoutGuide()
        addLayoutGuide(topLayoutGuide)
        topLayoutGuide.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(60)
        }

        dateLabel.font = UDFont.systemFont(ofSize: 16)
        dateLabel.textColor = UIColor.ud.textTitle
        addSubview(dateLabel)
        updateDate(date: date)
        dateLabel.snp.makeConstraints { (make) in
            make.left.equalTo(topLayoutGuide.snp.left).offset(16)
            make.centerY.equalTo(topLayoutGuide)
        }

        let backButton = UIButton()
        backButton.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 20, height: 20)), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonDidClick), for: .touchUpInside)
        addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.left.equalTo(topLayoutGuide.snp.left).offset(109)
            make.centerY.equalTo(topLayoutGuide)
        }
        let forwardButton = UIButton()
        forwardButton.setImage(UDIcon.getIconByKey(.rightOutlined, iconColor: UIColor.ud.iconN2, size: CGSize(width: 20, height: 20)), for: .normal)
        forwardButton.addTarget(self, action: #selector(forwardButtonDidClick), for: .touchUpInside)
        addSubview(forwardButton)
        forwardButton.snp.makeConstraints { (make) in
            make.left.equalTo(backButton.snp.right).offset(16)
            make.centerY.equalTo(topLayoutGuide)
        }

        noLimitLabel.text = BundleI18n.Calendar.Lark_Search_AnyTime
        noLimitLabel.font = UDFont.systemFont(ofSize: 16)
        addSubview(noLimitLabel)
        noLimitLabel.snp.makeConstraints { (make) in
            make.right.equalTo(topLayoutGuide.snp.right).offset(-19)
            make.centerY.equalTo(topLayoutGuide)
        }

        noLimitButton.tapCallBack = { [weak self] _ in
            guard let self = self else { return }
            self.noLimitButtonDidClick()
        }
        noLimitButton.isSelected = noLimitSelected
        addSubview(noLimitButton)
        noLimitButton.snp.makeConstraints { (make) in
            make.right.equalTo(noLimitLabel.snp.left).offset(-7.5)
            make.centerY.equalTo(topLayoutGuide)
        }

    }

    func updateDate(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = BundleI18n.Calendar.Calendar_StandardTime_YearMonthCombineFormat
        dateLabel.text = formatter.string(from: date)
    }

    func updateNolimit(noLimitSelected: Bool) {
        noLimitButton.isSelected = noLimitSelected
    }

    @objc
    private func backButtonDidClick() {
        backClickCallback?()
    }

    @objc
    private func forwardButtonDidClick() {
        forwardClickCallback?()
    }

    private func noLimitButtonDidClick() {
        if noLimitButton.isSelected {
            noLimitButton.isSelected = false
        } else {
            noLimitButton.isSelected = true
        }
        noLimitClickCallback?(noLimitButton.isSelected)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
