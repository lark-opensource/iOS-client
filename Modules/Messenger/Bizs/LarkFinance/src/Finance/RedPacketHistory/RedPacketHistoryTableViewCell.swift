//
//  RedPacketHistoryTableViewCell.swift
//  LarkFinance
//
//  Created by SuPeng on 12/21/18.
//

import Foundation
import UIKit
import LarkUIKit
import LarkCore
import DateToolsSwift
import LarkBizAvatar

final class RedPacketHistoryTableViewCell: UITableViewCell {

    private let avatarImageView = RedPacketCommonAvatar()
    private let avatarSize: CGFloat = 40
    private let stackView = UIStackView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let moneyLabel = UILabel()
    private let statusLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(avatarImageView)
        contentView.addSubview(stackView)
        contentView.addSubview(moneyLabel)
        contentView.addSubview(statusLabel)

        avatarImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }

        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .fill
        stackView.lu.softer()
        stackView.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(moneyLabel.snp.left)
            make.right.lessThanOrEqualTo(statusLabel.snp.left)
        }

        nameLabel.font = UIFont.systemFont(ofSize: 17)
        nameLabel.textColor = UIColor.ud.textTitle
        stackView.addArrangedSubview(nameLabel)

        timeLabel.textColor = UIColor.ud.textPlaceholder
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        stackView.addArrangedSubview(timeLabel)

        moneyLabel.textColor = UIColor.ud.textTitle
        moneyLabel.font = UIFont.systemFont(ofSize: 17)
        moneyLabel.lu.harder()
        moneyLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(nameLabel)
            make.right.equalToSuperview().offset(-16)
        }

        statusLabel.textColor = UIColor.ud.textPlaceholder
        statusLabel.font = UIFont.systemFont(ofSize: 12)
        statusLabel.lu.harder()
        statusLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(timeLabel)
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(record: RedPacketReceviedSentRecord) {
        if let companyLogoPassThrough = record.companyLogoPassThrough {
            avatarImageView.avatarType = .company(passThrough: companyLogoPassThrough)
        } else {
            avatarImageView.avatarType = .user(identifier: record.avatarId,
                                               avatarKey: record.avatarKey,
                                               avatarViewParams: .init(sizeType: .size(avatarSize)))
        }
        nameLabel.text = record.displayName
        timeLabel.text = record.date.format(with: "MM-dd")
        moneyLabel.text = String(format: BundleI18n.LarkFinance.Lark_Legacy_HongbaoHistoryYuan, Float(record.sum) / 100.0)
        statusLabel.text = record.description
    }
}
