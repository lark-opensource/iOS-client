//
//  ReadListViewCell.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/3/30.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkCore
import SnapKit
import LarkTag
import LarkUIKit
import ByteWebImage
import LarkBizAvatar

final class ReadListViewCell: UITableViewCell {
    private let avatarWH: CGFloat = 48
    private let iconWH: CGFloat = 16

    class var identifier: String {
        return String(describing: ReadListViewCell.self)
    }

    lazy var avatarView: BizAvatar = {
        let avatar = BizAvatar()
        avatar.backgroundColor = UIColor.ud.N300
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = CGFloat(self.avatarWH / 2)
        avatar.layer.masksToBounds = true
        return avatar
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.N900
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    lazy var atIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private var isTagViewShow: Bool = false
    lazy var tagView: TagWrapperView = {
        let tag = TagWrapperView()
        contentView.addSubview(tag)
        tag.snp.makeConstraints {
            $0.right.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }
        isTagViewShow = true
        return tag
    }()

    var statusLablel: ChatterStatusLabel = ChatterStatusLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectedBackgroundView = BaseCellSelectView()
        self.contentView.backgroundColor = UIColor.ud.bgBody
        self.contentView.lu.addBottomBorder(leading: 76, trailing: 0, color: UIColor.ud.commonTableSeparatorColor)

        self.contentView.addSubview(avatarView)
        self.avatarView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
            make.size.equalTo(CGSize(width: self.avatarWH, height: self.avatarWH))
        }

        self.contentView.addSubview(nameLabel)
        self.nameLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(76)
            make.right.lessThanOrEqualTo(-16)
        }

        self.contentView.addSubview(self.statusLablel)
        self.statusLablel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-24)
            make.centerY.equalTo(nameLabel)
        }
        self.statusLablel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        self.statusLablel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        self.contentView.addSubview(atIcon)
        self.atIcon.snp.makeConstraints { (make) in
            make.bottom.right.equalTo(self.avatarView)
            make.size.equalTo(CGSize(width: self.iconWH, height: self.iconWH))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUI(_ cellViewModel: ReadListCellViewModel) {
        let name = cellViewModel.chatterDisplayName()
        if let filterKey = cellViewModel.filterKey {
            self.nameLabel.attributedText = name.lu.stringWithHighlight(
                highlightText: filterKey,
                pinyinOfString: cellViewModel.chatter.namePinyin,
                normalColor: UIColor.ud.N900)
        } else {
            self.nameLabel.text = name
        }
        self.atIcon.image = cellViewModel.rightIcon
        self.avatarView.setAvatarByIdentifier(cellViewModel.chatter.id,
                                              avatarKey: cellViewModel.chatter.avatarKey,
                                              scene: .Chat,
                                              avatarViewParams: .init(sizeType: .size(avatarWH)))

        if let isUnread = cellViewModel.isUnread {
            tagView.isHidden = false

            statusLablel.snp.remakeConstraints { (make) in
                make.left.equalTo(nameLabel.snp.right).offset(8)
                make.right.lessThanOrEqualTo(tagView.snp.left).offset(-8)
                make.centerY.equalTo(nameLabel)
            }
            tagView.setTags([isUnread ? .unread : .read])
        }

        let description = cellViewModel.chatter.description_p
        self.statusLablel.set(description: description.text, descriptionType: description.type)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if isTagViewShow {
            tagView.isHidden = true

            statusLablel.snp.remakeConstraints { (make) in
                make.left.equalTo(nameLabel.snp.right).offset(8)
                make.right.lessThanOrEqualToSuperview().offset(-24)
                make.centerY.equalTo(nameLabel)
            }
        }
    }
}
