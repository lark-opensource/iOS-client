//
//  DateFilterNaviBar.swift
//  LarkSearch
//
//  Created by SuPeng on 4/19/19.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignFont

protocol DateFilterNaviBarDelegate: AnyObject {
    func naviBarDidClickCloseButton(_ naviBar: DateFilterNaviBar)
    func naviBarDidClickFinishButton(_ naviBar: DateFilterNaviBar)
}

final class DateFilterNaviBar: UIView {
    weak var delegate: DateFilterNaviBarDelegate?

    private let closeButton = UIButton()
    private let titleLabel = UILabel()
    private let finishButton = UIButton()

    init(style: DateFilerItemViewSyle) {
        super.init(frame: .zero)

        backgroundColor = UIColor.ud.bgBody

        closeButton.setImage(LarkUIKit.Resources.navigation_close_light.ud.withTintColor(UIColor.ud.iconN1, renderingMode: .alwaysOriginal), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonDidClick), for: .touchUpInside)
        addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
        }

        titleLabel.font = UDFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        finishButton.setTitle(BundleI18n.Calendar.Calendar_Common_Done, for: .normal)
        finishButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        finishButton.addTarget(self, action: #selector(finishButtonDidClick), for: .touchUpInside)
        finishButton.titleLabel?.font = UDFont.systemFont(ofSize: 16)
        addSubview(finishButton)
        finishButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }

        lu.addBottomBorder()

        set(style: style)
    }

    func set(style: DateFilerItemViewSyle) {
        switch style {
        case .left:
            titleLabel.text = BundleI18n.Calendar.Lark_Search_SelectStartTime
        case .right:
            titleLabel.text = BundleI18n.Calendar.Lark_Search_SelectEndTime
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func closeButtonDidClick() {
        delegate?.naviBarDidClickCloseButton(self)
    }

    @objc
    private func finishButtonDidClick() {
        delegate?.naviBarDidClickFinishButton(self)
    }
}
