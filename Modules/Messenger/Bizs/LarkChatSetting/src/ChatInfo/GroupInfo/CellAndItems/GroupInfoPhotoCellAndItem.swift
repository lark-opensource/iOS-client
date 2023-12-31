//
//  GroupInfoPhotoCellAndItem.swift
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
import LarkBizAvatar

// MARK: - 群头像 - item
struct GroupInfoPhotoItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var chatID: String
    var avatarKey: String
    var isTapEnabled: Bool
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 群头像 - cell
final class GroupInfoPhotoCell: GroupSettingCell {
    private let avatarSize: CGFloat = 48
    var avatarView: BizAvatar = .init(frame: .zero)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 23, left: 16, bottom: 22.5, right: 100))
            maker.height.equalTo(22.5).priority(.high)
        }

        avatarView = BizAvatar()
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (maker) in
            maker.top.right.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 40))
            maker.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
        }

        defaultLayoutArrow()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupInfoPhotoItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.isUserInteractionEnabled = item.isTapEnabled
        titleLabel.text = item.title
        avatarView.setAvatarByIdentifier(item.chatID, avatarKey: item.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        arrow.isHidden = !item.isTapEnabled
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let infoItem = self.item as? GroupInfoPhotoItem {
            infoItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
