//
//  ReactionDetailTableViewCell.swift
//  LarkChat
//
//  Created by kongkaikai on 2018/12/12.
//

import Foundation
import UIKit
import LarkTag
import LarkUIKit
import UniverseDesignColor
import LarkBizAvatar

final class ReactionDetailTableViewCell: UITableViewCell {

    var chatterInfo: CalendarReactoinChatterInfo? {
        didSet {
            guard let chatterInfo = chatterInfo else { return }
            self.avatarView.image = nil
            self.nameLabel.text = chatterInfo.name
            self.statusLabel.set(
                description: chatterInfo.description,
                showIcon: true
            )

            self.avatarView.setAvatarByIdentifier(chatterInfo.chatterId, avatarKey: chatterInfo.avatarKey,
                                                  avatarViewParams: .init(sizeType: .size(48)))
        }
    }

    private let avatarView = LarkMedalAvatar()
    private let nameLabel = UILabel()
    private let statusLabel = ChatterStatusLabel()
    private let bottomLine = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(bottomLine)

        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 24
        avatarView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(48)
            maker.top.bottom.equalToSuperview().inset(10)
            maker.left.equalToSuperview().inset(16)
        }

        nameLabel.font = UIFont.systemFont(ofSize: 18)
        nameLabel.textColor = UIColor.ud.N900
        nameLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(avatarView.snp.right).offset(12)
        }

        statusLabel.isHidden = true
        statusLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(nameLabel.snp.right).offset(8)
            maker.right.lessThanOrEqualToSuperview().inset(8)
        }

        bottomLine.backgroundColor = UIColor.ud.N300
        bottomLine.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().inset(76)
            maker.right.bottom.equalToSuperview()
            maker.height.equalTo(0.5)
        }

        selectedBackgroundView = BaseCellSelectView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
