//
//  ThreadSelectionButton.swift
//  LarkThread
//
//  Created by zoujiayi on 2019/10/12.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import LarkBizAvatar

final class ThreadSelectionButton: UIControl {
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ud.N900
        return label
    }()

    private let avatarSize: CGFloat = 20
    private lazy var avatar: BizAvatar = {
        let avatar = BizAvatar()
        return avatar
    }()

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        label.text = BundleI18n.LarkThread.Lark_Groups_SelectGroupTip
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        return label
    }()

    private lazy var arrowIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.new_topic_arrow
        return imageView
    }()

    private lazy var border: UIView = {
        let border = UIView()
        border.backgroundColor = UIColor.ud.N300
        return border
    }()

    init() {
        super.init(frame: .zero)
        layoutViews()
        self.backgroundColor = UIColor.ud.N00
    }

    private func layoutViews() {
        self.addSubview(arrowIcon)
        arrowIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.trailing.equalToSuperview().offset(-16)
        }

        self.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
            make.trailing.equalToSuperview().offset(-36)
        }

        self.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(44)
            make.trailing.lessThanOrEqualTo(tipLabel.snp.leading).offset(-8)
        }
        self.addSubview(avatar)
        avatar.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(avatarSize)
        }

        self.addSubview(border)
        border.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func update(name: String, avatarKey: String, entityId: String) {
        nameLabel.text = name
        avatar.setAvatarByIdentifier(entityId, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
