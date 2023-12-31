//
//  AvatarListCell.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2022/7/29.
//

import Foundation
import UIKit
import LarkBizAvatar
import AppReciableSDK

final class AvatarListCell: UITableViewCell {
    static let avatarSize: CGFloat = 40
    lazy var avatar: BizAvatar = {
        let avatar = BizAvatar()
        avatar.layer.cornerRadius = Self.avatarSize / 2
        avatar.avatar.clipsToBounds = true
        avatar.backgroundColor = UIColor.ud.N300
        return avatar
    }()

    lazy var title: UILabel = {
        let title = UILabel(frame: .zero)
        title.textColor = UIColor.ud.textTitle
        title.font = UIFont.systemFont(ofSize: 16)
        title.numberOfLines = 1
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
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Self.avatarSize)
        }

        contentView.addSubview(title)
        title.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(avatar.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualToSuperview().offset(16)
        }
    }

    func update(info: ChatterInfo) {
        avatar.setAvatarByIdentifier(info.chatterID, avatarKey: info.avatarKey, scene: .Chat)
        title.text = info.name
    }
}
