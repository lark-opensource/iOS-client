//
//  TeamListCell.swift
//  LarkFeed
//
//  Created by chaishenghua on 2022/12/28.
//

import Foundation
import UniverseDesignIcon
import UIKit
import LarkBizAvatar
import ByteWebImage
import RustPB

final class TeamListCell: UITableViewCell {
    /// 头像
    private let teamAvatarView = LarkMedalAvatar()
    /// 标题
    private let titleLabel = UILabel()
    /// 分割线
    private let lineView = UIView()
    private static let downsampleSize = CGSize(width: 20, height: 20)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        let image = Resources.labelCustomOutlined
        self.teamAvatarView.image = image
        self.contentView.addSubview(self.teamAvatarView)
        self.teamAvatarView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        /// 标题
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.lineBreakMode = .byTruncatingTail
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.teamAvatarView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        /// 分割线
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        self.contentView.addSubview(lineView)
        lineView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(team: Basic_V1_Team) {
        self.titleLabel.text = team.name
        self.teamAvatarView.setAvatarByIdentifier(
            String(team.id),
            avatarKey: team.avatarKey,
            scene: .Feed,
            options: [.downsampleSize(Self.downsampleSize)],
            avatarViewParams: .init(sizeType: .size(Self.downsampleSize.width)),
            completion: { result in
                if case let .failure(error) = result {
                    FeedContext.log.error("teamlog/image/team. \(team.id), \(error)")
                }
            })
    }
}
