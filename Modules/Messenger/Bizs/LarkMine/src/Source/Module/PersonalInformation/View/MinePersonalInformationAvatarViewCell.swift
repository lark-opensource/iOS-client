//
//  MineAccountAvatarViewCell.swift
//  LarkMine
//
//  Created by liuwanlin on 2018/8/2.
//

import Foundation
import UIKit
import LarkCore
import LarkUIKit
import LarkBizAvatar
import UniverseDesignIcon

final class MinePersonalInformationAvatarViewCell: BaseSettingCell {
    private let titleLabel = UILabel()
    private let headerImageView = BizAvatar(frame: .zero)
    private let arrowImageView = UIImageView()
    private let avatarSize: CGFloat = 40

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.height.equalTo(64)
            make.left.equalToSuperview().offset(12)
            make.width.lessThanOrEqualTo(self.contentView.frame.width / 2)
        }

        self.arrowImageView.image = UDIcon.getIconByKey(.rightOutlined).ud.withTintColor(UIColor.ud.iconN3)
        self.contentView.addSubview(self.arrowImageView)
        self.arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.right.equalTo(-12)
        }

        self.contentView.addSubview(self.headerImageView)
        self.headerImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(avatarSize)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(self.arrowImageView.snp.leading).offset(-4)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, avatarKey: String, entityId: String) {
        self.titleLabel.text = title
        self.headerImageView.setAvatarByIdentifier(entityId, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
    }
}
