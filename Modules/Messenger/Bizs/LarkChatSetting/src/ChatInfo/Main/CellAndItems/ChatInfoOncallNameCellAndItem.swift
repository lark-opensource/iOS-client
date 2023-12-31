//
//  ChatInfoOncallNameCellAndItem.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/6/11.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkCore
import LarkBizAvatar

// MARK: - 群信息OnCall - item
struct ChatInfoOncallItem: CommonCellItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var avatarKey: String
    var entityId: String
    var name: String
}

// MARK: - 群信息OnCall - cell
final class ChatInfoOncallCell: ChatInfoCell {
    private var avatarImageView: BizAvatar
    private let avatarSize: CGFloat = 48
    private var nameLabel: UILabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        avatarImageView = BizAvatar()
        nameLabel = UILabel()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)

        avatarImageView.snp.makeConstraints { (maker) in
            maker.top.left.bottom.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 0))
            maker.width.height.equalTo(avatarSize)
        }

        nameLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(76)
            maker.height.equalTo(22.5)
            maker.right.equalTo(-40)
            maker.centerY.equalTo(avatarImageView)
        }

        arrow.isHidden = true

        // 不需要选中背景色
        self.selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let nameItem = item as? ChatInfoOncallItem else {
            assert(false, "\(self):item.Type error")
            return
        }

        avatarImageView.setAvatarByIdentifier(nameItem.entityId, avatarKey: nameItem.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        nameLabel.text = nameItem.name
        layoutSeparater(nameItem.style)
    }
}
