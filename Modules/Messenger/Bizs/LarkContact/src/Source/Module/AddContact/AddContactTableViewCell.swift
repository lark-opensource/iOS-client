//
//  AddContactTableViewCell.swift
//  LarkContact
//
//  Created by ChalrieSu on 2018/9/13.
//

import Foundation
import UIKit
import LarkCore
import LarkModel
import LarkUIKit
import LarkBizAvatar

final class AddContactTableViewCell: UITableViewCell {
    private var avatarImageView: BizAvatar = .init(frame: .zero)
    private let avatarSize: CGFloat = 48
    private var titleLabel: UILabel = .init()
    private var detailLabel: UILabel = .init()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectedBackgroundView = BaseCellSelectView()

        self.avatarImageView = BizAvatar()
        self.contentView.addSubview(self.avatarImageView)
        self.avatarImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(avatarSize).priority(.required)
            make.left.equalTo(16)
            make.top.equalTo(10)
            make.centerY.equalToSuperview()
        }

        self.titleLabel = UILabel()
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textColor = UIColor.ud.N900
        self.contentView.addSubview(self.titleLabel)

        self.detailLabel = UILabel()
        self.detailLabel.font = UIFont.systemFont(ofSize: 14)
        self.detailLabel.textColor = UIColor.ud.N500
        self.contentView.addSubview(self.detailLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(entityId: String, avatarKey: String, name: String, detail: String?) {
        self.avatarImageView.setAvatarByIdentifier(entityId,
                                                   avatarKey: avatarKey,
                                                   scene: .Contact,
                                                   avatarViewParams: .init(sizeType: .size(avatarSize)))
        self.titleLabel.text = name
        self.detailLabel.text = detail

        self.titleLabel.snp.removeConstraints()
        self.detailLabel.snp.removeConstraints()
        if detail?.isEmpty == false {
            self.detailLabel.isHidden = false
            self.titleLabel.snp.makeConstraints { (make) in
                make.left.equalTo(73.5)
                make.right.equalTo(-16)
                make.top.equalTo(12)
            }
            self.detailLabel.snp.makeConstraints { (make) in
                make.left.equalTo(73.5)
                make.right.equalTo(-16)
                make.bottom.equalTo(-11.5)
            }
        } else {
            self.detailLabel.isHidden = true
            self.titleLabel.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.right.equalTo(-16)
                make.left.equalTo(73.5)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.avatarImageView.setAvatarByIdentifier("", avatarKey: "")
        self.titleLabel.text = nil
        self.detailLabel.text = nil
    }
}
