//
//  TeamInfoCell.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/7/4.
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

typealias TeamAvatarEditHandler = () -> Void

// MARK: - 团队信息 - viewModel
// doc: https://bytedance.feishu.cn/docs/doccnIRzIxUOaz3lul1Di2MyvUE#
struct TeamInfoCellViewModel: TeamCellViewModelProtocol {
    var type: TeamCellType
    var cellIdentifier: String
    var style: TeamCellSeparaterStyle

    var isShowLeftAvatar: Bool = false
    var isShowDescription: Bool = false
    var isShowArrow: Bool = false
    var title: String?
    var attriTitle: NSAttributedString?
    var subTitle: NSAttributedString = NSAttributedString()
    var leftAvatarKey: String = ""
    var description: String = ""
    var avatarId: String = ""
    var tapHandler: TeamCellTapHandler
}

// MARK: - 团队信息 - cell
final class TeamInfoCell: TeamBaseCell {
    private let avatarSize: CGFloat = 48

    private var leftAvatarImageView: BizAvatar = {
        let avatar = BizAvatar()
        return avatar
    }()
    private var leftStack: UIStackView = {
        var stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.distribution = .equalSpacing
        return stack
    }()
    private var titleStack: UIStackView = {
        var stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 1
        stack.alignment = .leading
        stack.distribution = .equalSpacing
        return stack
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        return label
    }()
    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 1
        return label
    }()
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()
    private var arrow = UIImageView(image: Resources.right_arrow)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(leftStack)
        leftStack.addArrangedSubview(leftAvatarImageView)
        leftStack.addArrangedSubview(titleStack)
        titleStack.addArrangedSubview(titleLabel)
        titleStack.addArrangedSubview(subTitleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(arrow)

        leftStack.snp.makeConstraints { (maker) in
            maker.left.top.equalTo(16)
            maker.bottom.equalTo(-16)
        }
        leftAvatarImageView.snp.makeConstraints { maker in
            maker.width.height.equalTo(avatarSize)
        }
        descriptionLabel.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.left.greaterThanOrEqualTo(leftStack.snp.right)
            maker.right.equalTo(arrow.snp.left).offset(-8)
            maker.height.equalTo(24)
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
        guard let item = item as? TeamInfoCellViewModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        leftAvatarImageView.snp.updateConstraints { (maker) in
            maker.width.height.equalTo(item.isShowLeftAvatar ? avatarSize : 0)
        }
        leftAvatarImageView.isHidden = !item.isShowLeftAvatar
        descriptionLabel.isHidden = !item.isShowDescription
        arrow.isHidden = !item.isShowArrow

        if item.isShowLeftAvatar, !item.leftAvatarKey.isEmpty {
            leftAvatarImageView.setAvatarByIdentifier(item.avatarId, avatarKey: item.leftAvatarKey)
        }
        if let title = item.title {
            titleLabel.text = title
        } else if let attriTitle = item.attriTitle {
            titleLabel.attributedText = attriTitle
        }
        subTitleLabel.isHidden = item.subTitle.string.isEmpty
        subTitleLabel.attributedText = item.subTitle
        descriptionLabel.text = item.description
        layoutSeparater(item.style)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let infoItem = self.item as? TeamInfoCellViewModel {
            infoItem.tapHandler(self)
        }
        super.setSelected(selected, animated: animated)
    }
}
