//
//  MessageCell.swift
//  FontDemo
//
//  Created by bytedance on 2020/11/4.
//

import Foundation
import UIKit
import LarkZoomable
import UniverseDesignColor
import UniverseDesignFont
import ByteWebImage

final class MessageCell: UITableViewCell {

    enum Cons {
        static var messageColor: UIColor { UIColor.ud.textTitle }
        static var selfBubbleColor: UIColor { UIColor.ud.rgb(0xCCE0FF) & UIColor.ud.rgb(0x203E78) }
        static var otherBubbleColor: UIColor { UIColor.ud.N200 }
        static var bubbleCornerRadius: CGFloat { .fixed(10) }
        static var leftMargin: CGFloat { .fixed(20) }
        static var rightMargin: CGFloat { .fixed(40) }
        static var topMargin: CGFloat { .fixed(8) }
        static var bottomMargin: CGFloat { .fixed(0) }
        static var avatarBubbleMargin: CGFloat { .fixed(7) }
        static var messageVPadding: CGFloat { .fixed(8) }
        static var messageHPadding: CGFloat { .fixed(12) }
        static func avatarSize(forZoom zoom: Zoom) -> CGFloat { LarkConstraint.auto(28, forZoom: zoom) }
    }

    func configure(with model: Message, avatarURL: String?, continuous: Bool, zoom: Zoom) {
        if model.id == 0 {
            if let avatarURL = avatarURL,
               let url = URL(string: avatarURL) {
                avatarImageView.bt.setImage(url)
            }
        } else {
            avatarImageView.image = model.avatar
        }
        messageLabel.text = model.content
        bubbleView.backgroundColor = model.isFromSelf ? Cons.selfBubbleColor : Cons.otherBubbleColor
        avatarImageView.isHidden = continuous
        messageLabel.font = UDFont.getTitle4(for: zoom)
        bubbleView.layer.cornerRadius = Cons.bubbleCornerRadius
        avatarImageView.layer.cornerRadius = Cons.avatarSize(forZoom: zoom) / 2
        setupConstraints(continuous: continuous, zoom: zoom)
    }

    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private lazy var bubbleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = UIFont.ud.body0
        label.translatesAutoresizingMaskIntoConstraints = false
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

    private var avatarConstraints: [NSLayoutConstraint] = []
    private var bubbleConstraints: [NSLayoutConstraint] = []
    private var messageConstraints: [NSLayoutConstraint] = []

    func setupConstraints(continuous: Bool, zoom: Zoom = Zoom.currentZoom) {
        NSLayoutConstraint.deactivate(avatarConstraints)
        NSLayoutConstraint.deactivate(bubbleConstraints)
        NSLayoutConstraint.deactivate(messageConstraints)
        avatarConstraints = [
            avatarImageView.widthAnchor.constraint(equalToConstant: Cons.avatarSize(forZoom: zoom)),
            avatarImageView.heightAnchor.constraint(equalToConstant: Cons.avatarSize(forZoom: zoom)),
            avatarImageView.topAnchor.constraint(equalTo: topAnchor, constant: Cons.topMargin * (continuous ? 1 : 2)),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Cons.leftMargin)
        ]
        bubbleConstraints = [
            bubbleView.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            bubbleView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: Cons.avatarBubbleMargin),
            bubbleView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: Cons.bottomMargin),
            bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: .fixed(-Cons.rightMargin))
        ]
        messageConstraints = [
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: .fixed(Cons.messageVPadding)),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: .fixed(Cons.messageHPadding)),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: .fixed(-Cons.messageVPadding)),
            messageLabel.rightAnchor.constraint(equalTo: bubbleView.rightAnchor, constant: .fixed(-Cons.messageHPadding))
        ]
        NSLayoutConstraint.activate(avatarConstraints)
        NSLayoutConstraint.activate(bubbleConstraints)
        NSLayoutConstraint.activate(messageConstraints)
    }

    func setupAppearance() {
        messageLabel.textColor = Cons.messageColor
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgBody
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
