//
//  File.swift
//  Lark
//
//  Created by ChalrieSu on 2018/7/18.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkBizAvatar

final class AvatarWithBottomNameCollectionViewCell: UICollectionViewCell {
    private let avatarView = BizAvatar()
    private let avatarSize: CGFloat = 50
    private let nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.font = UIFont.systemFont(ofSize: 12)
        nameLabel.textColor = UIColor.ud.N500
        self.contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(avatarView)
            make.top.equalTo(avatarView.snp.bottom).offset(8)
            make.width.lessThanOrEqualTo(avatarView.snp.width)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(_ avatarKey: String, entityId: String, userName: String) {
        avatarView.setAvatarByIdentifier(entityId, avatarKey: avatarKey, scene: .Chat, avatarViewParams: .init(sizeType: .size(avatarSize)))
        self.nameLabel.text = userName
    }
}

final class ShowMoreCollectionViewCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let countLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(imageView)
        imageView.layer.cornerRadius = 25
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = UIColor.ud.bgFiller
        imageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(50)
        }

        countLabel.lineBreakMode = .byTruncatingTail
        countLabel.font = UIFont.systemFont(ofSize: 12)
        countLabel.textColor = UIColor.ud.textCaption
        self.contentView.addSubview(countLabel)
        countLabel.snp.makeConstraints { (make) in
            make.center.equalTo(imageView)
        }

        descriptionLabel.lineBreakMode = .byTruncatingTail
        descriptionLabel.font = UIFont.systemFont(ofSize: 12)
        descriptionLabel.textColor = UIColor.ud.N500
        self.contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(imageView)
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.width.lessThanOrEqualTo(imageView.snp.width)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(count: String, description: String) {
        self.countLabel.text = count
        self.descriptionLabel.text = description
    }
}
