//
//  TestView.swift
//  LarkPushCardDev
//
//  Created by 白镜吾 on 2022/10/10.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import LarkPushCard

/// 响铃卡片
class RingView: UIView {
    var id: String
    private lazy var contentView: UIView = {
        let view = UIView()
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return view
    }()

    let avatarImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        return view
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.text = "aaaaaaaaabbbbb"
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return label
    }()

    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = .systemFont(ofSize: 12)
        label.textAlignment = .left
        label.text = "bba bba ba b ba bbabab"
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        return label
    }()

    lazy var declineButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .red
        let image = UDIcon.getIconByKey(.callEndFilled, iconColor: UIColor.ud.primaryPri500, size: CGSize(width: 36, height: 36))
        button.setImage(image, for: .normal)
        button.setImage(image, for: .highlighted)
        button.setImage(image, for: .disabled)
        button.layer.masksToBounds = true
        return button
    }()

    lazy var acceptButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .green
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(clickAccept(_:)), for: .touchUpInside)
        return button
    }()

    @objc
    func clickAccept(_ sender: UIButton) {
        PushCardCenter.shared.remove(with: id)
    }

    init(id: String) {
        self.id = id
        super.init(frame: .zero)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(acceptButton)
        contentView.addSubview(declineButton)
        addSubview(contentView)

        contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(80)
        }

        avatarImageView.snp.remakeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(44.0)
        }
        nameLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(avatarImageView.snp.right).offset(8)
            make.right.equalTo(declineButton.snp.left).offset(-8)
            make.height.equalTo(24)
            make.top.equalToSuperview().offset(18)
        }

        descriptionLabel.snp.remakeConstraints { (make) in
            make.left.right.equalTo(nameLabel)
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.height.equalTo(18)
        }

        acceptButton.snp.remakeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
            make.right.equalToSuperview().offset(-16)
        }

        declineButton.snp.remakeConstraints { (make) in
            make.size.equalTo(36)
            make.centerY.equalTo(acceptButton)
            make.right.equalTo(acceptButton.snp.left).offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
