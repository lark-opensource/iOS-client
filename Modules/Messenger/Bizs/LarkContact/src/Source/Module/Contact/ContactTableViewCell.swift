//
//  ContactTableViewCell.swift
//  Lark
//
//  Created by 刘晚林 on 2016/12/14.
//  Copyright © 2016年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import LarkModel
import LarkCore
import LarkTag
import LarkListItem
import LarkFeatureGating
import LarkFocus
import LarkContactComponent

 enum ContactCheckBoxStaus {
    case invalid, selected, unselected, defaultSelected, disableToSelect
}

 protocol ContactTableViewCellPropsProtocol {
    var name: String { get set }
    var avatarKey: String { get set }
    var medalKey: String { get set }
    var avatar: UIImage? { get set }
    var description: String? { get set }
    var hasNext: Bool { get set }
    var hasRegister: Bool { get set }
    var isRobot: Bool { get set }
    var isLeader: Bool { get set }
    var isAdministrator: Bool { get set }
    var isSuperAdministrator: Bool { get set }
    var checkStatus: ContactCheckBoxStaus { get set }
    var status: Chatter.Description? { get set }
}

 class ContactTableViewCell: UITableViewCell {
    public var badgeStackView: UIStackView = UIStackView()
    public lazy var personInfoView: ListItem = {
        let personInfoView = ListItem()
        // 有的场景会出现大于2个的情况，比如组织架构界面：未激活+超级管理员+负责人
        personInfoView.additionalIcon.maxTagCount = 3
        personInfoView.nameTag.maxTagCount = 3
        personInfoView.avatarView.backgroundColor = UIColor.clear
        personInfoView.bottomSeperator.isHidden = true
        personInfoView.backgroundColor = .clear
        return personInfoView
    }()
    public lazy var arrowImageBgView: UIView = {
        let bgView = UIView()
        let arrowImageView = UIImageView(image: Resources.mine_right_arrow)
        bgView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview().offset(-15)
        }
        return bgView
    }()
    private var tenantContainerView: LarkTenantNameViewInterface?

    var badageLabel: PaddingUILabel = .init()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.ud.bgBody
        self.contentView.backgroundColor = .clear
        setupBackgroundViews(highlightOn: true)

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
        }

        stackView.addArrangedSubview(personInfoView)

        arrowImageBgView.setContentHuggingPriority(.required, for: .horizontal)
        arrowImageBgView.setContentCompressionResistancePriority(.required, for: .horizontal)
        stackView.addArrangedSubview(arrowImageBgView)

        // badage
        badageLabel = PaddingUILabel()
        badageLabel.layer.cornerRadius = 8
        badageLabel.layer.masksToBounds = true
        badageLabel.paddingLeft = 4
        badageLabel.paddingRight = 4
        badageLabel.font = UIFont.systemFont(ofSize: 12)
        badageLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        badageLabel.textAlignment = .center
        badageLabel.color = UIColor.ud.colorfulRed

        badgeStackView.axis = .horizontal
        badgeStackView.alignment = .fill
        badgeStackView.spacing = 6
        badgeStackView.distribution = .fillEqually
        badgeStackView.addArrangedSubview(badageLabel)
        contentView.addSubview(badgeStackView)
        badgeStackView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        badageLabel.snp.makeConstraints { (make) in
            make.width.greaterThanOrEqualTo(16).priority(999)
            make.height.equalTo(16)
        }

        badgeStackView.isHidden = true
    }

    required  init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func additionalTagTypsForProps(_ props: ContactTableViewCellProps) -> [TagType] {
        if props.isRobot {
            return self.filterDisableTags(tags: [.robot], disableTags: props.disableTags)
        }

        var tagTyps: [TagType] = []

        if props.isLeader {
            tagTyps.append(.supervisor)
        }

        // 是管理员也是超级管理员，则只显示超级管理员
        if props.isSuperAdministrator {
            tagTyps.append(.tenantSuperAdmin)
        } else if props.isAdministrator {
            tagTyps.append(.tenantAdmin)
        }

        if !props.hasRegister {
            tagTyps.append(.unregistered)
        }

        return self.filterDisableTags(tags: tagTyps, disableTags: props.disableTags)
    }

    private func nameTagTypsForProps(_ props: ContactTableViewCellProps) -> [TagType] {
        var tagTyps: [TagType] = []
        if props.isSpecialFocus {
            tagTyps.append(.specialFocus)
        }
        if props.isExternal {
           tagTyps.append(.external)
        }
        if let user = props.user, user.workStatus.status == .onLeave {
           tagTyps.append(.onLeave)
        }
        return self.filterDisableTags(tags: tagTyps, disableTags: props.disableTags)
    }

    private func filterDisableTags(tags: [TagType], disableTags: [TagType]) -> [TagType] {
        if tags.isEmpty || disableTags.isEmpty {
            return tags
        }

        let result = tags.filter { (tag) -> Bool in
            return !disableTags.contains(tag)
        }

        return result
    }

    fileprivate var props: ContactTableViewCellProps = .empty {
        didSet {
            switch self.props.checkStatus {
            case .invalid:
                personInfoView.checkBox.isHidden = true
            case .selected:
                personInfoView.checkBox.isHidden = false
                updateCheckBox(selected: true, enabled: true)
            case .unselected:
                personInfoView.checkBox.isHidden = false
                updateCheckBox(selected: false, enabled: true)
            case .defaultSelected:
                personInfoView.checkBox.isHidden = false
                self.updateCheckBox(selected: true, enabled: false)
            case .disableToSelect:
                personInfoView.checkBox.isHidden = false
                self.updateCheckBox(selected: false, enabled: false)
            }

            if self.props.avatar != nil {
                personInfoView.avatarView.image = self.props.avatar
            } else {
                personInfoView.avatarView.setAvatarByIdentifier(self.props.entityId,
                                                                   avatarKey: self.props.avatarKey,
                                                                   medalKey: self.props.medalKey,
                                                                   medalFsUnit: "",
                                                                   scene: .Contact,
                                                                   avatarViewParams: .init(sizeType: .size(personInfoView.avatarSize)),
                                                                   backgroundColorWhenError: UIColor.ud.textPlaceholder)
            }

            personInfoView.nameLabel.text = props.name

            personInfoView.timeLabel.timeString = props.timeString
            if (props.description ?? "").isEmpty {
                personInfoView.infoLabel.isHidden = true
            } else {
                personInfoView.infoLabel.isHidden = false
                if let tenantContainerView = tenantContainerView,
                    let contactInfo = props.contactInfo {
                    // 占位使用
                    personInfoView.infoLabel.text = " "
                    if tenantContainerView.superview == nil {
                        personInfoView.infoLabel.addSubview(tenantContainerView)
                    }
                    tenantContainerView.snp.remakeConstraints { (make) in
                        make.left.top.bottom.equalToSuperview()
                        make.right.equalTo(personInfoView.infoLabel.superview?.snp.right ?? 0)
                    }
                    let v2CertificationInfo = tenantContainerView.transFormCertificationInfo(basicV1CertificationInfo: contactInfo.certificationInfo)
                    let tenantInfo = LarkTenantInfo(
                        tenantName: contactInfo.tenantName,
                        isFriend: true,
                        tenantNameStatus: contactInfo.tenantNameStatus,
                        certificationInfo: v2CertificationInfo,
                        tapCallback: nil)
                    tenantContainerView.config(tenantInfo: tenantInfo)
                } else {
                    personInfoView.infoLabel.text = props.description
                }
            }

            if let description = props.status {
                personInfoView.setDescription(NSAttributedString(string: description.text), descriptionType: ListItem.DescriptionType(rawValue: description.type.rawValue))
            } else {
                personInfoView.setDescription(NSAttributedString(string: ""), descriptionType: ListItem.DescriptionType.onDefault)
            }

            if let focusStatus = props.focusStatusList.topActive {
                let tagView = FocusTagView()
                tagView.config(with: focusStatus)
                personInfoView.setFocusTag(tagView)
            } else {
                personInfoView.setFocusIcon(nil)
            }

            var tagTypes = additionalTagTypsForProps(props)
            if !tagTypes.isEmpty {
                personInfoView.additionalIcon.isHidden = false
                personInfoView.additionalIcon.setTags(tagTypes)
            } else {
                personInfoView.additionalIcon.isHidden = true
            }

            arrowImageBgView.isHidden = !props.hasNext

            var autoSort = true
            let nameTagTypes = nameTagTypsForProps(props)
            var nameTags = nameTagTypes.map { tag in
                return Tag(type: tag)
            }
            if let tag = props.customTags {
                nameTags.append(contentsOf: tag)
                autoSort = false
            }
            personInfoView.nameTag.setElements(nameTags, autoSort: autoSort)
            personInfoView.nameTag.isHidden = nameTags.isEmpty

            personInfoView.bottomSeperator.backgroundColor = UIColor.ud.lineDividerDefault
            personInfoView.bottomSeperator.snp.remakeConstraints { (make) in
                make.left.equalTo(personInfoView.nameLabel.snp.left)
                make.height.equalTo(1 / UIScreen.main.scale)
                make.bottom.equalToSuperview()
                make.right.equalTo(self.snp.right)
            }
        }
    }

     func setProps(_ props: ContactTableViewCellProps) {
        self.props = props
    }

     func setProps(_ props: ContactTableViewCellProps, tenantNameService: LarkTenantNameService) {
         if tenantContainerView == nil {
             let tenantNameUIConfig = LarkTenantNameUIConfig(
                 tenantNameFont: UIFont.systemFont(ofSize: 14),
                 tenantNameColor: UIColor.ud.textPlaceholder,
                 isShowCompanyAuth: true,
                 isSupportAuthClick: false,
                 isOnlySingleLineDisplayed: true)
             tenantContainerView = tenantNameService.generateTenantNameView(with: tenantNameUIConfig)
         }
         setProps(props)
     }

     func updateCheckBox(selected: Bool, enabled: Bool) {
//        self.selectionStyle = enabled ? .default : .none
        personInfoView.checkBox.isEnabled = enabled
        personInfoView.checkBox.isSelected = selected
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }
}
