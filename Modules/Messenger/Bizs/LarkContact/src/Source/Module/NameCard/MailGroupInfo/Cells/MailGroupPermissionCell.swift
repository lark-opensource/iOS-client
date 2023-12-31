//
//  MailGroupPermissionCell.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/11/5.
//

import Foundation
import LarkUIKit
import UniverseDesignCheckBox
import UIKit
import UniverseDesignIcon

class BaseMailGroupSettingCell: MailGroupInfoCell {
    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        contentView.addSubview(label)
        return label
    }()

    private(set) lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 2
        contentView.addSubview(label)
        return label
    }()

    private(set) lazy var switchButton: LoadingSwitch = {
        let switchButton = LoadingSwitch(behaviourType: .normal)
        switchButton.isHidden = true
        switchButton.onTintColor = UIColor.ud.primaryContentDefault
        switchButton.valueChanged = { [weak self] (isOn) in
            self?.switchButtonStatusChange(to: isOn)
        }
        contentView.addSubview(switchButton)
        return switchButton
    }()

    fileprivate var separatorStyle: SeparaterStyle = .none

    func defaultLayoutSwitchButton() {
        switchButton.isHidden = false
        switchButton.snp.makeConstraints { (maker) in
            maker.centerY.equalToSuperview()
            maker.right.equalToSuperview().offset(-12)
        }
    }

    func switchButtonStatusChange(to status: Bool) {}
}

class MailGroupPermissionCell: BaseMailGroupSettingCell {
    let checkBox = UDCheckBox(boxType: .single)
    lazy var countLabel: UILabel = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(48)
            make.centerY.equalToSuperview()
        }
        contentView.addSubview(checkBox)
        checkBox.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(16)
            make.size.equalTo(LKCheckbox.Layout.iconMidSize)
        }
        checkBox.isSelected = false
        arrow.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

final class MailGroupPermissionMemberCell: MailGroupPermissionCell {
    lazy var membersView: MailGroupInfoMemberView = MailGroupInfoMemberView()

    func setMembers(editable: Bool,
                    memberCount: Int,
                    memberItems: [MailGroupInfoMemberViewItem],
                    addClick: @escaping MailGroupInfoTapHandler,
                    deleteClick: @escaping MailGroupInfoTapHandler) {

        if countLabel.superview == nil {
            countLabel = UILabel()
            countLabel.font = UIFont.systemFont(ofSize: 14)
            countLabel.textColor = UIColor.ud.textPlaceholder
            countLabel.textAlignment = .right
            contentView.addSubview(countLabel)
            countLabel.snp.makeConstraints { (maker) in
                maker.right.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 32))
                maker.top.equalTo(titleLabel.snp.top)
                maker.height.equalTo(20)
            }

            arrow.snp.remakeConstraints { (maker) in
                maker.centerY.equalTo(countLabel.snp.centerY)
                maker.right.equalToSuperview().offset(-16)
                maker.width.height.equalTo(12)
            }
            arrow.isHidden = false
        }

        let show = memberCount > 0
        arrow.isHidden = !show
        countLabel.isHidden = !show
        if show {
            titleLabel.snp.remakeConstraints { (maker) in
                maker.top.left.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 48, bottom: 0, right: 0))
                maker.right.lessThanOrEqualTo(countLabel.snp.left).offset(-12)
            }
            checkBox.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.top)
                make.left.equalTo(16)
                make.size.equalTo(LKCheckbox.Layout.iconMidSize)
            }
        } else {
            titleLabel.snp.remakeConstraints { (make) in
                make.leading.equalToSuperview().offset(48)
                make.centerY.equalToSuperview()
            }
            checkBox.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalTo(16)
                make.size.equalTo(LKCheckbox.Layout.iconMidSize)
            }
        }

        countLabel.text = "\(memberCount)"
        if memberCount > 0 {
            self.contentView.addSubview(membersView)
            membersView.snp.remakeConstraints { maker in
                maker.top.equalTo(titleLabel.snp.bottom).offset(12)
                maker.left.equalToSuperview().offset(32)
                maker.bottom.equalToSuperview().offset(-12)
                maker.height.equalTo(32)
            }
            membersView.isHidden = false
            membersView.set(memberItems: memberItems,
                            hasAccess: editable,
                            width: bounds.size.width - 32,
                            isShowDeleteButton: editable)
            membersView.addNewMember = { [weak self] in
                if let `self` = self {
                    addClick(self)
                }
            }
            membersView.deleteMemberHandler = { [weak self] in
                if let `self` = self {
                    deleteClick(self)
                }
            }
        } else if membersView.superview != nil {
            membersView.removeFromSuperview()
        }
        layoutSeparater(.none)
    }
}

final class MailGroupPickerRouterCell: BaseMailGroupSettingCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.numberOfLines = 1
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(62)
            make.centerY.equalToSuperview()
        }
        titleLabel.textColor = UIColor.ud.primaryContentDefault

        imageView?.image = UDIcon.addOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault)
        imageView?.snp.makeConstraints { (make) in
            make.size.equalTo(14)
            make.leading.equalToSuperview().offset(48)
            make.centerY.equalToSuperview()
        }
        arrow.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
