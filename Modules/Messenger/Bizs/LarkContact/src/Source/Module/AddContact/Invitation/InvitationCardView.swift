//
//  InvitationCardView.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/9/11.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import LarkUIKit
import LarkBizAvatar
import AvatarComponent

final class InvitationCardControl: UIControl {
    private let avatarSize: CGFloat = 48
    lazy var avatarImageView: BizAvatar = {
        let avatarImageView = BizAvatar()
        avatarImageView.layer.masksToBounds = true
        avatarImageView.lastingColor = UIColor.clear
        avatarImageView.setAvatarUIConfig(AvatarComponentUIConfig(backgroundColor: UIColor.clear))
        return avatarImageView
    }()

    lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.textAlignment = .center
        nameLabel.textColor = UIColor.ud.N900
        return nameLabel
    }()

    lazy var tenantLabel: UILabel = {
        let tenantLabel = UILabel()
        tenantLabel.font = UIFont.systemFont(ofSize: 11)
        tenantLabel.textAlignment = .center
        tenantLabel.textColor = UIColor.ud.N500
        return tenantLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.layer.cornerRadius = 4
        self.backgroundColor = UIColor.ud.primaryOnPrimaryFill
        self.layer.borderColor = UIColor.ud.N300.cgColor
        self.layer.borderWidth = 0.5
        self.layer.shadowColor = UIColor.ud.staticBlack.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowRadius = 12.5
        self.layer.shadowOpacity = 0.05

        self.addSubview(avatarImageView)
        self.addSubview(nameLabel)
        self.addSubview(tenantLabel)

        avatarImageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.width.height.equalTo(avatarSize)
        }

        nameLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(avatarImageView.snp.bottom).offset(20)
        }

        tenantLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(nameLabel.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-16)
        }
    }

    func setInvitationCardView(entityId: String, avatarKey: String, displayName: String, tenantName: String) {
        avatarImageView.setAvatarByIdentifier(entityId, avatarKey: avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        nameLabel.text = displayName
        tenantLabel.text = tenantName
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
