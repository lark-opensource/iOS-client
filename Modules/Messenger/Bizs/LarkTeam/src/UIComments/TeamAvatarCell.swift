//
//  TeamAvatarCell.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/8/17.
//

import Foundation
import UIKit
import SnapKit
import LarkTag
import LarkCore
import LarkUIKit
import LarkBizAvatar
import LarkFeatureSwitch
import LarkMessengerInterface

// MARK: - 团队头像 - viewModel
struct TeamAvatarCellViewModel: TeamCellViewModelProtocol {
    var type: TeamCellType
    var cellIdentifier: String
    var style: TeamCellSeparaterStyle

    var title: String
    var avatarKey: String = ""
    var avatarId: String = ""
    var tapHandler: TeamCellTapHandler
}

// MARK: - 团队信息 - cell
final class TeamAvatarCell: TeamBaseCell {
    private let avatarSize: CGFloat = 48

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        return label
    }()
    private var rightAvatarImageView: BizAvatar = {
        let avatar = BizAvatar()
        return avatar
    }()
    private var arrow = UIImageView(image: Resources.right_arrow)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.addSubview(rightAvatarImageView)
        contentView.addSubview(arrow)

        titleLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(16)
            maker.centerY.equalTo(rightAvatarImageView.snp.centerY)
        }
        rightAvatarImageView.snp.makeConstraints { maker in
            maker.width.height.equalTo(avatarSize)
            maker.top.equalTo(16)
            maker.bottom.equalTo(-16)
            maker.right.equalTo(arrow.snp.left).offset(-8)
        }
        arrow.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-16)
            maker.width.height.equalTo(12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let item = item as? TeamAvatarCellViewModel else {
            assert(false, "\(self):item.Type error")
            return
        }

        titleLabel.text = item.title
        rightAvatarImageView.setAvatarByIdentifier(item.avatarId, avatarKey: item.avatarKey)
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let infoItem = self.item as? TeamAvatarCellViewModel {
            infoItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
