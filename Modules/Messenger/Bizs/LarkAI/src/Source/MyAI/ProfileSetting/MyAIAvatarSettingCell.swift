//
//  MyAIAvatarSettingCell.swift
//  LarkAI
//
//  Created by Hayden on 2023/5/29.
//

import UIKit
import LarkCore
import LarkUIKit
import ByteWebImage
import UniverseDesignIcon

class MyAIAvatarSettingCell: BaseSettingCell {

    func setAvatar(_ image: UIImage?) {
        self.headerImageView.image = image
    }

    func setAvatar(_ key: String, entityId: String) {
        self.headerImageView.bt.setLarkImage(with: .avatar(key: key, entityID: entityId))
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = BundleI18n.LarkAI.MyAI_IM_AISettings_Avatar_Tab
        return label
    }()

    private let headerImageView = UIImageView()

    private let arrowImageView: UIImageView = {
        let arrowView = UIImageView()
        arrowView.image = UDIcon.getIconByKey(.rightOutlined).ud.withTintColor(UIColor.ud.iconN3)
        return arrowView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        contentView.addSubview(headerImageView)
        contentView.addSubview(arrowImageView)

        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualTo(headerImageView.snp.leading).offset(4)
        }
        headerImageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(self.arrowImageView.snp.leading).offset(-4)
        }
        arrowImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.right.equalTo(-16)
        }

        headerImageView.layer.cornerRadius = 16
        headerImageView.layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
