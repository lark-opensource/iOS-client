//
//  MessageCell.swift
//  FontDemo
//
//  Created by bytedance on 2020/11/4.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignTheme

class MessageCell: UITableViewCell {

    enum Cons {
        static var selfMessageColor: UIColor {
            return UIColor.ud.N900
        }
        static var otherMessageColor: UIColor {
            return UIColor.ud.N900
        }
        static var selfBubbleColor: UIColor {
            return UIColor.ud.W100 & UIColor.ud.colorfulBlue
        }
        static var otherBubbleColor: UIColor {
            return UIColor.ud.N200
        }
        static var bubbleCornerRadius: CGFloat { 10 }
        static var leftMargin: CGFloat { 20 }
        static var rightMargin: CGFloat { 40 }
        static var topMargin: CGFloat { 8 }
        static var bottomMargin: CGFloat { 0 }
        static var avatarBubbleMargin: CGFloat { 7 }
        static var messageVPadding: CGFloat { 8 }
        static var messageHPadding: CGFloat { 12 }
        static var avatarSize: CGFloat { 28 }
    }

    func configure(with model: Message, continuous: Bool) {
        avatarImageView.image = model.avatar
        bubbleView.backgroundColor = model.isFromSelf ? Cons.selfBubbleColor : Cons.otherBubbleColor
        messageLabel.textColor = model.isFromSelf ? Cons.selfMessageColor : Cons.otherMessageColor
        avatarImageView.isHidden = continuous
        messageLabel.font = .systemFont(ofSize: 17)
        bubbleView.layer.cornerRadius = Cons.bubbleCornerRadius
        avatarImageView.layer.cornerRadius = Cons.avatarSize / 2
        backgroundColor = .clear
        switch model.content {
        case .text(let content):
            bubbleView.image = nil
            messageLabel.text = content
            setupConstraints(continuous: continuous)
        case .image(let image):
            bubbleView.image = image
            messageLabel.text = nil
            setupConstraints(continuous: continuous, aspectRatio: image.size.width / image.size.height)
        }
    }

    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private lazy var bubbleView: UIImageView = {
        let view = UIImageView()
        view.clipsToBounds = true
        return view
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints(continuous: false)
        setupAppearance()
    }

    func setupSubviews() {
        addSubview(avatarImageView)
        addSubview(bubbleView)
        addSubview(messageLabel)
    }

    func setupConstraints(continuous: Bool, aspectRatio: CGFloat? = nil) {
        avatarImageView.snp.remakeConstraints { make in
            make.width.height.equalTo(Cons.avatarSize)
            make.top.equalToSuperview().offset(Cons.topMargin * (continuous ? 1 : 2))
            make.leading.equalToSuperview().offset(Cons.leftMargin)
        }
        bubbleView.snp.remakeConstraints { make in
            make.top.equalTo(avatarImageView)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(Cons.avatarBubbleMargin)
            make.bottom.equalToSuperview().offset(-Cons.bottomMargin)
            make.trailing.lessThanOrEqualToSuperview().offset(-Cons.rightMargin)
            if let ratio = aspectRatio {
                make.width.equalTo(bubbleView.snp.height).multipliedBy(ratio)
            }
        }
        messageLabel.snp.remakeConstraints { make in
            make.leading.equalTo(bubbleView).offset(Cons.messageHPadding)
            make.trailing.equalTo(bubbleView).offset(-Cons.messageHPadding)
            make.top.equalTo(bubbleView).offset(Cons.messageVPadding)
            make.bottom.equalTo(bubbleView).offset(-Cons.messageVPadding)
        }
    }

    func setupAppearance() {
        selectionStyle = .none
        avatarImageView.layer.ud.setBorderColor(UIColor.ud.N100)
        avatarImageView.layer.borderWidth = 1
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
