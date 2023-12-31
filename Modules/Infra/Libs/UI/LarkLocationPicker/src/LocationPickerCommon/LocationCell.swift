//
//  LarkLocationCell.swift
//  LarkLocationPicker
//
//  Created by Fangzhou Liu on 2019/7/9.
//
//  用于在日历地点选择界面，展示地点数据

import Foundation
import UIKit
import SnapKit
import LarkTag

final class LarkLocationCell: UITableViewCell {
    private(set) var location: LocationData?
    private let locationIcon: UIImageView = UIImageView(image: BundleResources.LarkLocationPicker.newEventLocationGray)
    /// e.g. "双榆树北路甲3号院-南门"
    private let mainTitle = UILabel()
    /// e.g. "北京市.海淀区.中关村街道.双榆树北路"
    private let subTitle = UILabel()
    private let checkIcon = UIImageView(image: BundleResources.LarkLocationPicker.checkbox_on)
    private let bottomSeparatorLine = UIView()
    private var mainTitleCenterYContraint: Constraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        contentView.addSubview(mainTitle)
        contentView.addSubview(subTitle)
        contentView.addSubview(locationIcon)
        contentView.addSubview(checkIcon)
        contentView.addSubview(bottomSeparatorLine)
        contentView.backgroundColor = UIColor.ud.bgBody

        locationIcon.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.centerY.equalTo(mainTitle.snp.centerY)
            make.left.equalTo(16)
        }

        checkIcon.isHidden = true
        checkIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 18, height: 18))
            make.right.equalToSuperview().offset(-16)
        }

        mainTitle.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        mainTitle.textColor = UIColor.ud.N900
        mainTitle.snp.makeConstraints { (make) in
            make.left.equalTo(locationIcon.snp.right).offset(16)
            make.right.equalTo(checkIcon.snp.left).offset(-16)
            make.top.equalToSuperview().offset(12.5).priority(.medium)
            mainTitleCenterYContraint = make.centerY.equalToSuperview().priority(.low).constraint
        }

        subTitle.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subTitle.textColor = UIColor.ud.N500
        subTitle.snp.makeConstraints { (make) in
            make.left.equalTo(mainTitle.snp.left)
            make.right.equalTo(checkIcon.snp.left).offset(-16)
            make.top.equalTo(mainTitle.snp.bottom)
            make.bottom.equalToSuperview().offset(-13)
        }

        bottomSeparatorLine.backgroundColor = UIColor.ud.N300
        bottomSeparatorLine.snp.makeConstraints { (make) in
            make.left.equalTo(mainTitle.snp.left)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(location: UILocationData, distance: String, isSelect: Bool = false, isCurrent: Bool = false) {
        self.location = location
        mainTitle.text = location.name.isEmpty ? BundleI18n.LarkLocationPicker.Lark_Chat_MessageReplyStatusLocation("") : location.name
        subTitle.text = isCurrent ? "" : location.address
        checkIcon.isHidden = !isSelect
    }

    func setHighLightContent(location: UILocationData, distance: String, keyword: String) {
        guard !keyword.isEmpty else {
            setContent(location: location, distance: distance)
            return
        }
        self.location = location
        mainTitle.attributedText = LarkLocationPickerUtils.createHighlightedString(text: location.name, keywords: keyword, color: UIColor.ud.colorfulBlue)
        subTitle.attributedText = LarkLocationPickerUtils.createHighlightedString(text: location.address, keywords: keyword, color: UIColor.ud.colorfulBlue)
        checkIcon.isHidden = true
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if !highlighted {
            self.backgroundColor = UIColor.ud.N00
        } else {
            self.backgroundColor = UIColor.ud.N300.withAlphaComponent(0.5)
        }
    }
}
