//
//  SettingLabelAddCell.swift
//  LarkFeed
//
//  Created by aslan on 2022/4/24.
//

import UIKit
import Foundation
import UniverseDesignIcon

final class SettingLabelAddCell: UITableViewCell {
    /// label icon
    private let iconImageView = UIImageView()
    /// 标题
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.iconImageView.image = UDIcon.getIconByKey(.addMiddleOutlined).ud.withTintColor(UIColor.ud.primaryContentDefault)
        self.contentView.addSubview(self.iconImageView)
        self.iconImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.primaryContentDefault
        self.titleLabel.text = BundleI18n.LarkFeed.Lark_Core_CreateLabel_Button_Mobile
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.iconImageView.snp.right).offset(12)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
