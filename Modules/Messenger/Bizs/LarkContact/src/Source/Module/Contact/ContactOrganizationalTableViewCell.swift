//
//  ContactOrganizationalTableViewCell.swift
//  LarkContact
//
//  Created by zhangxingcheng on 2021/9/13.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import LarkModel
import LarkCore
import LarkTag
import LarkListItem
import RustPB
import LarkProfile
import LarkLocalizations
import LarkFeatureGating
import LarkSearchCore

final class ContactOrganizationalTableViewCell: ContactTableViewCell {

    public lazy var personOrgInfoView: LarkOrganizationalListItem = {
        let personOrgInfoView = LarkOrganizationalListItem()
        // 有的场景会出现大于2个的情况，比如组织架构界面：未激活+超级管理员+负责人
        personOrgInfoView.additionalIcon.maxTagCount = 3
        personOrgInfoView.nameTag.maxTagCount = 3
        personOrgInfoView.avatarView.backgroundColor = UIColor.clear
        return personOrgInfoView
    }()

    private lazy var professionalStackView: ProfessionalStackView = {
        let professionalView = ProfessionalStackView()
        professionalView.axis = .horizontal
        professionalView.spacing = 8
        professionalView.alignment = .center
        professionalView.distribution = .fill
        professionalView.setContentHuggingPriority(.defaultLow - 2, for: .horizontal)
        professionalView.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        return professionalView
    }()

    public lazy var targetInfo: UIButton = {
        let targetInfo = UIButton(type: .custom)
        targetInfo.setImage(Resources.target_info, for: .normal)
        targetInfo.addTarget(self, action: #selector(handleTargetInfoTap), for: .touchUpInside)
        targetInfo.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        return targetInfo
    }()

    public var section: Int?
    public var row: Int?
    public weak var delegate: TargetInfoTapDelegate?

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    // 整行置灰蒙层
    private lazy var coverView: UIView = {
        let coverView = UIView()
        coverView.backgroundColor = UIColor.ud.bgBody
        coverView.alpha = 0.5
        return coverView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectedBackgroundView = BaseCellSelectView()
        self.backgroundColor = UIColor.ud.bgBody
        self.personInfoView.isHidden = true

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(personOrgInfoView)

        arrowImageBgView.setContentHuggingPriority(.required, for: .horizontal)
        arrowImageBgView.setContentCompressionResistancePriority(.required, for: .horizontal)
        stackView.addArrangedSubview(arrowImageBgView)

        personOrgInfoView.professionalStackView.addArrangedSubview(professionalStackView)
        professionalStackView.isHidden = true

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
        self.addSubview(targetInfo)

        self.contentView.addSubview(self.coverView)
        coverView.snp.makeConstraints { (make) in
            make.left.equalTo(self.personOrgInfoView.avatarView.snp.left)
            make.right.equalTo(self.personOrgInfoView.snp.right)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
        coverView.isHidden = true
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
           switch props.leaderType {
           case .enterpriseLeader:
               tagTyps.append(TagType.enterpriseSupervisor)
           case .mainLeader:
               tagTyps.append(TagType.mainSupervisor)
           case .subLeader:
               tagTyps.append(TagType.supervisor)
           @unknown default:
               break
           }
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
       if props.isExternal {
           tagTyps.append(.external)
       }
       if let user = props.user, user.workStatus.status == .onLeave {
           tagTyps.append(.onLeave)
       }
       if props.isSpecialFocus {
           tagTyps.append(.specialFocus)
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
           // 默认情况下没有半透明蒙层
           coverView.isHidden = true
           switch self.props.checkStatus {
           case .invalid:
               personOrgInfoView.checkBox.isHidden = true
           case .selected:
               personOrgInfoView.checkBox.isHidden = false
               updateOrgCheckBox(selected: true, enabled: true)
           case .unselected:
               personOrgInfoView.checkBox.isHidden = false
               updateOrgCheckBox(selected: false, enabled: true)
           case .defaultSelected:
               personOrgInfoView.checkBox.isHidden = false
               self.updateOrgCheckBox(selected: true, enabled: false)
               coverView.isHidden = false
           case .disableToSelect:
               personOrgInfoView.checkBox.isHidden = false
               self.updateOrgCheckBox(selected: false, enabled: false)
               coverView.isHidden = false
           }

           if self.props.avatar != nil {
               personOrgInfoView.avatarView.image = self.props.avatar
           } else {
               personOrgInfoView.avatarView.setAvatarByIdentifier(self.props.entityId,
                                                                  avatarKey: self.props.avatarKey,
                                                                  medalKey: self.props.medalKey,
                                                                  medalFsUnit: "",
                                                                  scene: .Contact,
                                                                  avatarViewParams: .init(sizeType: .size(personOrgInfoView.avatarSize)),
                                                                  backgroundColorWhenError: UIColor.ud.textPlaceholder)
           }

           personOrgInfoView.nameLabel.text = props.name

           personOrgInfoView.timeLabel.timeString = props.timeString

           personOrgInfoView.infoLabel.isHidden = (props.description ?? "").isEmpty
           personOrgInfoView.infoLabel.text = props.description

           if let description = props.status {
               personOrgInfoView.setDescription(NSAttributedString(string: description.text), descriptionType: LarkOrganizationalListItem.DescriptionType(rawValue: description.type.rawValue))
           } else {
               personOrgInfoView.setDescription(NSAttributedString(string: ""), descriptionType: LarkOrganizationalListItem.DescriptionType.onDefault)
           }

           let tagTypes = additionalTagTypsForProps(props)
           if !tagTypes.isEmpty {
               personOrgInfoView.additionalIcon.isHidden = false
               personOrgInfoView.additionalIcon.setTags(tagTypes)
           } else {
               personOrgInfoView.additionalIcon.isHidden = true
           }

           arrowImageBgView.isHidden = !props.hasNext

           // 当存在自定义标签时，替换掉外部标签
           let tagElements = nameTagTypsForProps(props).map { tagType -> TagElement in
               if tagType == .external, let tagTitle = props.tagData?.tagDataItems.first?.textVal {
                   return Tag(title: tagTitle,
                                       image: nil,
                                       style: .blue,
                                       type: .customTitleTag)
               } else {
                   return tagType
               }
           }

           personOrgInfoView.nameTag.setElements(tagElements)
           personOrgInfoView.nameTag.isHidden = tagElements.isEmpty

           personOrgInfoView.bottomSeperator.backgroundColor = UIColor.ud.lineDividerDefault
           personOrgInfoView.bottomSeperator.snp.remakeConstraints { (make) in
               make.left.equalTo(personOrgInfoView.nameLabel.snp.left)
               make.height.equalTo(1 / UIScreen.main.scale)
               make.bottom.equalToSuperview()
               make.right.equalTo(self.snp.right)
           }

           //组织架构屏蔽掉 subtitle
           //            personInfoView.nameStatusAndInfoStackView.isHidden = true
           let profileFieldsArray = props.profileFieldsDic[self.props.entityId ?? ""]
           if profileFieldsArray?.isEmpty ?? true {
               professionalStackView.isHidden = true
           } else if profileFieldsArray?.count == 1 {
               professionalStackView.isHidden = false
               guard let userProfileField = profileFieldsArray?[0] as? UserProfileField else {
                   return
               }
               professionalStackView.firstTitle.text = self.getProfileFieldTitle(profileField: userProfileField)
               if professionalStackView.firstTitle.text?.isEmpty ?? true {
                   //空字符串隐藏
                   professionalStackView.isHidden = true
               } else {
                   professionalStackView.updateProfessionalStackViewUI(titleStatus: .oneTitleStatus)
               }
           } else if profileFieldsArray?.count ?? 2 > 1 {
               guard let userProfileField1 = profileFieldsArray?[0] as? UserProfileField else {
                   //出现脏数据则返回
                   return
               }
               guard let userProfileField2 = profileFieldsArray?[1] as? UserProfileField else {
                   //出现脏数据则返回
                   return
               }

               professionalStackView.firstTitle.text = self.getProfileFieldTitle(profileField: userProfileField1)
               professionalStackView.secondTitle.text = self.getProfileFieldTitle(profileField: userProfileField2)

               if professionalStackView.firstTitle.text?.isEmpty ?? true && professionalStackView.secondTitle.text?.isEmpty ?? true {
                   //两个值都为空
                   professionalStackView.isHidden = true
               } else if professionalStackView.firstTitle.text?.isEmpty ?? true && !(professionalStackView.secondTitle.text?.isEmpty ?? true) {
                   //第一个值为空，第二个值不为空
                   professionalStackView.isHidden = false
                   professionalStackView.firstTitle.text = self.getProfileFieldTitle(profileField: userProfileField2)
                   professionalStackView.updateProfessionalStackViewUI(titleStatus: .oneTitleStatus)
               } else if !(professionalStackView.firstTitle.text?.isEmpty ?? true) && professionalStackView.secondTitle.text?.isEmpty ?? true {
                   //第一个值不为空，第二个值为空
                   professionalStackView.isHidden = false
                   professionalStackView.firstTitle.text = self.getProfileFieldTitle(profileField: userProfileField1)
                   professionalStackView.updateProfessionalStackViewUI(titleStatus: .oneTitleStatus)
               } else if !(professionalStackView.firstTitle.text?.isEmpty ?? true) && !(professionalStackView.secondTitle.text?.isEmpty ?? true) {
                   //两个值都不为空
                   professionalStackView.isHidden = false
                   professionalStackView.firstTitle.text = self.getProfileFieldTitle(profileField: userProfileField1)
                   professionalStackView.secondTitle.text = self.getProfileFieldTitle(profileField: userProfileField2)
                   professionalStackView.updateProfessionalStackViewUI(titleStatus: .doubleTitleStatus)
               }
           }
           if props.targetPreview && !props.hasNext {
               targetInfo.isHidden = false
               stackView.snp.remakeConstraints { (make) in
                   make.leading.top.bottom.equalToSuperview()
                   make.trailing.equalToSuperview().offset(-Self.Layout.personInfoMargin)
               }
               targetInfo.snp.makeConstraints { (make) in
                   make.leading.equalTo(stackView.snp.trailing).offset(8)
                   make.trailing.equalToSuperview().offset(-Self.Layout.targetInfoMargin)
                   make.centerY.equalToSuperview()
               }
           } else {
               targetInfo.isHidden = true
               stackView.snp.remakeConstraints { (make) in
                   make.edges.equalToSuperview()
               }
           }
       }
   }

    @objc
    func handleTargetInfoTap() {
        self.delegate?.presentPreviewViewController(section: section, row: row)
    }

   func getProfileFieldTitle(profileField: UserProfileField) -> String {
       switch profileField {
       case .text(let textTitle):
           let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
           guard let profileTitle = textTitle.text.i18NVals[currentLocalizations] else {
               return textTitle.text.defaultVal
           }
           if profileTitle.isEmpty {
               return textTitle.text.defaultVal
           }
           return profileTitle
       case .link(let link):
           return link.title.getString()
       case .cAlias(let cAlias):
           let currentLocalizations = LanguageManager.currentLanguage.rawValue.lowercased()
           guard let cAliasTitle = cAlias.text.i18NVals[currentLocalizations] else {
               return cAlias.text.defaultVal
           }
           if cAliasTitle.isEmpty {
               return cAlias.text.defaultVal
           }
           return cAliasTitle
       default:
           break
       }
       return ""
   }

    func setOrgProps(_ props: ContactTableViewCellProps) {
       self.props = props
   }

    func updateOrgCheckBox(selected: Bool, enabled: Bool) {
       self.selectionStyle = enabled ? .default : .none
        personOrgInfoView.checkBox.isEnabled = enabled
        personOrgInfoView.checkBox.isSelected = selected
   }
}

enum ProfessionalTitleStatus: Int {
   case oneTitleStatus
   case doubleTitleStatus
}

final class ProfessionalStackView: UIStackView {
   public let firstTitle = UILabel()
   public let secondTitle = UILabel()
   public let verticalLineView = UIView()

   public override init(frame: CGRect) {
       super.init(frame: frame)
       self.firstTitle.font = UIFont.systemFont(ofSize: 12)
       self.firstTitle.textAlignment = .left
       self.firstTitle.textColor = UIColor.ud.N500
       self.firstTitle.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
       self.firstTitle.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

       self.verticalLineView.backgroundColor = UIColor.ud.lineDividerDefault

       self.secondTitle.font = UIFont.systemFont(ofSize: 12)
       self.secondTitle.textAlignment = .left
       self.secondTitle.textColor = UIColor.ud.N500
       self.secondTitle.setContentHuggingPriority(.defaultLow - 1, for: .horizontal)
       self.secondTitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

       self.addArrangedSubview(self.firstTitle)
       self.addArrangedSubview(self.verticalLineView)
       self.addArrangedSubview(self.secondTitle)

       self.firstTitle.snp.makeConstraints { (make) in
           make.centerY.equalTo(self)
           make.left.equalTo(self).offset(0.0)
           make.right.equalTo(self.verticalLineView.snp.left).offset(-8.0)
       }
       self.verticalLineView.snp.makeConstraints { (make) in
           make.centerY.equalTo(self)
           make.left.equalTo(self.firstTitle.snp.right).offset(8.0)
           make.width.equalTo(1)
           make.height.equalTo(10)
       }
       self.secondTitle.snp.makeConstraints { (make) in
           make.centerY.equalTo(self)
           make.left.equalTo(self.verticalLineView.snp.right).offset(8.0)
           make.width.greaterThanOrEqualTo(70)
       }
   }

   /**更新UI布局*/
   public func updateProfessionalStackViewUI(titleStatus: ProfessionalTitleStatus) {
       switch titleStatus {
       case .oneTitleStatus:
           self.verticalLineView.isHidden = true
           self.secondTitle.isHidden = true
           self.firstTitle.snp.remakeConstraints { (make) in
               make.centerY.equalTo(self)
               make.left.equalTo(self).offset(0.0)
               make.right.equalTo(self).offset(0.0)
           }
       case .doubleTitleStatus:
           self.doubleTitleSnp()
       default:
           self.doubleTitleSnp()
       }
   }

   public func doubleTitleSnp() {
       self.verticalLineView.isHidden = false
       self.secondTitle.isHidden = false
       self.firstTitle.snp.remakeConstraints { (make) in
           make.centerY.equalTo(self)
           make.left.equalTo(self).offset(0.0)
           make.right.equalTo(self.verticalLineView.snp.left).offset(-8.0)
       }
       self.verticalLineView.snp.remakeConstraints { (make) in
           make.centerY.equalTo(self)
           make.left.equalTo(self.firstTitle.snp.right).offset(8.0)
           make.width.equalTo(1)
           make.height.equalTo(10)
       }
       self.secondTitle.snp.remakeConstraints { (make) in
           make.centerY.equalTo(self)
           make.left.equalTo(self.verticalLineView.snp.right).offset(8.0)
           make.width.greaterThanOrEqualTo(70)
       }
   }

   required public init(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
   }
}

extension ContactOrganizationalTableViewCell {
    final class Layout {
        //根据UI设计图而来
        static let infoIconWidth: CGFloat = 20
        static let personInfoMargin: CGFloat = 8 + 20 + 16
        static let targetInfoMargin: CGFloat = 16
    }
}
