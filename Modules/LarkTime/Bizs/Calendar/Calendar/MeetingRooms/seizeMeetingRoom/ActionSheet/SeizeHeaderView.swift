//
//  SeizeHeaderView.swift
//  Calendar
//
//  Created by harry zou on 2019/4/17.
//

import UIKit
import CalendarFoundation
final class SeizeHeaderView: UIView {

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: 68)
    }

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Calendar.Calendar_Takeover_SelectTime
        label.font = UIFont.cd.mediumFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    let subTitleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Calendar.Calendar_Takeover_TipsSheetTwo
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(11)
            make.left.equalToSuperview().offset(16)
        }
        addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-13)
        }
        addBottomBorder()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
