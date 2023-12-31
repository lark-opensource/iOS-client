//
//  MailAddressCell.swift
//  LarkMailTokenInputView
//
//  Created by majx on 2019/5/28.
//

import Foundation
import UIKit
import SnapKit

protocol MailAddressCellDelegate: AnyObject {
    func deleteExternAddress(_ viewModel: MailAddressCellViewModel)
}

struct MailAddressCellViewModel: Equatable {
    var name: String = ""
    var searchName: String = ""
    var address: String = ""
    var avatar: String = ""

    var isSelected: Bool = false
    var avatarKey: String? // 给imageService使用
    var tags: [ContactTagType]?
    var type: ContactType?
    var larkID: String = "" // 对于不知道email的会有一个larkID
    var tenantId: String = "" //
    var subtitle = ""
    var titleHitTerms = [String]()
    var emailHitTerms = [String]()
    var departmentHitTerms = [String]()
    var groupType: MailClientGroupType? // = .chatMailGroup
    var displayName: String = ""
    var chatGroupMembersCount: Int64? = 0
    var currentTenantID: String?

    var isExternal: Bool {
        return tenantId.isEmpty || tenantId != currentTenantID
    }

    var mailDisplayName: String {
        return !searchName.isEmpty ? searchName : (!displayName.isEmpty ? displayName : name)
    }
    static func == (lhs: MailAddressCellViewModel,
                   rhs: MailAddressCellViewModel) -> Bool {
        return lhs.address == rhs.address &&
            lhs.name == rhs.name &&
            lhs.larkID == rhs.larkID &&
            lhs.tenantId == rhs.tenantId

    }

    static func make(from addressModel: MailSendAddressModel, currentTenantID: String) -> MailAddressCellViewModel {
        var viewModel = MailAddressCellViewModel()
        viewModel.name = addressModel.name
        viewModel.searchName = addressModel.searchName
        viewModel.address = addressModel.address
        viewModel.avatar = addressModel.avatar
        viewModel.isSelected = false
        viewModel.avatarKey = addressModel.avatarKey
        viewModel.tags = addressModel.tags
        viewModel.type = addressModel.type
        viewModel.larkID = addressModel.larkID ?? ""
        viewModel.tenantId = addressModel.tenantID ?? ""
        viewModel.subtitle = addressModel.subtitle
        viewModel.titleHitTerms = addressModel.titleHitTerms
        viewModel.emailHitTerms = addressModel.emailHitTerms
        viewModel.departmentHitTerms = addressModel.departmentHitTerms
        viewModel.displayName = addressModel.displayName ?? ""
        viewModel.chatGroupMembersCount = addressModel.chatGroupMembersCount
        viewModel.currentTenantID = currentTenantID
        return viewModel
    }
}

struct MailAddressCellConfig {
    static let height: CGFloat = 56
    static let identifier = "MailAddressCell"
}

// 邮件地址Cell
class MailAddressCell: UITableViewCell {
    var viewModel: MailAddressCellViewModel?
    var setImageTask: SetImageTask?
    var nameCenterConstraint: Constraint?
    private let nameColor = UIColor.ud.textTitle
    private let addressSubtitleColor = UIColor.ud.textPlaceholder
    var contactTagView = MailThreadCustomTagWrapper()
    weak var delegate: MailAddressCellDelegate?
    let rightMargin: CGFloat = 16 + 16 + 16
    let parenthesesSpace: CGFloat = 8 // 中文括号单边（）空白
    let labelRightMargin: CGFloat = 48 - 4 // 4是文字空白
    let nameAdDistance: CGFloat = 4
    let labelTagDistance: CGFloat = 8
    let deleteBtnMargin: CGFloat = 16
    let deleteBtnWidth: CGFloat = 16
    let memberCountRightMargin = 8
    let avatarWidth: CGFloat = 36
    let avatarLeftMargin: CGFloat = 16
    let avatarRightMargin: CGFloat = 12
    let avatarAreaWidth: CGFloat = 36 + 16 + 12

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.layer.zPosition = 0
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(memberCountLabel)
        contentView.addSubview(addressLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(contactTagView)
        contentView.addSubview(deleteBtn)
        contentView.addSubview(bgBackView)

        avatarImageView.setContentHuggingPriority(.required, for: .horizontal)
        avatarImageView.setContentCompressionResistancePriority(.required, for: .horizontal)

        nameLabel.setContentHuggingPriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        memberCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        memberCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        addressLabel.setContentHuggingPriority(.required, for: .horizontal)
        addressLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        contactTagView.setContentHuggingPriority(.required, for: .horizontal)
        contactTagView.setContentCompressionResistancePriority(.required, for: .horizontal)

        subtitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        avatarImageView.addSubview(defaultNameLabel)
        avatarImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(avatarLeftMargin).priority(.required)
            make.size.equalTo(avatarWidth).priority(.required)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalTo(8)
            make.left.equalTo(avatarImageView.snp.right).offset(avatarRightMargin).priority(.required)
            self.nameCenterConstraint = make.centerY.equalTo(avatarImageView).constraint
            self.nameCenterConstraint?.isActive = false
        }
        memberCountLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(nameLabel.snp.centerY).priority(.required)
            make.left.equalTo(nameLabel.snp.right).priority(.required)
            make.right.lessThanOrEqualToSuperview().offset(-labelRightMargin).priority(.required)
        }
        subtitleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.left)
            make.right.lessThanOrEqualToSuperview().offset(-labelRightMargin).priority(.required)
            make.bottom.equalTo(-8)
        }
        defaultNameLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(20)
        }
        deleteBtn.snp.makeConstraints { (make) in
            make.width.height.equalTo(deleteBtnWidth)
            make.centerY.equalTo(nameLabel.snp.centerY)
            make.right.equalToSuperview().offset(-deleteBtnMargin)
        }
        bgBackView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled else { return nil }
        guard !isHidden else { return nil }
        guard alpha >= 0.01 else { return nil }
        guard self.point(inside: point, with: event) else { return nil }
        for subview in self.contentView.subviews {
            let relatePoint = self.convert(point, to: subview)
            if let candidate = subview.hitTest(relatePoint, with: event){
                return candidate
            }
        }
        return self
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.bgBackView.isHidden = !selected
    }

    // addressLabel、contactTag更新前要设置好isHidden；memberCountLabel不显示的话设成""
    func updateView() {
        addressLabel.snp.removeConstraints()
        contactTagView.snp.removeConstraints()
        let addressLabelIsHidden = addressLabel.isHidden

        if !addressLabelIsHidden {
            addressLabel.snp.makeConstraints { (make) in
                make.centerY.equalTo(nameLabel.snp.centerY)
                make.left.equalTo(memberCountLabel.snp.right).offset(nameAdDistance).priority(.required)
                make.right.lessThanOrEqualToSuperview().offset(-labelRightMargin).priority(.required)
            }
        } else {
            addressLabel.snp.makeConstraints { (make) in
                make.left.equalTo(memberCountLabel.snp.right).priority(.required)
            }
        }

        if !contactTagView.isHidden {
            contactTagView.snp.makeConstraints { (make) in
                if addressLabelIsHidden {
                    make.left.equalTo(memberCountLabel.snp.right).offset(labelTagDistance).priority(.required)
                } else {
                    make.left.equalTo(addressLabel.snp.right).offset(labelTagDistance).priority(.required)
                }
                make.right.lessThanOrEqualToSuperview().offset(-rightMargin).priority(.required)
                make.centerY.equalTo(nameLabel)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.textColor = nameColor
        memberCountLabel.textColor = nameColor
        addressLabel.textColor = addressSubtitleColor
        subtitleLabel.textColor = addressSubtitleColor
        contactTagView.isHidden = true
        deleteBtn.isHidden = true
    }

    func update(newModel: MailAddressCellViewModel) {
        viewModel = newModel
        nameLabel.text = newModel.mailDisplayName
        addressLabel.text = newModel.address
        subtitleLabel.text = newModel.subtitle
        if newModel.titleHitTerms.count > 0 {
            let nameAttributed = NSAttributedString(string: newModel.mailDisplayName, attributes: [.font: nameLabel.font, .foregroundColor: nameLabel.textColor])
            nameLabel.attributedText = SearchHelper.AttributeText.searchHighlightAttributeText(attributedString: nameAttributed,
                                                                                               keywords: newModel.titleHitTerms,
                                                                                               highlightColor: UIColor.ud.primaryContentDefault)
        }
        if newModel.emailHitTerms.count > 0 {
            let addressAttributed = NSAttributedString(string: newModel.address, attributes: [.font: addressLabel.font, .foregroundColor: addressLabel.textColor])
            addressLabel.attributedText = SearchHelper.AttributeText.searchHighlightAttributeText(attributedString: addressAttributed,
                                                                                                  keywords: newModel.emailHitTerms,
                                                                                                  highlightColor: UIColor.ud.primaryContentDefault)
        }
        if newModel.departmentHitTerms.count > 0 {
            let departmentAttributed = NSAttributedString(string: newModel.subtitle, attributes: [.font: subtitleLabel.font, .foregroundColor: subtitleLabel.textColor])
            subtitleLabel.attributedText = SearchHelper.AttributeText.searchHighlightAttributeText(attributedString: departmentAttributed,
                                                                                                   keywords: newModel.departmentHitTerms,
                                                                                                   highlightColor: UIColor.ud.primaryContentDefault)
        }

        if let addressAttributedText = addressLabel.attributedText {
            let address = NSMutableAttributedString(string: "")
            address.append(NSAttributedString(string: "<"))
            address.append(addressAttributedText)
            address.append(NSAttributedString(string: ">"))
            addressLabel.attributedText = address
        }
        var tagText = getTagText(tags: newModel.tags)
        deleteBtn.isHidden = !showDeleteBtn(tags: newModel.tags)
        setContactTagView(tagText: tagText)
        var nameLabelIsTruncated = false // 查看nameLabel是否会被截断
        var shallShowAd = false // 剩余位置太小address不应显示

        var memberCount = ""
        let isGroup = newModel.tags?.first == .tagChatGroupNormal ||
            newModel.tags?.first == .tagChatGroupDepartment ||
            newModel.tags?.first == .tagChatGroupSuper ||
            newModel.tags?.first == .tagChatGroupTenant
        if isGroup, let count = newModel.chatGroupMembersCount, count != 0 {
            memberCount = "(\(count))"
        }
        func judgeAdAndNameIsHidden() {
            let maxLabelTagWidth: CGFloat = contentView.frame.width - avatarAreaWidth - ((tagText.isEmpty) ? labelRightMargin : rightMargin)
            let tagWidth = ((tagText.isEmpty) ? 0 : tagText.getTextWidth(fontSize: 11))
            let memberCounWidth = (" " + memberCount).getTextWidth(fontSize: 16)
            let maxNameAdWidth = maxLabelTagWidth - tagWidth - memberCounWidth

            let nameWidth = (nameLabel.text ?? "").getTextWidth(fontSize: 16)
            if maxNameAdWidth < nameWidth {
                nameLabelIsTruncated = true
                return
            }
            nameLabelIsTruncated = false
            guard newModel.tags?.first != .tagChatGroupTenant,
                  newModel.tags?.first != .tagChatGroupSuper,
                  newModel.tags?.first != .tagChatGroupDepartment,
                  newModel.tags?.first != .tagChatGroupNormal,
                  let address = addressLabel.text else { return }
            let adWidth = min(address.getTextWidth(fontSize: 14), "<...".getTextWidth(fontSize: 14))
            guard adWidth > 0.1 else { return }
            let maxAdWidth = maxNameAdWidth - labelTagDistance - nameAdDistance
            shallShowAd = maxAdWidth >= adWidth
        }
        judgeAdAndNameIsHidden()
        addressLabel.isHidden = !shallShowAd // 还要补充另外一个type为chatter才设置为空
        if newModel.type == .group, !memberCount.isEmpty {
            memberCountLabel.text = ((nameLabelIsTruncated) ? "" : " ") + memberCount // 要有一个文字空格的距离，如果有截断，截断后面会有空白
        } else {
            memberCountLabel.text = ""
        }
        avatarImageView.backgroundColor = UIColor.ud.N300
        if let task = setImageTask {
            task.cancel()
        }
        if let subtitle = subtitleLabel.text, !subtitle.isEmpty {
            self.nameCenterConstraint?.deactivate()
            subtitleLabel.isHidden = false
        } else {
            self.nameCenterConstraint?.activate()
            subtitleLabel.isHidden = true
        }
        if let avatarKey = newModel.avatarKey, !avatarKey.isEmpty {
            defaultNameLabel.isHidden = true
            setImageTask = ProviderManager.default.imageProvider?.setAvatar(avatarImageView,
                                                                            key: avatarKey,
                                                                            entityId: newModel.larkID,
                                                                            avatarImageParams: nil,
                                                                            placeholder: I18n.image(named: "avatar_placeholder"),
                                                                            progress: nil, completion: nil)
        } else {
            if (newModel.type == .group || newModel.type == .enterpriseMailGroup) {
                avatarImageView.image = Resources.mail_contact_group_icon
                defaultNameLabel.isHidden = true
            } else {
                avatarImageView.image = I18n.image(named: "member_avatar_background")
                if let firstName = newModel.mailDisplayName.first {
                    defaultNameLabel.text = String(firstName)
                } else {
                    defaultNameLabel.text = ""
                }
                defaultNameLabel.isHidden = false
            }
        }
        updateView()
    }

    func showDeleteBtn(tags: [ContactTagType]?) -> Bool {
        return tags?.first == .tagExternalContact && FeatureManager.open(.deleteExtern)
    }

    func getTagText(tags: [ContactTagType]?) -> String {
        var tagText = ""
        let tagType = tags?.first
        if tagType == .tagMailGroup {
            tagText = BundleI18n.MailSDK.Mail_MailingList_MailingList   //邮件组
        } else if tagType == .tagChatGroupSuper {
            tagText = BundleI18n.MailSDK.Mail_Edit_Supergroup
        } else if tagType == .tagChatGroupTenant {
            tagText = BundleI18n.MailSDK.Mail_Edit_All
        } else if tagType == .tagChatGroupDepartment {
            tagText = BundleI18n.MailSDK.Mail_Edit_Department
        } else if tagType == .tagNameCard {
            tagText = BundleI18n.MailSDK.Mail_Normal_ContactCard    //邮箱联系人
        } else if tagType == .tagExternalContact && !Store.settingData.mailClient {
            tagText = BundleI18n.MailSDK.Mail_Search_External   //外部
        } else if tagType == .tagSharedMailbox {
            tagText = BundleI18n.MailSDK.Mail_Search_PublicMailbox  //公共邮箱
        }
        return tagText
    }

    func setContactTagView(tagText: String) {
        if tagText.count == 0 {
            contactTagView.isHidden = true
        } else {
            contactTagView.isHidden = false
            contactTagView.maxTagCount = 1

            let commonView = CommonCustomTagView.createTagView(text: tagText,
                                                               fontColor: UIColor.ud.udtokenTagTextSBlue,
                                                               bgColor: UIColor.ud.udtokenTagBgBlue)
            contactTagView.setElements([commonView])
            commonView.snp.removeConstraints()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc
    private func deleteAddressClick() {
        if let model = self.viewModel {
            self.delegate?.deleteExternAddress(model)
        }
    }

    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = avatarWidth / 2.0
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = nameColor
        return label
    }()

    private lazy var memberCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = nameColor
        return label
    }()

    private lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = addressSubtitleColor
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = addressSubtitleColor
        return label
    }()

    private lazy var defaultNameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = UIColor.ud.primaryOnPrimaryFill
        label.backgroundColor = .clear
        return label
    }()

    private lazy var deleteBtn: UIButton = {
        let closeButton = UIButton()
        closeButton.setImage(Resources.smartInbox_card_close.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.addTarget(self, action: #selector(deleteAddressClick), for: .touchUpInside)
        closeButton.tintColor = UIColor.ud.iconN3
        closeButton.hitTestEdgeInsets = UIEdgeInsets(top: -12, left: -12, bottom: -12, right: -12)
        return closeButton
    }()
    private lazy var bgBackView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.fillSelected
        view.isHidden = true
        return view
    }()
}
