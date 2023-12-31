//
//  TeamAvatarConfigCell.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/8/9.
//

import UIKit
import Foundation
import LarkUIKit
import LarkBizAvatar

typealias TapAvatarHandler = () -> Void

struct TeamAvatarConfigViewModel: TeamCellViewModelProtocol {
    var type: TeamCellType
    var cellIdentifier: String
    var style: TeamCellSeparaterStyle
    var entityId: String
    var avatarKey: String
    var avatarImage: UIImage? /// 优先使用 UIImage
    var title: String
    var tapAvatarHandler: TapAvatarHandler
}

// MARK: - 头像配置 - cell
final class TeamAvatarConfigCell: TeamBaseCell {
    private let avatarSize = CGSize(width: 80, height: 80)
    private let editIconSize = CGSize(width: 32, height: 32)

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()

    private lazy var avatar: BizAvatar = {
        let bizAvatar = BizAvatar()
        bizAvatar.avatar.layer.cornerRadius = self.avatarSize.width / 2
        return bizAvatar
    }()

    private lazy var editIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.icon_edit
        imageView.layer.cornerRadius = self.editIconSize.width / 2
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(13)
            make.right.equalTo(-16)
        }

        contentView.addSubview(avatar)
        avatar.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
            make.width.equalTo(avatarSize.width)
            make.height.equalTo(avatarSize.height)
            make.bottom.equalTo(-24)
        }
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapEvent)))

        contentView.addSubview(editIcon)
        editIcon.snp.makeConstraints { (make) in
            make.right.bottom.equalTo(avatar)
            make.width.equalTo(editIconSize.width)
            make.height.equalTo(editIconSize.height)
        }
        editIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapEvent)))
    }

    @objc
    func tapEvent() {
        guard let item = item as? TeamAvatarConfigViewModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        item.tapAvatarHandler()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? TeamAvatarConfigViewModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        if let avatarImage = item.avatarImage {
            avatar.image = avatarImage
        } else {
            avatar.setAvatarByIdentifier(item.entityId,
                                         avatarKey: item.avatarKey,
                                         avatarViewParams: .init(sizeType: .size(avatarSize.width)))
        }
        layoutSeparater(item.style)
    }
}
