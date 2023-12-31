//
//  GroupInfoQRCodeCellAndItem.swift
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

// MARK: - 群二维码 - item
struct GroupInfoQRCodeItem: GroupSettingItemProtocol {
    var type: CommonCellItemType
    var cellIdentifier: String
    var style: SeparaterStyle
    var title: String
    var isShowIcon: Bool = true
    var tapHandler: ChatInfoTapHandler
}

// MARK: - 群二维码 - cell
final class GroupInfoQRCodeCell: GroupSettingCell {
    var qrImage: UIImageView = .init(image: nil)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview().inset(UIEdgeInsets(top: 13, left: 16, bottom: 12.5, right: 65))
            maker.height.equalTo(22.5).priority(.high)
        }

        qrImage = UIImageView(image: Resources.group_er_code.ud.withTintColor(UIColor.ud.iconN3))
        contentView.addSubview(qrImage)
        qrImage.snp.makeConstraints { (maker) in
            maker.top.right.equalToSuperview().inset(UIEdgeInsets(top: 14, left: 0, bottom: 0, right: 35))
            maker.size.equalTo(CGSize(width: 20, height: 20))
        }

        defaultLayoutArrow()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? GroupInfoQRCodeItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.text = item.title
        qrImage.isHidden = !item.isShowIcon
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let item = self.item as? GroupInfoQRCodeItem {
            item.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}

typealias GroupInfoChatBgImageCell = GroupInfoQRCodeCell
typealias GroupInfoChatBgImageItem = GroupInfoQRCodeItem
