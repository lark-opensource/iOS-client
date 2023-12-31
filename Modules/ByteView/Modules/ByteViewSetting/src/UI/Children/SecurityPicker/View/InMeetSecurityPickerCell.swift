//
//  InMeetSecurityPickerCell.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/9.
//

import Foundation
import UniverseDesignColor
import UniverseDesignCheckBox
import ByteViewCommon
import ByteViewUI
import ByteViewNetwork

class InMeetSecurityPickerCell: UITableViewCell {
    let checkboxView = UDCheckBox(boxType: .multiple)
    let avatarView = AvatarView(style: .circle)
    let containerView = UIView()
    let rightView = UIView()

    let titleView = UIView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    var titleAccessoryViews: [UIView] = []

    var showsCheckbox: Bool { true }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = .clear

        checkboxView.isUserInteractionEnabled = false
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = .ud.fillHover
        self.selectedBackgroundView = selectedBackgroundView

        titleLabel.textColor = .ud.textTitle
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        subtitleLabel.textColor = .ud.textPlaceholder

        /// checkbox - avatar - container - right
        contentView.addSubview(checkboxView)
        contentView.addSubview(avatarView)
        contentView.addSubview(containerView)
        contentView.addSubview(rightView)
        containerView.addSubview(titleView)
        containerView.addSubview(subtitleLabel)
        titleView.addSubview(titleLabel)
        checkboxView.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.left.equalTo(safeAreaLayoutGuide).offset(16)
        }

        rightView.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.width.equalTo(0).priority(.low)
        }

        containerView.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }

        titleView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(24) // .h4
            make.bottom.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        let showsCheckbox = self.showsCheckbox
        checkboxView.isHidden = !showsCheckbox
        self.isUserInteractionEnabled = showsCheckbox
        avatarView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
            if showsCheckbox {
                make.left.equalTo(checkboxView.snp.right).offset(12)
            } else {
                make.left.equalToSuperview().offset(62)
            }
        }
    }

    private var isConfiguringCell = false
    private(set) var item: InMeetSecurityPickerItem?
    weak var setting: MeetingSettingManager?
    func config(_ item: InMeetSecurityPickerItem, setting: MeetingSettingManager) {
        self.isConfiguringCell = true
        self.item = item
        self.setting = setting
        self.avatarView.setTinyAvatar(item.avatarInfo)
        self.titleLabel.attributedText = item.title
        self.subtitleLabel.attributedText = item.subtitle
    }

    /// convenience for row
    final func config(_ row: InMeetSecurityPickerRow, setting: MeetingSettingManager) {
        self.config(row.item, setting: setting)
        if showsCheckbox {
            self.checkboxView.isSelected = row.isSelected
        }
    }

    func didConfigCell() {
        isConfiguringCell = false
        let hasRightView = !rightView.isHidden && rightView.subviews.contains(where: { !$0.isHidden })
        containerView.snp.remakeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            if hasRightView {
                make.right.equalTo(rightView.snp.left)
            } else {
                make.right.equalToSuperview().offset(-20)
            }
        }

        let hasSubtitle = subtitleLabel.text?.isEmpty == false
        titleView.snp.remakeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(24) // .h4
            if hasSubtitle {
                make.bottom.equalTo(subtitleLabel.snp.top)
            } else {
                make.bottom.equalToSuperview()
            }
        }
        updateTitleAccessoryLayout()
    }

    final func updateTitleAccessoryLayout() {
        if isConfiguringCell { return }
        let accessoryViews: [UIView] = titleAccessoryViews.filter { !$0.isHidden }
        var lastView: UIView = self.titleLabel
        let lastAccessoryView = accessoryViews.last
        accessoryViews.forEach { view in
            view.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(lastView.snp.right).offset(8)
                if lastAccessoryView == view {
                    make.right.lessThanOrEqualToSuperview()
                }
            }
            lastView = view
        }
    }
}

extension InMeetSecurityUserFlagLabel {
    func setFlag(for pickerItem: InMeetSecurityPickerItem, setting: MeetingSettingManager) {
        let canShowExternal = setting.service.canShowExternal
        let isExternal: Bool
        let tagUser: VCRelationTag.User
        var workStatus: User.WorkStatus?
        var relationTag: CollaborationRelationTag?
        switch pickerItem {
        case .user(let item):
            let user = item.user
            isExternal = canShowExternal && setting.service.tenantId != user.tenantId
            tagUser = .init(type: .larkUser, id: user.id)
            workStatus = user.user?.workStatus
        case .group(let chat):
            tagUser = .init(type: .chat, id: chat.id)
            isExternal = chat.isCrossTenant && canShowExternal
        case .search(let item):
            if item.idType == .user {
                tagUser = .init(type: .larkUser, id: item.id)
                isExternal = canShowExternal && item.isExternal
                relationTag = item.relationTagWhenRing
                workStatus = item.userInfo?.workStatus
            } else if item.idType == .chat {
                tagUser = .init(type: .chat, id: item.id)
                isExternal = item.isExternal && canShowExternal
                relationTag = item.relationTagWhenRing
            } else {
                self.setFlagInfo(nil, service: nil)
                return
            }
        default:
            self.setFlagInfo(nil, service: nil)
            return
        }

        let flagInfo = InMeetSecurityUserFlagLabel.FlagInfo(isRelationTagEnabled: setting.isRelationTagEnabled, isNewStatusEnabled: setting.isNewStatusEnabled, isExternal: isExternal, user: tagUser, workStatus: workStatus, relationTag: relationTag)
        self.setFlagInfo(flagInfo, service: setting.service.httpClient.participantRelationTagService)
    }
}

extension UserFocusTagView {
    func setStatus(for pickerItem: InMeetSecurityPickerItem) {
        var statuses: [User.CustomStatus] = []
        switch pickerItem {
        case .user(let item):
            if let user = item.user.user {
                statuses = user.customStatuses
            }
        case .search(let item):
            if item.idType == .user, let info = item.userInfo {
                statuses = info.customStatuses
            }
        default:
            break
        }
        setCustomStatuses(statuses)
    }
}
