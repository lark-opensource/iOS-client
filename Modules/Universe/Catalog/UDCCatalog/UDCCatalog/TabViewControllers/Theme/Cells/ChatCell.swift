//
//  ChatCell.swift
//  FontDemo
//
//  Created by bytedance on 2020/11/4.
//

import Foundation
import UIKit

class ChatCell: UITableViewCell {

    enum Cons {
        static var avatarSize: CGFloat { 48 }
    }

    func configure(with model: Chat) {
        avatarImageView.image = model.avatar
        nameLabel.text = model.name
        messageLabel.text = model.lastMessage
        timeLabel.text = model.lastActiveTime

        nameLabel.font = .systemFont(ofSize: 17)
        messageLabel.font = .systemFont(ofSize: 14)
        timeLabel.font = .systemFont(ofSize: 12)
        avatarImageView.layer.cornerRadius = Cons.avatarSize / 2
        setupConstraints()
        backgroundColor = .clear
    }

    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N900
        return label
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        label.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N500
        return label
    }()

    private lazy var separatorLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N500
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

    func setupConstraints() {
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(Cons.avatarSize)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(15)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.height.equalTo(21)
        }
        messageLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-14)
            make.leading.trailing.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(5)
            make.height.equalTo(17)
        }
        timeLabel.snp.makeConstraints { make in
            make.firstBaseline.equalTo(nameLabel)
            make.trailing.equalToSuperview().offset(-10)
        }
        separatorLine.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview()
            make.height.equalTo(0.5)
            make.leading.equalTo(nameLabel)
        }
    }

    func setupAppearance() {
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
        backgroundColor = selected ? UIColor.ud.N50 : UIColor.ud.N00
    }
}
