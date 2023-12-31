//
//  ChatAddPinURLSearchCell.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/6.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon

final class ChatAddPinURLSearchCell: UITableViewCell {
    private lazy var iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.layer.cornerRadius = 20
        iconImageView.backgroundColor = UIColor.ud.textLinkHover
        iconImageView.contentMode = .center
        iconImageView.image = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.textLinkNormal, size: CGSize(width: 26, height: 26)).ud.withTintColor(UIColor.ud.bgBody)
        return iconImageView
    }()

    private lazy var urlLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(iconImageView)
        contentView.addSubview(urlLabel)
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        urlLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(20)
        }
    }

    func set(_ text: String) {
        urlLabel.text = text
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
