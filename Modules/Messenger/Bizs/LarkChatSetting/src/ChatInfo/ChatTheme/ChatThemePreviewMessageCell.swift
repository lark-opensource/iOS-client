//
//  ChatThemeMessageCell.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2022/12/27.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import ByteWebImage
import LarkMessageCore
import UniverseDesignColor

struct ChatThemePreviewMessageItem: ChatThemePreviewItem {
    var cellIdentifier: String

    var content: String
    var nameAndDesc: String
    var isFromMe: Bool
    var avatarKey: String?
    var image: UIImage?
    var userId: String
    var config: ChatThemePreviewConfig
    var componentTheme: ChatComponentTheme
}

class ChatThemePreviewMessageBaseCell: ChatThemePreviewBaseCell {
    fileprivate let avatar: ByteImageView = {
        let image = ByteImageView()
        image.layer.cornerRadius = 15
        image.layer.masksToBounds = true
        return image
    }()
    fileprivate let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    fileprivate let nameAndDescLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
    fileprivate lazy var readStatusButton: ReadStatusButton = {
        let btn = ReadStatusButton()
        btn.trackColor = UDMessageColorTheme.imMessageIconRead
        btn.defaultColor = UDMessageColorTheme.imMessageIconUnread
        return btn
    }()
    fileprivate let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.numberOfLines = 0
        return label
    }()

    override func setCellInfo() {
        guard let item = item as? ChatThemePreviewMessageItem else { return }
        if let key = item.avatarKey {
            self.avatar.bt.setLarkImage(with: .avatar(key: key, entityID: item.userId))
        } else if let img = item.image {
            self.avatar.bt.setLarkImage(with: .default(key: ""),
                                        placeholder: img)
        }
        titleLabel.text = item.content
        nameAndDescLabel.text = item.nameAndDesc
        let nameColor = item.componentTheme.nameAndDescColor
        nameAndDescLabel.textColor = ChatThemePreviewColorManger.getColor(color: nameColor, config: item.config)
        let bubbleViewColor = item.isFromMe ? UDMessageColorTheme.imMessageBgBubblesBlue : UDMessageColorTheme.imMessageBgBubblesGrey
        readStatusButton.isHidden = !item.isFromMe
        bubbleView.backgroundColor = ChatThemePreviewColorManger.getColor(color: bubbleViewColor, config: item.config)
        titleLabel.textColor = ChatThemePreviewColorManger.getColor(color: UIColor.ud.textTitle, config: item.config)
    }
}

class ChatThemePreviewMessageCell: ChatThemePreviewMessageBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        contentView.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalToSuperview()
            make.width.height.equalTo(30)
        }
        avatar.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(nameAndDescLabel)
        nameAndDescLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(18)
            make.left.equalTo(avatar.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        contentView.addSubview(bubbleView)
        bubbleView.snp.makeConstraints { make in
            make.bottom.equalTo(-20)
            make.left.equalTo(nameAndDescLabel)
            make.top.equalTo(nameAndDescLabel.snp.bottom).offset(4)
        }
        bubbleView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(24).priority(.required)
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
        }
        contentView.addSubview(readStatusButton)
        readStatusButton.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.left.equalTo(bubbleView.snp.right).offset(4)
            make.right.lessThanOrEqualToSuperview()
            make.bottom.equalTo(bubbleView)
        }
        readStatusButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        readStatusButton.update(percent: 1)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ChatThemePreviewMessageReverseCell: ChatThemePreviewMessageBaseCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        contentView.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.right.equalTo(-16)
            make.width.height.equalTo(30)
        }
        contentView.addSubview(bubbleView)
        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(-20)
            make.right.equalTo(avatar.snp.left).offset(-8)
        }
        bubbleView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(24).priority(.required)
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
        }
        contentView.addSubview(readStatusButton)
        readStatusButton.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.right.equalTo(bubbleView.snp.left).offset(-4)
            make.bottom.equalTo(bubbleView)
        }
        readStatusButton.update(percent: 1)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
