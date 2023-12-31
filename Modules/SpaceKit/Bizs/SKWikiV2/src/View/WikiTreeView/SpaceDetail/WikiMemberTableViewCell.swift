//
//  WikiMemberTableViewCell.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/23.
//  

import UIKit
import SKUIKit
import SnapKit
import Kingfisher
import SKCommon
import SKResource
import UniverseDesignColor
import SKWorkspace

class WikiMemberTableViewCell: UITableViewCell {

    private lazy var avatarImageView: UIImageView = {
        let imageView = SKAvatar(configuration: .init(style: .circle, contentMode: .scaleAspectFit))
        return imageView
    }()

    private lazy var roleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ct.systemRegular(ofSize: 14)
        label.textColor = UDColor.textCaption
        return label
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ct.systemRegular(ofSize: 17)
        label.textColor = UDColor.textTitle
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ct.systemRegular(ofSize: 14)
        label.textColor = UDColor.textPlaceholder
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    var avatarDidClick: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarDidClick = nil
    }

    private func setupUI() {
        contentView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 20

        contentView.addSubview(roleLabel)
        roleLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        roleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.top.equalToSuperview().inset(12)
            make.left.equalTo(avatarImageView.snp.right).offset(12)
            make.right.equalTo(roleLabel.snp.left).offset(-12)
        }

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom)
            make.height.equalTo(20)
            make.bottom.equalToSuperview().inset(12)
            make.left.equalTo(nameLabel.snp.left)
            make.right.equalTo(roleLabel.snp.left).offset(-12)
        }

        let avatarTapGesture = UITapGestureRecognizer(target: self, action: #selector(didClickAvatar))
        avatarImageView.addGestureRecognizer(avatarTapGesture)
        avatarImageView.isUserInteractionEnabled = true
        contentView.backgroundColor = UDColor.bgBody
    }

    @objc
    private func didClickAvatar() {
        avatarDidClick?()
    }

    func update(member: WikiMemberListDisplayProtocol) {
        nameLabel.text = member.displayName
        descriptionLabel.text = member.displayDescription
        if member.displayDescription.trim().isEmpty {
            nameLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().inset(22)
            }
            descriptionLabel.snp.updateConstraints { make in
                make.bottom.equalToSuperview().inset(2)
            }
        } else {
            nameLabel.snp.updateConstraints { make in
                make.top.equalToSuperview().inset(12)
            }
            descriptionLabel.snp.updateConstraints { make in
                make.bottom.equalToSuperview().inset(12)
            }
        }
        roleLabel.text = member.displayRole
        if let image = member.displayIcon {
            avatarImageView.image = image
        } else if let iconURL = member.displayIconURL {
            avatarImageView.kf.setImage(with: iconURL, placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
        } else {
            avatarImageView.image = BundleResources.SKResource.Common.Collaborator.avatar_placeholder
        }
    }

}
