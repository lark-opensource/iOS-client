//
//  EventEditAttendeeTimeZoneCell.swift
//  Calendar
//
//  Created by 张威 on 2020/2/17.
//

import UIKit
import LarkBizAvatar
final class EventEditAttendeeTimeZoneCell: UITableViewCell {

    static let desiredHeight: CGFloat = 70
    typealias Item = (avatar: Avatar, name: String)

    private var avatarView = AvatarView()
    private var nameLabel: UILabel = UILabel()

    var item: Item? {
        didSet {
            if let avatar = item?.avatar {
                avatarView.setAvatar(avatar, with: 48)
            }
            nameLabel.text = item?.name
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(48)
            $0.left.equalToSuperview().offset(16)
        }

        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.font = UIFont.cd.regularFont(ofSize: 16)
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalTo(avatarView.snp.right).offset(12)
            $0.right.equalToSuperview().offset(-16)
            $0.height.equalTo(23)
        }
        contentView.backgroundColor = UIColor.ud.bgFloat
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
