//
//  MemberListCell.swift
//  Todo
//
//  Created by 张威 on 2021/9/12.
//

import CTFoundation
import LarkBizAvatar
import LarkTag
import UniverseDesignIcon
import UniverseDesignFont

/// MemberList - Cell

enum MemberListCellDeleteState {
    case hidden                     // 不可见
    case disable(message: String)   // 不可用，但可以点击（点击后弹 toast 提醒）
    case enable                     // 可用，可以点击
}

protocol MemberListCellDataType {
    var member: Member { get }
    var tags: [LarkTag.TagType] { get }
    var deleteState: MemberListCellDeleteState { get }
}

class MemberListCell: UITableViewCell, ViewDataConvertible {

    var viewData: MemberListCellDataType? {
        didSet {
            guard let viewData = viewData else { return }
            updateContent(with: viewData)
        }
    }

    var onDelete: (() -> Void)?
    var onDeleteDisableAlert: ((String) -> Void)?

    private let avatarSize: CGFloat = 40

    private let avatarView = BizAvatar()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()
    private let nameTag = TagWrapperView()
    private let deleteButton = UIButton()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody

        deleteButton.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        let closeIcon = UDIcon.closeOutlined.ud.resized(to: CGSize(width: 16, height: 16))
        deleteButton.setImage(closeIcon.ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        deleteButton.addTarget(self, action: #selector(handleDeleteButtonClick), for: .touchUpInside)

        contentView.addSubview(deleteButton)
        deleteButton.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().offset(-16)
            $0.width.height.equalTo(16)
        }

        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(avatarSize)
        }

        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints {
            $0.left.equalTo(avatarView.snp.right).offset(12)
            $0.centerY.equalToSuperview()
        }

        nameTag.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameTag.setContentHuggingPriority(.required, for: .horizontal)
        contentView.addSubview(nameTag)
        nameTag.snp.makeConstraints {
            $0.centerY.equalTo(nameLabel)
            $0.left.equalTo(nameLabel.snp.right).offset(6)
            $0.right.lessThanOrEqualTo(deleteButton.snp.left).offset(-12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateContent(with viewData: MemberListCellDataType) {
        nameLabel.text = viewData.member.name

        avatarView.setAvatarByIdentifier(
            viewData.member.avatar.avatarId,
            avatarKey: viewData.member.avatar.avatarKey,
            avatarViewParams: .init(sizeType: .size(avatarSize), format: .webp)
        )

        nameTag.setTags(viewData.tags)

        let deleteIconSize = CGSize(width: 16, height: 16)
        switch viewData.deleteState {
        case .hidden:
            deleteButton.isHidden = true
        case .disable:
            let icon = UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.N400, size: deleteIconSize)
            deleteButton.isHidden = false
            deleteButton.setImage(icon, for: .normal)
        case .enable:
            deleteButton.isHidden = false
            let icon = UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.N600, size: deleteIconSize)
            deleteButton.setImage(icon, for: .normal)
        }
    }

    @objc
    private func handleDeleteButtonClick() {
        switch viewData?.deleteState {
        case .disable(let message):
            onDeleteDisableAlert?(message)
        case .enable:
            onDelete?()
        default:
            break
        }
    }

}
