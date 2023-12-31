//
//  ReactionDetailTableViewCell.swift
//  LarkChat
//
//  Created by kongkaikai on 2018/12/12.
//

import Foundation
import UIKit
import LarkTag
import LarkUIKit
import UniverseDesignColor

final class ReactionDetailTableViewCell: UITableViewCell {

    var chatter: Chatter? {
        didSet {
            if chatter?.id == oldValue?.id { return }
            self.avatarView.imageView.image = nil
            self.nameLabel.text = chatter?.displayName ?? ""
            self.statusLabel.set(
                description: chatter?.descriptionText ?? "",
                descriptionType: chatter?.descriptionType ?? .onDefault,
                showIcon: true
            )
            if let avatarImageFetcher = avatarImageFetcher,
                let chatter = self.chatter {
                avatarImageFetcher(chatter) { [weak self] image in
                    if self?.chatter?.id != chatter.id { return }
                    excuteInMain {
                        self?.avatarView.imageView.image = image
                    }
                }
            }
        }
    }

    var avatarImageFetcher: ((Chatter, @escaping (UIImage) -> Void) -> Void)?

    public let avatarView = ChatterAvatarView()
    public let nameLabel = UILabel()
    public let statusLabel = ChatterStatusLabel()
    private let bottomLine = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(bottomLine)

        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 24
        avatarView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(48)
            maker.top.bottom.equalToSuperview().inset(10)
            maker.left.equalToSuperview().inset(16)
        }

        nameLabel.font = UIFont.systemFont(ofSize: 18)
        nameLabel.textColor = UIColor.ud.N900
        nameLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(avatarView.snp.right).offset(12)
        }

        statusLabel.isHidden = true
        statusLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.equalTo(nameLabel.snp.right).offset(8)
            maker.right.lessThanOrEqualToSuperview().inset(8)
        }

        bottomLine.backgroundColor = UIColor.ud.N300
        bottomLine.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().inset(76)
            maker.right.bottom.equalToSuperview()
            maker.height.equalTo(0.5)
        }

        selectedBackgroundView = BaseCellSelectView()

        avatarView.accessibilityIdentifier = "reaction.detail.page.cell.avatarview"
        nameLabel.accessibilityIdentifier = "reaction.detail.page.cell.nameLabel"
        statusLabel.accessibilityIdentifier = "reaction.detail.page.cell.statusLabel"
        bottomLine.accessibilityIdentifier = "reaction.detail.page.cell.bottomLine"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
