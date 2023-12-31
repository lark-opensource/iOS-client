//
//  MeetingCreatorCell.swift
//  Calendar
//
//  Created by harry zou on 2019/4/22.
//

import UIKit
import CalendarFoundation
import LarkBizAvatar
import UniverseDesignIcon
final class MeetingCreatorCell: UIControl {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.cd.regularFont(ofSize: 16)
        label.numberOfLines = 1
        return label
    }()

    let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.memberOutlined).renderColor(with: .n3))

    let tailImage = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.rightOutlined).renderColor(with: .n3))

    let avatarView = AvatarView()

    let seizeableTag = TagViewProvider.booker()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layout(imageView: imageView)
        layout(avatarView: avatarView, leadingView: imageView)
        layout(titleView: titleLabel, leadingView: avatarView)
        layout(tag: seizeableTag, leadingView: titleLabel)
        layout(tail: tailImage)
        addBottomBorder(inset: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0), lineHeight: 1)
    }

    private func layout(tail: UIView) {
        addSubview(tail)
        tail.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(13)
        }
    }

    func layout(imageView: UIImageView) {
        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.leading.equalToSuperview().offset(16)
        }
    }

    func layout(avatarView: UIView, leadingView: UIView) {
        addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(32)
            make.leading.equalTo(leadingView.snp.trailing).offset(15)
        }
    }

    func layout(titleView: UILabel, leadingView: UIView) {
        addSubview(titleView)
        titleView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.leading.equalTo(leadingView.snp.trailing).offset(8)
        }
    }

    func layout(tag: UIView, leadingView: UIView) {
        addSubview(tag)
        tag.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(leadingView.snp.trailing).offset(6)
            make.trailing.lessThanOrEqualToSuperview().offset(-12)
        }
    }

    func update(creatorEntity: CreatorEntity) {
        avatarView.setAvatar(creatorEntity, with: 32)
        titleLabel.text = creatorEntity.userName
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
