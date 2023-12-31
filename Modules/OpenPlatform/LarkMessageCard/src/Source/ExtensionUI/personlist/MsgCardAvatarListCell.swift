//
//  MsgCardAvartarList.swift
//  LarkMessageCard
//
//  Created by ByteDance on 2023/6/22.
//

import Foundation
import UIKit
import LarkBizAvatar
import AppReciableSDK
fileprivate struct AvatarStyle {
    static let avatarSize: CGFloat = 40
    static let avatarOffset: CGFloat = 16
    static let titleLeading: CGFloat = 12
}
final class MsgCardAvatarListCell: UITableViewCell {
    lazy var avatar: BizAvatar = {
        let avatar = BizAvatar()
        avatar.layer.cornerRadius = AvatarStyle.avatarSize / 2
        avatar.avatar.clipsToBounds = true
        avatar.backgroundColor = UIColor.ud.N300
        return avatar
    }()

    lazy var title: UILabel = {
        let title = UILabel(frame: .zero)
        title.textColor = UIColor.ud.textTitle
        title.font = UIFont.systemFont(ofSize: 16)
        title.numberOfLines = 1
        title.lineBreakMode = .byTruncatingTail
        return title
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(AvatarStyle.avatarOffset)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(AvatarStyle.avatarSize)
        }

        contentView.addSubview(title)
        title.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(avatar.snp.trailing).offset(AvatarStyle.titleLeading)
            make.trailing.lessThanOrEqualToSuperview().offset(-AvatarStyle.avatarOffset)
        }
    }

    func update(person: Person) {
        avatar.setAvatarByIdentifier(person.id ?? "", avatarKey: person.avatarKey ?? "", placeholder: BundleResources.LarkMessageCard.universal_card_avatar)
        title.text = person.content ?? BundleI18n.LarkMessageCard.OpenPlatform_CardCompt_UnknownUser
    }
}

