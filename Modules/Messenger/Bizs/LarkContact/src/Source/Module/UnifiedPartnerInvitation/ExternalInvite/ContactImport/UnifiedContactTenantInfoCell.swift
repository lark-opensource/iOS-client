//
//  UnifiedContactTenantInfoCell.swift
//  LarkContact
//
//  Created by mochangxing on 2019/9/24.
//

import Foundation
import UIKit
import SnapKit
import LarkModel
import LarkSDKInterface
import ByteWebImage
import LarkBizAvatar

final class UnifiedContactTenantInfoCell: UITableViewCell {

    private let avatarSize: CGFloat = 48
    private lazy var profileThumbnailImageView: BizAvatar = {
        let view = BizAvatar()
        view.layer.masksToBounds = true
        return view
    }()
    private lazy var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.N900
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()
    private lazy var tenantLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.N500
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private lazy var viewButton: UIButton = {
        let viewButton = UIButton(frame: .zero)
        viewButton.setTitleColor(UIColor.ud.N00, for: .normal)
        viewButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        viewButton.backgroundColor = UIColor.ud.colorfulBlue
        viewButton.layer.cornerRadius = 4
        viewButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        viewButton.setTitle(BundleI18n.LarkContact.Lark_UserGrowth_InvitePeopleSearchView, for: .normal)
        viewButton.clipsToBounds = true
        viewButton.isUserInteractionEnabled = false // 不处理时间，只是为了设置contentEdgeInsets
        return viewButton
    }()

    private lazy var bottomLine: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.N300
        return line
    }()

    var showBottomLine: Bool = false {
        didSet {
            bottomLine.isHidden = !showBottomLine
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.N00
        contentView.addSubview(profileThumbnailImageView)
        contentView.addSubview(tenantLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(viewButton)
        contentView.addSubview(bottomLine)
        profileThumbnailImageView.snp.makeConstraints { (make) in
            make.left.equalTo(contentView.snp.left).offset(16)
            make.width.height.equalTo(avatarSize)
            make.centerY.equalToSuperview()
        }

        viewButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.height.equalTo(28)
        }

        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(profileThumbnailImageView.snp.right).offset(12)
            make.right.lessThanOrEqualTo(viewButton.snp.left).offset(-12).priority(.high)
            make.top.equalTo(contentView.snp.top).offset(12)
            make.height.equalTo(23)
        }

        tenantLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.left)
            make.right.lessThanOrEqualTo(viewButton.snp.left).offset(-12).priority(.high)
            make.bottom.equalToSuperview().offset(-12.5)
            make.height.equalTo(20)
        }

        bottomLine.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.left)
            make.right.equalTo(contentView.snp.right)
            make.bottom.equalTo(contentView.snp.bottom)
            make.height.equalTo(0.5)
        }
    }

    func bindWithModel(userProfile: UserProfile) {

        profileThumbnailImageView
            .setAvatarByIdentifier(userProfile.userId,
                                   avatarKey: userProfile.avatarKey,
                                   scene: .Profile,
                                   avatarViewParams: .init(sizeType: .size(avatarSize)))

        tenantLabel.text = userProfile.company.tenantName
        nameLabel.text = userProfile.displayNameForSearch
        if userProfile.company.tenantName.isEmpty {
            nameLabel.snp.updateConstraints { (make) in
                make.height.equalTo(44)
            }
        } else {
            nameLabel.snp.updateConstraints { (make) in
                make.height.equalTo(23)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
