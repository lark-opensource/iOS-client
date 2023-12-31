//
//  LKReadListCell.swift
//  LarkChat
//
//  Created by zhenning on 2002/02/05.
//  Copyright © 2020年. All rights reserved.
//

import Foundation
import UIKit
import LarkCore
import SnapKit
import LarkTag
import LarkUIKit
import ByteWebImage
import LarkBizAvatar

final class LKReadListCell: UITableViewCell {
    private let avatarWH: CGFloat = 32
    private let iconWH: CGFloat = 14

    class var identifier: String {
        return String(describing: LKReadListCell.self)
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
        label.font = UIFont.systemFont(ofSize: 17)
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

    private var isTagViewShow: Bool = true
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectedBackgroundView = BaseCellSelectView()
        self.contentView.backgroundColor = UIColor.ud.bgBody

        self.contentView.addSubview(avatarView)
        self.avatarView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
            make.size.equalTo(CGSize(width: self.avatarWH, height: self.avatarWH))
        }

        self.contentView.addSubview(nameLabel)
        self.nameLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(self.avatarView.snp.right).offset(12)
            make.right.lessThanOrEqualTo(tagView.snp.left).offset(-10)
        }
        // 设置名称容易被压缩
        self.nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

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

            tagView.setTags([isUnread ? .unread : .read])
        }

    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if isTagViewShow {
            tagView.isHidden = true
        }
    }

}
