//
//  ChatInfoTeamItemCellView.swift
//  LarkTeam
//
//  Created by chaishenghua on 2022/11/14.
//

import UIKit
import Foundation
import LarkBizAvatar
import LarkOpenChat

class ChatInfoTeamItemCellView: UIView {
    private let avatarView: BizAvatar
    private let titleLabel: UILabel
    private let subTitleLabel: UILabel
    private let moreButton: EnlargeButton
    private var item: ChatInfoTeamItem?

    override init(frame: CGRect) {
        self.avatarView = BizAvatar()
        self.titleLabel = UILabel()
        self.subTitleLabel = UILabel()
        self.moreButton = EnlargeButton(type: .custom)
        super.init(frame: frame)

        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textTitle

        subTitleLabel.font = UIFont.systemFont(ofSize: 12)
        subTitleLabel.textColor = UIColor.ud.textCaption

        moreButton.largeEdge = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        moreButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        moreButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        moreButton.addTarget(self, action: #selector(click(_:)), for: .touchUpInside)

        self.addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(8)
            make.width.height.equalTo(32)
            make.bottom.equalToSuperview().inset(8)
        }

        self.addSubview(moreButton)
        moreButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(avatarView)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(16)
        }

        self.addSubview(titleLabel)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(avatarView)
            make.left.equalTo(avatarView.snp.right).offset(10)
            make.right.lessThanOrEqualTo(moreButton.snp.left).offset(-16)
        }

        self.addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.equalTo(titleLabel)
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateAvailableMaxWidth(_ width: CGFloat) {}

    func setCellInfo(item: ChatInfoTeamItem) {
        self.item = item
        moreButton.item = item
        avatarView.setAvatarByIdentifier(
            item.entityIdForAvatar,
            avatarKey: item.avatarKey,
            scene: .Chat,
            avatarViewParams: .init(sizeType: .size(32)),
            completion: nil)
        titleLabel.text = item.title
        subTitleLabel.isHidden = !item.showSubTitle
        if subTitleLabel.isHidden {
            titleLabel.snp.updateConstraints { (make) in
                make.centerY.equalTo(avatarView)
            }
        } else {
            titleLabel.snp.updateConstraints { (make) in
                make.centerY.equalTo(avatarView).offset(-8)
            }
        }
        subTitleLabel.text = item.subTitle
        moreButton.isHidden = false
        moreButton.setImage(nil, for: .normal)
        moreButton.setTitle(nil, for: .normal)
        if item.showMore {
            moreButton.setImage(Resources.icon_more_outlinedN2, for: .normal)
            moreButton.snp.remakeConstraints { (make) in
                make.centerY.equalTo(avatarView)
                make.right.equalToSuperview().offset(-16)
                make.width.height.equalTo(16)
            }
        } else {
            moreButton.isHidden = true
            moreButton.snp.remakeConstraints { (make) in
                make.centerY.equalTo(avatarView)
                make.right.equalToSuperview().offset(-16)
            }
        }
    }

    @objc
    private func click(_ sender: UIButton) {
        guard let item = item else { return }
        if item.showMore {
            item.tapHandler(item, self)
        }
    }
}
