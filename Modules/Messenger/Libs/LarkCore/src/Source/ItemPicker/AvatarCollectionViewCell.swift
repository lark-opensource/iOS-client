//
//  AvatarCollectionViewCell.swift
//  Lark
//
//  Created by zc09v on 2017/5/12.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkAvatar
import LarkBizAvatar

public final class AvatarCollectionViewCell: UICollectionViewCell {
    var avatarView: LarkMedalAvatar!
    private let threadTopicIcon = UIImageView()
    private let kSelectedMemberAvatarSize: CGFloat = 30.0

    override init(frame: CGRect) {
        super.init(frame: frame)

        avatarView = LarkMedalAvatar(frame: self.bounds)
        self.contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })

        threadTopicIcon.image = Resources.thread_topic
        threadTopicIcon.isHidden = true
        self.contentView.addSubview(threadTopicIcon)
        threadTopicIcon.snp.makeConstraints { (make) in
            make.bottom.equalTo(avatarView.snp.bottom)
            make.trailing.equalTo(avatarView.snp.trailing)
            make.size.equalTo(CGSize(width: 18, height: 18))
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setContent(_ avatarKey: String,
                           medalKey: String,
                           id: String,
                           showThreadTopicIcon: Bool = false) {
        self.avatarView.setAvatarByIdentifier(id,
                                              avatarKey: avatarKey,
                                              medalKey: medalKey,
                                              medalFsUnit: "",
                                              scene: .Forward)
        self.threadTopicIcon.isHidden = true
        self.threadTopicIcon.isHidden = !showThreadTopicIcon
    }
}

public final class AvatarWithRightNameCollectionViewCell: UICollectionViewCell {
    var avatarView: BizAvatar = .init(frame: .zero)
    var nameLabel: UILabel = .init()
    private lazy var arrowIcon: UIImageView = {
        let arrowIcon = UIImageView(image: Resources.right_arrow)
        arrowIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrowIcon.setContentHuggingPriority(.required, for: .horizontal)
        return arrowIcon
    }()

    private lazy var thumbnailAvatarView: BizAvatar = {
        let avatarView = BizAvatar()
        avatarView.isHidden = true
        return avatarView
    }()

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
        self.contentView.addSubview(arrowIcon)
        nameLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(avatarView)
            make.leading.equalTo(avatarView.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(arrowIcon.snp.leading).offset(-12)
        }
        arrowIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        let width = avatarSize / 2.0 - 1
        self.avatarView.addSubview(thumbnailAvatarView)
        thumbnailAvatarView.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview()
            make.size.equalTo(CGSize(width: width, height: width))
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setContent(_ avatarKey: String, id: String, userName: String, image: UIImage?, avatarErrorHandler: ((Error) -> Void)? = nil) {
        self.thumbnailAvatarView.isHidden = image == nil
        if let image = image {
            self.avatarView.setAvatarByIdentifier("0", avatarKey: "")
            self.avatarView.image = image
            self.thumbnailAvatarView.image = nil
            self.thumbnailAvatarView.setAvatarByIdentifier(id, avatarKey: avatarKey,
                                                           scene: .Forward,
                                                           avatarViewParams: .init(sizeType: .size(19))) {
                if case let .failure(error) = $0 {
                    avatarErrorHandler?(error)
                }
            }
        } else {
            self.avatarView.image = nil
            self.avatarView.setAvatarByIdentifier(id, avatarKey: avatarKey,
                                                  scene: .Forward,
                                                  avatarViewParams: .init(sizeType: .size(avatarSize))) {
                if case let .failure(error) = $0 {
                    avatarErrorHandler?(error)
                }
            }
        }
        self.nameLabel.text = userName
    }

    public func showArrowIcon(_ shouldShow: Bool) {
        self.arrowIcon.isHidden = !shouldShow
    }
}
