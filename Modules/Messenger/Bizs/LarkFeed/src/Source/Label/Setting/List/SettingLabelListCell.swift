//
//  SettingLabelListCell.swift
//  LarkFeed
//
//  Created by aslan on 2022/4/20.
//

import Foundation
import UniverseDesignCheckBox
import UniverseDesignIcon
import UIKit

final class SettingLabelListCell: UITableViewCell {
    /// label icon
    private let iconImageView = UIImageView()
    /// 标题
    private let titleLabel = UILabel()
    /// 选中图标
    private let checkBox = UDCheckBox(boxType: .multiple)

    private let lineView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        let image = Resources.labelCustomOutlined
        self.iconImageView.image = image
        self.contentView.addSubview(self.iconImageView)
        self.iconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        /// 选中图标
        self.checkBox.isUserInteractionEnabled = false
        self.contentView.addSubview(self.checkBox)
        self.checkBox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        /// 标题
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.lineBreakMode = .byTruncatingTail
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.iconImageView.snp.right).offset(12)
            make.right.equalTo(self.checkBox.snp.left).offset(-12)
            make.centerY.equalToSuperview()
        }

        /// 分割线
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        self.contentView.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, isSelected: Bool) {
        self.titleLabel.text = title
        self.checkBox.isSelected = isSelected
    }
}
