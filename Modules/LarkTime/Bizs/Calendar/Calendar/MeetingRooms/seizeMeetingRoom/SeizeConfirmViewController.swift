//
//  SeizeConfirmViewController.swift
//  Calendar
//
//  Created by harry zou on 2019/4/16.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkUIKit
import LarkAlertController
final class SeizeConfirmView {
    private let wrapper = Wrapper()
    private var confirmVC: LarkAlertController
    var confirmPressed: ((Bool) -> Void)?

    init() {
        confirmVC = LarkAlertController()
        confirmVC.setTitle(text: BundleI18n.Calendar.Calendar_Takeover_TipsNoUse)
        confirmVC.setContent(view: wrapper)
        confirmVC.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Takeover_Confirm, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.confirmPressed?(self.wrapper.isOn)
        })
    }

    func show(in controller: UIViewController) {
        controller.present(confirmVC, animated: true)
    }
}

private final class Wrapper: UIView {
    var isOn: Bool {
        return checkbox.on
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: 263, height: size.height)
    }

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.numberOfLines = 0
        label.text = BundleI18n.Calendar.Calendar_Takeover_TipsNoUseTwo
        label.textAlignment = .center
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    let checkbox: Checkbox = {
        let checkbox = Checkbox()
        checkbox.boxType = .circle
        checkbox.minTouchSize = CGSize(width: 25, height: 25)
        checkbox.onFillColor = UIColor.ud.primaryContentDefault
        checkbox.offFillColor = UIColor.ud.primaryOnPrimaryFill
        checkbox.onCheckColor = UIColor.ud.primaryOnPrimaryFill
        checkbox.setOn(on: true)
        return checkbox
    }()

    let checkboxLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.numberOfLines = 0
        label.text = BundleI18n.Calendar.Calendar_Takeover_TipsNoShow
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
        addSubview(checkbox)
        checkbox.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
            make.width.height.equalTo(16)
            make.left.bottom.equalToSuperview()
        }
        addSubview(checkboxLabel)
        checkboxLabel.snp.makeConstraints { (make) in
            make.left.equalTo(checkbox.snp.right).offset(7)
            make.centerY.equalTo(checkbox)
            make.right.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
