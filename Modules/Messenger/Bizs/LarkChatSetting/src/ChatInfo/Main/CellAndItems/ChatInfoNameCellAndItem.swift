//
//  ChatInfoNameCellAndItem.swift
//  Lark
//
//  Created by K3 on 2018/8/9.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore
import LarkTag
import LarkMessengerInterface
import LarkFeatureSwitch
import LarkBizAvatar

// MARK: - 群信息 - item
struct ChatInfoNameModel: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var avatarKey: String
    var entityId: String
    var name: String
    var nameTagTypes: [TagType]
    var description: String
    var canBeShared: Bool
    var showEditIcon: Bool
    var showCryptoIcon: Bool
    var showArrow: Bool
    var avatarTapHandler: ChatInfoAvatarEditHandler
    var tapHandler: ChatInfoTapHandler
    //需求自定义布局时定义下面属性
    var avatarLayout: ((ConstraintMaker) -> Void)?
    var infoAndQRCodeStackLayout: ((ConstraintMaker) -> Void)?
    var nameLabelFont: UIFont?
}

// MARK: - 群信息 - cell
final class ChatInfoNameCell: ChatInfoCell {
    private var avatarImageView = BizAvatar()
    private let avatarSize: CGFloat = 48
    private var tagView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.icon_tag_crypto
        return imageView
    }()

    private var infoAndQRCodeStack = UIStackView()
    private var nameAndDescriptionStack = UIStackView()
    private var nameAndTagStack = UIStackView()

    private var nameLabel = UILabel()
    private var nameTagView = TagWrapperView()
    private var descriptionLabel = UILabel()
    private var qrcodeImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(tagView)
        contentView.addSubview(infoAndQRCodeStack)

        infoAndQRCodeStack.axis = .horizontal
        infoAndQRCodeStack.spacing = 6
        infoAndQRCodeStack.alignment = .center
        infoAndQRCodeStack.distribution = .fill
        infoAndQRCodeStack.addArrangedSubview(nameAndDescriptionStack)
        infoAndQRCodeStack.addArrangedSubview(qrcodeImageView)
        infoAndQRCodeStack.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 76, bottom: 17, right: 34))
            maker.height.greaterThanOrEqualTo(68 - 12 - 14)
        }

        nameAndDescriptionStack.axis = .vertical
        nameAndDescriptionStack.spacing = 1
        nameAndDescriptionStack.alignment = .leading
        nameAndDescriptionStack.distribution = .fill
        nameAndDescriptionStack.addArrangedSubview(nameAndTagStack)
        nameAndDescriptionStack.addArrangedSubview(descriptionLabel)

        nameAndTagStack.axis = .horizontal
        nameAndTagStack.spacing = 6
        nameAndTagStack.alignment = .center
        nameAndTagStack.distribution = .fill
        nameAndTagStack.addArrangedSubview(nameLabel)
        nameAndTagStack.addArrangedSubview(nameTagView)

        avatarImageView.snp.makeConstraints { (maker) in
            maker.top.left.bottom.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 0))
            maker.width.height.equalTo(avatarSize)
        }
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                                     action: #selector(avatarTap)))

        tagView.snp.makeConstraints { (make) in
            make.bottom.right.equalTo(avatarImageView)
            make.width.height.equalTo(16)
        }

        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.numberOfLines = 1
        nameTagView.setContentCompressionResistancePriority(.required, for: .horizontal)

        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = UIColor.ud.textPlaceholder
        descriptionLabel.snp.makeConstraints { (maker) in
            maker.height.equalTo(20)
        }

        self.qrcodeImageView.image = Resources.group_er_code.ud.withTintColor(UIColor.ud.iconN3)
        self.qrcodeImageView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let nameItem = item as? ChatInfoNameModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        avatarImageView.setAvatarByIdentifier(nameItem.entityId, avatarKey: nameItem.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        tagView.isHidden = !nameItem.showCryptoIcon
        nameLabel.text = nameItem.name
        // 过滤掉密聊icon, 避免重复展示
        let tags = nameItem.nameTagTypes.filter({ $0 != .crypto })
        nameTagView.setTags(tags)

        descriptionLabel.text = nameItem.description
        descriptionLabel.isHidden = nameItem.description.isEmpty

        if nameItem.canBeShared {
            qrcodeImageView.isHidden = false
        } else {
            qrcodeImageView.isHidden = true
        }
        arrow.isHidden = !nameItem.showArrow
        layoutSeparater(nameItem.style)
        descriptionLabel.textColor = UIColor.ud.textPlaceholder
        if let avatarLayout = nameItem.avatarLayout {
            resetAvatarLayout(avatarLayout)
        }
        if let infoAndQRCodeStackLayout = nameItem.infoAndQRCodeStackLayout {
            resetInfoAndQRCodeStackLayout(infoAndQRCodeStackLayout)
        }
        if let nameLabelFont = nameItem.nameLabelFont {
            nameLabel.font = nameLabelFont
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let infoItem = self.item as? ChatInfoNameModel {
            infoItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }

    @objc
    private func avatarTap() {
        guard let infoItem = self.item as? ChatInfoNameModel else { return }
        infoItem.avatarTapHandler()
    }

    private func resetAvatarLayout(_ layout: ((ConstraintMaker) -> Void)) {
        avatarImageView.snp.remakeConstraints(layout)
    }

    private func resetInfoAndQRCodeStackLayout(_ layout: ((ConstraintMaker) -> Void)) {
        infoAndQRCodeStack.snp.remakeConstraints(layout)
    }
}
