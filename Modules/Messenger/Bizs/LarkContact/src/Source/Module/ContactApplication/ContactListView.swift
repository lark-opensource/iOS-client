//
//  ContactListView.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/9/4.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import LarkBizAvatar
import AvatarComponent
import LarkContactComponent

final class ContactListView: UIView {
    private let avatarSize: CGFloat = 40
    private var tenantContainerView: LarkTenantNameViewInterface?
    lazy var avatarImageView: BizAvatar = {
        let avatarImageView = BizAvatar()
        avatarImageView.layer.masksToBounds = true
        avatarImageView.lastingColor = UIColor.clear
        avatarImageView.setAvatarUIConfig(AvatarComponentUIConfig(backgroundColor: UIColor.clear))
        return avatarImageView
    }()

    private let stackView = UIStackView()

    lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = UIFont.systemFont(ofSize: 17)
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        return nameLabel
    }()

    lazy var infoLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.textColor = UIColor.ud.textPlaceholder
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        infoLabel.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
        return infoLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(avatarImageView)
        self.addSubview(nameLabel)
        self.addSubview(infoLabel)

        avatarImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(avatarSize)
        }

        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(10)
            $0.left.equalTo(avatarImageView.snp.right).offset(12)
            $0.height.greaterThanOrEqualTo(avatarImageView)
            $0.right.equalToSuperview()
        }
        self.snp.makeConstraints {
            $0.bottom.equalTo(stackView).offset(12)
        }

        stackView.addArrangedSubview(nameLabel)
        if let tenantContainerView {
            stackView.addArrangedSubview(tenantContainerView)
        }
        stackView.addArrangedSubview(infoLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.width.greaterThanOrEqualTo(50)
            make.height.equalTo(24)
        }

        infoLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
        }
    }

    func set(
        name: String,
        info: String,
        tenantName: String,
        entityId: String,
        avartKey: String,
        tenantContainerView: LarkTenantNameViewInterface?) {
        self.avatarImageView.setAvatarByIdentifier(entityId, avatarKey: avartKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        infoLabel.isHidden = false
        nameLabel.isHidden = false

        nameLabel.text = name
        infoLabel.text = info
        if self.tenantContainerView == nil,
            let tenantContainView = tenantContainerView {
            self.tenantContainerView = tenantContainView
            stackView.insertArrangedSubview(tenantContainView, at: 1)
        }
        guard let tenantContainView = self.tenantContainerView else {
            return
        }
        tenantContainView.snp.remakeConstraints { (make) in
            make.height.equalTo(20)
        }
        infoLabel.isHidden = info.isEmpty
        tenantContainView.isHidden = tenantName.isEmpty
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
