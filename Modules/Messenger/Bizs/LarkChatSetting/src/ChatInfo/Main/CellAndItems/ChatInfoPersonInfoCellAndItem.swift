//
//  ChatInfoPersonInfoCellAndItem.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/2/2.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore
import LarkBizAvatar

// MARK: - 单聊信息 - item
struct ChatInfoPersonInfoItem: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var avatarKey: String
    var medalKey: String
    var entityId: String
    var name: String
    var showCryptoIcon: Bool
    var showAddButton: Bool
    var addButtonTapHandler: () -> Void
    var avatarTapHandler: () -> Void
}

// MARK: - 单聊信息 - cell
final class ChatInfoPersonInfoCell: ChatInfoCell {
    private var avatarImageView = LarkMedalAvatar()
    private let avatarSize: CGFloat = 48
    private var tagView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.icon_tag_crypto
        return imageView
    }()

    private var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 2
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private var addButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(Resources.icon_personInfo_add, for: .normal)
        button.setImage(Resources.icon_personInfo_add, for: .selected)
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        contentView.addSubview(avatarImageView)
        contentView.addSubview(tagView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(addButton)

        avatarImageView.snp.makeConstraints { (maker) in
            maker.top.left.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 0, right: 0))
            maker.width.height.equalTo(avatarSize)
        }
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))

        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(avatarImageView.snp.bottom)
            make.centerX.equalTo(avatarImageView.snp.centerX)
            make.width.equalTo(58)
            make.bottom.equalTo(-16)
        }

        tagView.snp.makeConstraints { (make) in
            make.bottom.right.equalTo(avatarImageView)
            make.width.height.equalTo(16)
        }

        addButton.snp.makeConstraints { (make) in
            make.top.equalTo(avatarImageView.snp.top)
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.width.height.equalTo(48)
        }
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        arrow.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let nameItem = item as? ChatInfoPersonInfoItem else {
            assert(false, "\(self):item.Type error")
            return
        }

        avatarImageView.setAvatarByIdentifier(nameItem.entityId,
                                              avatarKey: nameItem.avatarKey,
                                              medalKey: nameItem.medalKey,
                                              medalFsUnit: "",
                                              scene: .Chat,
                                              avatarViewParams: .init(sizeType: .size(avatarSize)))
        tagView.isHidden = !nameItem.showCryptoIcon
        addButton.isHidden = !nameItem.showAddButton
        nameLabel.text = nameItem.name
        layoutSeparater(nameItem.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    @objc
    private func addButtonTapped() {
        guard let infoItem = self.item as? ChatInfoPersonInfoItem else { return }
        infoItem.addButtonTapHandler()
    }

    @objc
    private func avatarTapped() {
        guard let infoItem = self.item as? ChatInfoPersonInfoItem else { return }
        infoItem.avatarTapHandler()
    }
}
