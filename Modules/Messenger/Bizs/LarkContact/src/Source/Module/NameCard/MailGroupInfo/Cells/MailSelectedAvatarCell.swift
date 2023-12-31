//
//  MailSelectedAvatarCell.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/27.
//

import Foundation
import UIKit
import LarkAvatar
import LarkBizAvatar

public final class MailAvatarCollectionViewCell: UICollectionViewCell {
    var avatarView: BizAvatar = .init(frame: .zero)
    private let kSelectedMemberAvatarSize: CGFloat = 30.0

    override init(frame: CGRect) {
        super.init(frame: frame)

        avatarView = BizAvatar(frame: self.bounds)
        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setContent(_ avatarKey: String, id: String, avatarImage: UIImage?) {
        if let img = avatarImage {
            self.avatarView.image = avatarImage
        } else {
            self.avatarView.setAvatarByIdentifier(id, avatarKey: avatarKey, scene: .Forward)
        }
    }
}

public final class MailAvatarWithRightNameCollectionViewCell: UICollectionViewCell {
    var avatarView: BizAvatar = .init(frame: .zero)
    var nameLabel: UILabel = .init()
    private let avatarSize: CGFloat = 40
    override init(frame: CGRect) {
        super.init(frame: frame)

        let avatarView = BizAvatar()
        self.avatarView = avatarView
        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }
        let nameLabel = UILabel()
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        self.nameLabel = nameLabel
        self.contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(avatarView)
            make.left.equalTo(avatarView.snp.right).offset(15)
            make.right.lessThanOrEqualToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setContent(_ avatarKey: String, id: String, userName: String) {
        self.avatarView.setAvatarByIdentifier(id, avatarKey: avatarKey,
                                              scene: .Forward,
                                              avatarViewParams: .init(sizeType: .size(avatarSize)))
        self.nameLabel.text = userName
    }
}
