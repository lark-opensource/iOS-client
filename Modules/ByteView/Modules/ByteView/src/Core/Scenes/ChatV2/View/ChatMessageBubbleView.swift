//
//  ChatMessageBubbleView.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/4/26.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit
import RichLabel
import ByteViewNetwork
import ByteViewUI

protocol ChatMessageBubbleViewDelegate: AnyObject {
    func messageBubbleViewDidClick(item: ChatItem)
}

class ChatMessageBubbleView: UIView {
    weak var delegate: ChatMessageBubbleViewDelegate?

    private enum Layout {
        static let contentLineHeight: CGFloat = 18
    }

    private let avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private let avatar = AvatarView()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.staticWhite.withAlphaComponent(0.7)
        return label
    }()

    private let contentLabelHandler: ContentLabelHandler

    private let contentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.ud.vcTokenMeetingBgFeed
        return view
    }()

    private var chatItem: ChatItem = ChatItem(name: "", avatar: ChatAvatarView.Content.image(nil), content: NSAttributedString(string: ""), position: 0)

    init(isUseImChat: Bool) {
        contentLabelHandler = ContentLabelHandler(isUseImChat: isUseImChat)
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public
    func update(with item: ChatItem) {
        chatItem = item
        update(with: item.avatar, senderName: item.name, attributedText: item.content)
    }

    func update(with avatarInfo: ChatAvatarView.Content, senderName: String, attributedText: NSAttributedString) {
        switch avatarInfo {
        case .key(let key, let id, let backup):
            if !key.isEmpty {
                avatar.isHidden = false
                avatarView.isHidden = true
                avatar.setAvatarInfo(.remote(key: key, entityId: id))
            } else {
                avatarView.image = backup
                avatarView.isHidden = false
                avatar.isHidden = true
            }
        case .image(let image):
            avatarView.image = image
            avatarView.isHidden = false
            avatar.isHidden = true
        }
        nameLabel.attributedText = NSAttributedString(string: senderName, config: .tiniestAssist)
        contentLabelHandler.setAttributedText(attributedText)
        updateStyle()
    }

    func updateContentWidth(_ width: CGFloat) {
        contentLabelHandler.setPreferredMaxLayoutWidth(width - 40)
    }

    func updateStyle() {
        if Display.phone {
            contentLabelHandler.setNumberOfLines(isPhoneLandscape ? 2 : 5)
        } else if Display.pad {
            contentLabelHandler.setNumberOfLines(5)
        }
    }

    func prepareForReuse() {
        nameLabel.text = nil
        contentLabelHandler.setAttributedText(nil)
        chatItem = ChatItem(name: "", avatar: ChatAvatarView.Content.image(nil), content: NSAttributedString(string: ""), position: 0)
    }

    // MARK: - Private

    private func setupSubviews() {
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().inset(6)
            make.size.equalTo(20)
        }

        contentView.addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.edges.equalTo(avatarView)
        }

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(6)
            make.right.lessThanOrEqualToSuperview().inset(8)
            make.right.equalToSuperview().inset(8).priority(.medium)
            make.left.equalTo(avatarView.snp.right).offset(6)
            make.height.equalTo(13)
        }

        contentView.addSubview(contentLabelHandler.contentLabel)
        contentLabelHandler.contentLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(1)
            make.left.equalTo(nameLabel)
            make.right.lessThanOrEqualToSuperview().inset(8)
            make.right.equalToSuperview().inset(8).priority(.medium)
            make.bottom.equalToSuperview().inset(6)
        }

        let tapGusture = UITapGestureRecognizer(target: self, action: #selector(handleClickContent))
        contentView.addGestureRecognizer(tapGusture)
    }

    // MARK: - Actions

    @objc
    private func handleClickContent() {
        delegate?.messageBubbleViewDidClick(item: chatItem)
    }
}

extension ChatMessageBubbleView {

    class ContentLabelHandler {
        let isUseImChat: Bool

        private let lkLabel: LKLabel = {
            let label = LKLabel()
            label.backgroundColor = .clear
            label.numberOfLines = 5
            return label
        }()

        private let label: UILabel = {
            let label = UILabel()
            label.backgroundColor = .clear
            label.numberOfLines = 5
            return label
        }()

        var contentLabel: UIView {
            if isUseImChat {
                return label
            } else {
                return lkLabel
            }
        }

        init(isUseImChat: Bool) {
            self.isUseImChat = isUseImChat
        }

        func setAttributedText(_ attributedText: NSAttributedString?) {
            if isUseImChat {
                label.attributedText = attributedText
                label.lineBreakMode = .byTruncatingTail
            } else {
                lkLabel.attributedText = attributedText
                lkLabel.outOfRangeText = NSAttributedString(string: "\u{2026}", attributes: IMChatViewModel.Cons.attributes)
            }
        }

        func setNumberOfLines(_ numberOfLines: Int) {
            if isUseImChat {
                label.numberOfLines = numberOfLines
            } else {
                lkLabel.numberOfLines = numberOfLines
            }
        }

        func setPreferredMaxLayoutWidth(_ width: CGFloat) {
            if isUseImChat {
                label.preferredMaxLayoutWidth = width
            } else {
                lkLabel.preferredMaxLayoutWidth = width
            }
        }
    }
}
