//
//  ChatCell.swift
//  FontDemo
//
//  Created by bytedance on 2020/11/4.
//

import Foundation
import UIKit
import LarkZoomable

class ChatCell: UITableViewCell {

    enum Cons {
        static func avatarSize(forZoom zoom: Zoom) -> CGFloat { LarkConstraint.auto(48, forZoom: zoom) }
    }

    func configure(with model: Chat, zoom: Zoom) {
        avatarImageView.backgroundColor = model.avatar
        nameLabel.text = model.name
        messageLabel.text = model.lastMessage
        timeLabel.text = model.lastActiveTime

        nameLabel.font = LarkFont.getTitle4(for: zoom)
        messageLabel.font = LarkFont.getBody2(for: zoom)
        timeLabel.font = LarkFont.getCaption1(for: zoom)
        avatarImageView.layer.cornerRadius = Cons.avatarSize(forZoom: zoom) / 2
        setupConstraints(zoom: zoom)
    }

    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        label.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        setupConstraints()
        setupAppearance()
    }

    func setupSubviews() {
        addSubview(avatarImageView)
        addSubview(nameLabel)
        addSubview(messageLabel)
        addSubview(timeLabel)
        addSubview(separatorLine)
    }

    private var avatarConstraints: [NSLayoutConstraint] = []
    private var nameConstraints: [NSLayoutConstraint] = []
    private var messageConstraints: [NSLayoutConstraint] = []
    private var timeConstraints: [NSLayoutConstraint] = []
    private var separatorConstraints: [NSLayoutConstraint] = []

    func getConstraints(zoom: Zoom = Zoom.currentZoom) {
        avatarConstraints = [
            avatarImageView.widthAnchor.constraint(equalToConstant: Cons.avatarSize(forZoom: zoom)),
            avatarImageView.heightAnchor.constraint(equalToConstant: Cons.avatarSize(forZoom: zoom)),
            avatarImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: .fixed(15))
        ]
        nameConstraints = [
            nameLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: .fixed(14)),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: .fixed(10)),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: .fixed(-10))
        ]
        messageConstraints = [
            messageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: LarkConstraint.auto(5, forZoom: zoom)),
            messageLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: .fixed(10)),
            messageLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: .fixed(-10)),
            messageLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: .fixed(-14))
        ]
        timeConstraints = [
            timeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: .fixed(-16)),
            timeLabel.firstBaselineAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor)
        ]
        separatorConstraints = [
            separatorLine.heightAnchor.constraint(equalToConstant: .fixed(0.5)),
            separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorLine.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor)
        ]
    }

    func setupConstraints(zoom: Zoom = Zoom.currentZoom) {
        NSLayoutConstraint.deactivate(avatarConstraints)
        NSLayoutConstraint.deactivate(nameConstraints)
        NSLayoutConstraint.deactivate(messageConstraints)
        NSLayoutConstraint.deactivate(timeConstraints)
        NSLayoutConstraint.deactivate(separatorConstraints)
        getConstraints(zoom: zoom)
        NSLayoutConstraint.activate(avatarConstraints)
        NSLayoutConstraint.activate(nameConstraints)
        NSLayoutConstraint.activate(messageConstraints)
        NSLayoutConstraint.activate(timeConstraints)
        NSLayoutConstraint.activate(separatorConstraints)
    }

    func setupAppearance() {
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

}
