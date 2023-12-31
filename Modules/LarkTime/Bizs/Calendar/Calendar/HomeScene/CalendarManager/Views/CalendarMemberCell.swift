//
//  CalendarManagerCalMemberView.swift
//  Calendar
//
//  Created by harry zou on 2019/3/22.
//

import UniverseDesignIcon
import UIKit
import CalendarFoundation
import LarkBizAvatar
struct CalendarMemberCellModel {
    let avatar: Avatar
    let name: String
    var role: String
    var editable: Bool
    var shouldHidden: Bool
    var groupMemberCount: String

    static func from(_ member: CalendarMember,
                     haveEditAccess: Bool,
                     isGroup: Bool,
                     groupMemberCount: Int) -> CalendarMemberCellModel {
        let avatar = member
        var name = member.localizedName
        var groupMemberCountString = ""
        if isGroup {
            name = member.userName
            if member.isUserCountVisible {
                groupMemberCountString = "(\(groupMemberCount))"
            }
        }
        let role = member.accessRole.toLocalString()
        let shouldHidden = member.status == .removed
        return CalendarMemberCellModel(avatar: avatar,
                                       name: name,
                                       role: role,
                                       editable: haveEditAccess,
                                       shouldHidden: shouldHidden,
                                       groupMemberCount: groupMemberCountString)
    }
}

final class CalendarMemberCell: UIControl, AddBottomLineAble {
    var index: Int = -1

    private let safeAreaLayoutWidth: CGFloat = 48
    private let LeftSideTitleMaximumWidthRatio: CGFloat = 0.6
    private let avatarView = AvatarView()
    private let nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.font = UIFont.cd.regularFont(ofSize: 16)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return nameLabel
    }()

    private var groupMemberCntLabel: UILabel = {
        let groupMemberCntLabel = UILabel()
        groupMemberCntLabel.setContentHuggingPriority(.required, for: .horizontal)
        groupMemberCntLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        groupMemberCntLabel.numberOfLines = 1
        groupMemberCntLabel.lineBreakMode = .byTruncatingTail
        groupMemberCntLabel.font = UIFont.cd.regularFont(ofSize: 16)
        return groupMemberCntLabel
    }()

    private let roleLabel: UILabel = {
        let roleLabel = UILabel()
        roleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        roleLabel.font = UIFont.cd.regularFont(ofSize: 14)
        roleLabel.textColor = UIColor.ud.textPlaceholder
        roleLabel.numberOfLines = 2
        roleLabel.lineBreakMode = .byTruncatingTail
        return roleLabel
    }()

    private let tailIcon = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.rightOutlined).renderColor(with: .n3).withRenderingMode(.alwaysOriginal))

    override var isEnabled: Bool {
        didSet {
            relayout(tailIcon: tailIcon, leftView: roleLabel, isHidden: !isEnabled)
            layoutIfNeeded()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        layout(avatarView: avatarView)
        layout(nameLabel: nameLabel, leftView: avatarView)
        layout(groupMemberCntLabel: groupMemberCntLabel, leftView: nameLabel)
        layout(roleLabel: roleLabel, leftView: groupMemberCntLabel)
        layout(tailIcon: tailIcon, leftView: roleLabel)
    }

    private func layout(avatarView: UIView) {
        addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(48)
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
        }
    }

    private func layout(nameLabel: UILabel, leftView: UIView) {
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(leftView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
        }
    }

    private func layout(groupMemberCntLabel: UILabel, leftView: UIView) {
        addSubview(groupMemberCntLabel)
        groupMemberCntLabel.snp.makeConstraints { (make) in
            make.left.equalTo(leftView.snp.right)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
            make.right.lessThanOrEqualToSuperview().multipliedBy(LeftSideTitleMaximumWidthRatio)
        }
    }

    private func layout(roleLabel: UILabel, leftView: UIView) {
        addSubview(roleLabel)
        roleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(leftView.snp.right).offset(safeAreaLayoutWidth)
        }
    }

    private func layout(tailIcon: UIView, leftView: UIView) {
        addSubview(tailIcon)
        relayout(tailIcon: tailIcon, leftView: leftView, isHidden: false)
    }

    private func relayout(tailIcon: UIView, leftView: UIView, isHidden: Bool) {
        tailIcon.isHidden = isHidden
        tailIcon.snp.removeConstraints()
        tailIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.left.equalTo(leftView.snp.right).offset(8)
            if isHidden {
                make.width.equalTo(0)
            } else {
                make.width.height.equalTo(12)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUI(with model: CalendarMemberCellModel?) {
        if let avatar = model?.avatar {
            avatarView.setAvatar(avatar, with: 48)
        }
        nameLabel.text = model?.name
        roleLabel.text = model?.role
        groupMemberCntLabel.text = model?.groupMemberCount
        isEnabled = model?.editable ?? false
        isUserInteractionEnabled = true
    }
}
