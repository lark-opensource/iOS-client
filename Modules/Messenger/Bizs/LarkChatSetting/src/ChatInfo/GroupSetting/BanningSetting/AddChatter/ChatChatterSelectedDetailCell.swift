//
//  ChatChatterItem.swift
//  LarkChat
//
//  Created by kkk on 2019/3/14.
//

import Foundation
import UIKit
import LarkCore
import LarkButton
import LarkUIKit
import LarkBizAvatar

final class ChatChatterSelectedDetailCell: UITableViewCell {
    private let avaterView = BizAvatar()
    private let avatarSize: CGFloat = 48
    private let nameLabel = UILabel()
    private let removeButton = IconButton(icon: Resources.member_select_cancel)
    private var separator: UIView?

    var item: ChatChatterItem? {
        didSet {
            if let item = item {
                avaterView.setAvatarByIdentifier(item.itemId,
                                                 avatarKey: item.itemAvatarKey,
                                                 scene: .Chat,
                                                 avatarViewParams: .init(sizeType: .size(avatarSize)))
                nameLabel.text = item.itemName
            }
        }
    }

    var onRemove: ((_ item: ChatChatterItem?) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // 头像
        contentView.addSubview(avaterView)
        avaterView.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
            make.centerY.equalToSuperview()
            make.left.equalTo(15)
        })

        // 名字
        nameLabel.textColor = UIColor.ud.N900
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        self.contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints({ make in
            make.centerY.equalToSuperview()
            make.left.equalTo(avaterView.snp.right).offset(15)
            make.right.equalTo(15)
        })

        removeButton.addTarget(self, action: #selector(removeTap), for: .touchUpInside)
        contentView.addSubview(removeButton)
        removeButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalTo(28)
        }

        separator = contentView.lu.addBottomBorder(leading: nameLabel.snp.left)
        selectedBackgroundView = BaseCellSelectView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func removeTap() {
        onRemove?(item)
    }
}
