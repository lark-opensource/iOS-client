//
//  ShareLinkEntrancePanel.swift
//  SpaceKit
//
//  Created by 杨子曦 on 2020/1/9.

import UIKit
import Foundation
import EENavigator
import SKUIKit
import LarkLocalizations
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignTag
import UniverseDesignToast

protocol ShareLinkEntrancePanelDelegate: AnyObject {
    func didClickedShareEntrancePanel(panel: ShareLinkEntrancePanel,
                                      chosenType: ShareLinkChoice?)
}

class ShareLinkEntrancePanel: UIControl {
    private weak var delegate: ShareLinkEntrancePanelDelegate?
    private var publicPermissions: PublicPermissionMeta?
    private var userPermissions: UserPermissionAbility?

    // fullAccess为true
    private var chosenType: ShareLinkChoice? = .close
    private var subTitle: String = ""
    
    var searchSettingEnable: Bool {
        guard UserScopeNoChangeFG.PLF.searchEntityEnable else {
            DocsLogger.info("ShareLinkEntrancePanel.searchSettingEnable: fg is disabled", component: LogComponents.permission)
            return false
        }
        guard shareEntity.wikiV2SingleContainer || shareEntity.spaceSingleContainer else {
            DocsLogger.info("ShareLinkEntrancePanel.searchSettingEnable: not wiki2.0 or space2.0", component: LogComponents.permission)
            return false
        }
        guard !shareEntity.isFolder && ![.minutes, .form].contains(shareEntity.type) else {
            DocsLogger.info("ShareLinkEntrancePanel.searchSettingEnable: docType is disabled", component: LogComponents.permission)
            return false
        }
        guard User.current.info?.isToNewC == false else {
            DocsLogger.info("ShareLinkEntrancePanel.searchSettingEnable: is to c user", component: LogComponents.permission)
            return false
        }
        guard publicPermissions?.searchEntity == .tenantCanSearch else {
            DocsLogger.info("ShareLinkEntrancePanel.searchSettingEnable: searchEntity is't tenantCanSearch", component: LogComponents.permission)
            return false
        }
        return true
    }
    
    var hasPassword: Bool {
        return publicPermissions?.hasLinkPassword == true && publicPermissions?.linkPassword.isEmpty == false
    }

    private lazy var iconView: UIImageView = {
        let i = UIImageView()
        i.contentMode = .scaleAspectFit
        i.image = UDIcon.linkCopyOutlined.withRenderingMode(.alwaysTemplate)
        i.tintColor = UDColor.iconN1
        return i
    }()

    // 链接分享是否开启，影响 icon
    private var linkShareEnabled = true {
        didSet {
            iconView.image = linkShareEnabled
                ? UDIcon.linkCopyOutlined.withRenderingMode(.alwaysTemplate)
                : UDIcon.cancelLinkOutlined.withRenderingMode(.alwaysTemplate)
        }
    }
    
    private var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textDisabled
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.text = LinkType.Sub.linkForOrgReadDes.text
        return label
    }()

    private lazy var singlePageTag: UDTag = {
        let config = UDTagConfig.TextConfig(cornerRadius: 4,
                                            textColor: UDColor.udtokenTagTextSBlue,
                                            backgroundColor: UDColor.udtokenTagBgBlue)
        let tag = UDTag(text: BundleI18n.SKResource.CreationMobile_Wiki_Perm_ExternalShare_Current_tag,
                        textConfig: config)
        tag.isHidden = true
        return tag
    }()
    
    private lazy var subTitleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UDColor.textCaption
        l.font = UIFont.systemFont(ofSize: 14)
        l.numberOfLines = 0
        l.isHidden = true
        return l
    }()
    
    lazy var arrowImageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate)
        view.tintColor = UDColor.textPlaceholder
        return view
    }()
    
    private lazy var splitView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    private let shareEntity: SKShareEntity

    // 置灰场景，设置此属性
    override var isEnabled: Bool {
        didSet {
            if isEnabled {
                iconView.tintColor = UDColor.iconN1
                nameLabel.textColor = UDColor.textTitle
                arrowImageView.tintColor = UDColor.textPlaceholder
                if !shareEntity.isFormV1 {
                    // 非表单场景多更新下 subtitleLabel
                    subTitleLabel.textColor = UDColor.textCaption
                }
                if shareEntity.bitableShareEntity?.meta?.isPublicPermissionToBeSet == true {
                    nameLabel.textColor = UDColor.textPlaceholder
                }
            } else {
                iconView.tintColor = UDColor.iconDisabled
                nameLabel.textColor = UDColor.textDisabled
                arrowImageView.tintColor = UDColor.iconDisabled
                if !shareEntity.isFormV1 {
                    // 非表单场景多更新下 subtitleLabel
                    subTitleLabel.textColor = UDColor.textDisabled
                }
            }
        }
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UDColor.fillPressed : UDColor.bgFloat
        }
    }
    
    init(_ shareEntity: SKShareEntity,
         delegate: ShareLinkEntrancePanelDelegate?) {
        self.shareEntity = shareEntity
        self.delegate = delegate
        super.init(frame: .zero)
        backgroundColor = UDColor.bgFloat
        isUserInteractionEnabled = false
        isEnabled = false
        if shareEntity.isFormV1 || shareEntity.isBitableSubShare {
            setupViewForForm()
        } else {
            setupView()
        }
        addTapGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showSplitBottom(show: Bool) {
        splitView.isHidden = !show
    }
    
    private func setupView() {
        addSubview(iconView)
        addSubview(splitView)
        addSubview(arrowImageView)

        let labelStackView = UIStackView(arrangedSubviews: [nameLabel, singlePageTag, subTitleLabel])
        labelStackView.axis = .vertical
        labelStackView.spacing = 4
        labelStackView.alignment = .leading
        labelStackView.distribution = .fill
        labelStackView.isUserInteractionEnabled = false
        addSubview(labelStackView)

        iconView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
            make.left.equalToSuperview().offset(16)
        }
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
            make.height.width.equalTo(20)
        }
        labelStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.left.equalTo(iconView.snp.right).offset(12)
            make.right.equalTo(arrowImageView.snp.left).offset(-12)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(22)
        }
        subTitleLabel.snp.makeConstraints { (make) in
            make.height.greaterThanOrEqualTo(20)
        }
        splitView.snp.makeConstraints { (make) in
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.equalTo(iconView)
        }
    }

    private func setupViewForForm() {
        addSubview(iconView)
        addSubview(nameLabel)
        addSubview(splitView)
        addSubview(arrowImageView)
        
        // Bitable 分享下，更改默认文案
        if shareEntity.isForm {
            nameLabel.text = LinkType.FormSub.onlyInvitedCanWriteDes.text
        } else if shareEntity.isBitableSubShare {
            nameLabel.text = LinkType.BitableSub.onlyInvitedPeopleCanView.text
        }

        iconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(16)
            make.width.height.equalTo(20)
        }

        nameLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.greaterThanOrEqualTo(22)
            make.top.bottom.equalToSuperview().inset(15)
            make.left.equalTo(iconView.snp.right).offset(12)
            make.right.lessThanOrEqualTo(arrowImageView.snp.left).offset(-12)
        }

        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.height.width.equalTo(20)
        }

        splitView.snp.makeConstraints { (make) in
            make.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.equalTo(iconView)
        }
    }

    
    private func addTapGesture() {
        addTarget(self, action: #selector(didReceiveTap), for: .touchUpInside)
    }
    
    @objc
    private func didReceiveTap() {
        delegate?.didClickedShareEntrancePanel(panel: self, chosenType: chosenType)
    }
}

extension ShareLinkEntrancePanel {
    func updateByApplicationConfig(_ close: Bool) {
        isUserInteractionEnabled = !close
        arrowImageView.isHidden = close
    }

    public func updateUserAndPublicPermissions(userPermissions: UserPermissionAbility?, publicPermissions: PublicPermissionMeta?) {
        self.userPermissions = userPermissions
        self.publicPermissions = publicPermissions
        let fullAccess = userPermissions?.canManageMeta() ?? true
        var isOwner = shareEntity.isOwner
        if let publicPermissions = publicPermissions {
            isOwner = publicPermissions.isOwner
        } else {
            iconView.tintColor = UDColor.iconDisabled
            arrowImageView.tintColor = UDColor.iconDisabled
        }
        if shareEntity.isFormV1 {
            self.isEnabled = shareEntity.formCanShare
            isUserInteractionEnabled = userPermissions?.canShare() ?? true
        } else if shareEntity.isBitableSubShare {
            self.isEnabled = shareEntity.bitableShareEntity?.isShareOn ?? false
            isUserInteractionEnabled = userPermissions?.canShare() ?? false
        } else if shareEntity.wikiV2SingleContainer {
            self.isEnabled = true
            isUserInteractionEnabled = isOwner ||
                (userPermissions?.canManageMeta() ?? true) ||
                (userPermissions?.canSinglePageManageMeta() ?? true)
        } else if shareEntity.spaceSingleContainer && shareEntity.isFolder {
            self.isEnabled = true
            isUserInteractionEnabled = isOwner || (userPermissions?.canManageMeta() ?? true)
        } else if shareEntity.isSyncedBlock {
            self.isEnabled = true
            isUserInteractionEnabled = true
        } else {
            self.isEnabled = true
            isUserInteractionEnabled = isOwner || fullAccess
        }
        if shareEntity.isSyncedBlock {
            arrowImageView.isHidden = true
        } else {
            arrowImageView.isHidden = !isUserInteractionEnabled
        }
        if shareEntity.isFormV1 {
            updateLabelForForm(publicPermissions: publicPermissions)
        } else if shareEntity.isBitableSubShare {
            updateLabelForBitable(publicPermissions: publicPermissions)
        } else if shareEntity.isFolder {
            updateLabelForShareFolder(publicPermissions: publicPermissions)
        } else {
            updateLabelForFile(publicPermissions: publicPermissions)
        }

        if shareEntity.wikiV2SingleContainer, publicPermissions?.permTypeValue?.linkShareEntity == .singlePage {
            singlePageTag.isHidden = false
        } else {
            singlePageTag.isHidden = true
        }
    }

    private func updateLabelForForm(publicPermissions: PublicPermissionMeta?) {
        guard let publicPermissions = publicPermissions else { return }
        if publicPermissions.linkShareEntity == .anyoneCanEdit {
            updateLinkShareChoice(type: .anybodyKnownLinkCanWriteDes, chosenType: .anyoneEdit)
            linkShareEnabled = true
        } else if publicPermissions.linkShareEntity == .tenantCanEdit {
            updateLinkShareChoice(type: .orgMemberCanWriteDes, chosenType: .orgEdit)
            linkShareEnabled = true
        } else if publicPermissions.linkShareEntity == .close {
            updateLinkShareChoice(type: .onlyInvitedCanWriteDes, chosenType: .close)
            linkShareEnabled = false
        } else {
            DocsLogger.warning("没有这种类型")
            spaceAssertionFailure()
        }
        self.updateLabelText()
    }
    
    private func updateLabelForBitable(publicPermissions: PublicPermissionMeta?) {
        if shareEntity.bitableShareEntity?.meta?.isPublicPermissionToBeSet == true {
            subTitle = BundleI18n.SKResource.Bitable_Share_ShareDashboardOnboarding_ForOldUser_Set_Button
            chosenType = nil
            linkShareEnabled = true
            updateLabelText()
            return
        }
        guard let linkPermType = publicPermissions?.linkShareEntity else {
            return
        }
        switch linkPermType {
        case .close:
            subTitle = LinkType.BitableSub.onlyInvitedPeopleCanView.text
            chosenType = .close
            linkShareEnabled = false
        case .tenantCanRead:
            subTitle = LinkType.BitableSub.peopleWithLinkInTheOrgCanView.text
            chosenType = .orgRead
            linkShareEnabled = true
        case .anyoneCanRead:
            subTitle = LinkType.BitableSub.peopleWithLinkOnTheInternetCanView.text
            chosenType = .anyoneRead
            linkShareEnabled = true
        case .tenantCanEdit, .anyoneCanEdit:
            spaceAssertionFailure("bitable sub share can not be those type")
            DocsLogger.error("bitable sub share with wrong public perm: \(linkPermType.rawValue)")
            return
        }
        updateLabelText()
    }

    private func updateLinkShareChoice(type: LinkType.FormSub, chosenType: ShareLinkChoice) {
        self.subTitle = type.text
        self.chosenType = chosenType
    }

    private func updateLabelForFile(publicPermissions: PublicPermissionMeta?) {
        guard let publicPermissions = publicPermissions else { return }
        if let linkShareEntityV2 = publicPermissions.linkShareEntityV2 {
            switch linkShareEntityV2 {
            case .close:
                updateLinkShareChoice(type: .closeLinkDes, chosenType: .close)
                linkShareEnabled = false
            case .tenantCanRead:
                updateLinkShareChoice(type: .linkForOrgReadDes, chosenType: .orgRead)
                linkShareEnabled = true
            case .tenantCanEdit:
                updateLinkShareChoice(type: .linkForOrgEditDes, chosenType: .orgEdit)
                linkShareEnabled = true
            case .anyoneCanRead:
                if hasPassword {
                    updateLinkShareChoice(type: .anybodyKnownLinkAndPasswordCanReadDes, chosenType: .anyoneRead)
                } else {
                    updateLinkShareChoice(type: .anybodyKnownLinkCanReadDes, chosenType: .anyoneRead)
                }
                linkShareEnabled = true
            case .anyoneCanEdit:
                if hasPassword {
                    updateLinkShareChoice(type: .anybodyKnownLinkAndPasswordCanEditDes, chosenType: .anyoneEdit)
                } else {
                    updateLinkShareChoice(type: .anybodyKnownLinkCanEditDes, chosenType: .anyoneEdit)
                }
                linkShareEnabled = true
            case .partnerTenantCanRead:
                updateLinkShareChoice(type: .partnerTenantKnownLinkCanReadDes, chosenType: .partnerRead)
                linkShareEnabled = true
            case .partnerTenantCanEdit:
                updateLinkShareChoice(type: .partnerTenantKnownLinkCanEditDes, chosenType: .partnerEdit)
                linkShareEnabled = true
            }
        } else {
            switch publicPermissions.linkShareEntity {
            case .close:
                updateLinkShareChoice(type: .closeLinkDes, chosenType: .close)
                linkShareEnabled = false
            case .tenantCanRead:
                updateLinkShareChoice(type: .linkForOrgReadDes, chosenType: .orgRead)
                linkShareEnabled = true
            case .tenantCanEdit:
                updateLinkShareChoice(type: .linkForOrgEditDes, chosenType: .orgEdit)
                linkShareEnabled = true
            case .anyoneCanRead:
                if hasPassword {
                    updateLinkShareChoice(type: .anybodyKnownLinkAndPasswordCanReadDes, chosenType: .anyoneRead)
                } else {
                    updateLinkShareChoice(type: .anybodyKnownLinkCanReadDes, chosenType: .anyoneRead)
                }
                linkShareEnabled = true
            case .anyoneCanEdit:
                if hasPassword {
                    updateLinkShareChoice(type: .anybodyKnownLinkAndPasswordCanEditDes, chosenType: .anyoneEdit)
                } else {
                    updateLinkShareChoice(type: .anybodyKnownLinkCanEditDes, chosenType: .anyoneEdit)
                }
                linkShareEnabled = true
            }
        }
        updateLabelText()
    }
    
    private func updateLabelForShareFolder(publicPermissions: PublicPermissionMeta?) {
        guard let publicPermissions = publicPermissions else { return }
        if let linkShareEntityV2 = publicPermissions.linkShareEntityV2 {
            switch linkShareEntityV2 {
            case .close:
                updateLinkShareChoice(type: .closeLinkDes, chosenType: .close)
                linkShareEnabled = false
            case .tenantCanRead:
                updateLinkShareChoice(type: .linkForOrgReadFolderDes, chosenType: .orgRead)
                linkShareEnabled = true
            case .tenantCanEdit:
                updateLinkShareChoice(type: .linkForOrgEditFolderDes, chosenType: .orgEdit)
                linkShareEnabled = true
            case .anyoneCanRead:
                if hasPassword {
                    updateLinkShareChoice(type: .anybodyKnownLinkAndPasswordCanReadDes, chosenType: .anyoneRead)
                } else {
                    updateLinkShareChoice(type: .anybodyKnownLinkCanReadDes, chosenType: .anyoneRead)
                }
                linkShareEnabled = true
            case .anyoneCanEdit:
                DocsLogger.error("share folder cannot have link share type anyone edit!")
                spaceAssertionFailure()
                updateLinkShareChoice(type: .closeLinkDes, chosenType: .close)
                linkShareEnabled = false
            case .partnerTenantCanRead:
                updateLinkShareChoice(type: .partnerTenantKnownLinkCanReadFolderDes, chosenType: .partnerRead)
                linkShareEnabled = true
            case .partnerTenantCanEdit:
                updateLinkShareChoice(type: .partnerTenantKnownLinkCanEditDes, chosenType: .partnerEdit)
                linkShareEnabled = true
            }
        } else {
            switch publicPermissions.linkShareEntity {
            case .close:
                updateLinkShareChoice(type: .closeLinkDes, chosenType: .close)
                linkShareEnabled = false
            case .tenantCanRead:
                updateLinkShareChoice(type: .linkForOrgReadFolderDes, chosenType: .orgRead)
                linkShareEnabled = true
            case .tenantCanEdit:
                updateLinkShareChoice(type: .linkForOrgEditFolderDes, chosenType: .orgEdit)
                linkShareEnabled = true
            case .anyoneCanRead:
                if hasPassword {
                    updateLinkShareChoice(type: .anybodyKnownLinkAndPasswordCanReadDes, chosenType: .anyoneRead)
                } else {
                    updateLinkShareChoice(type: .anybodyKnownLinkCanReadDes, chosenType: .anyoneRead)
                }
                linkShareEnabled = true
            case .anyoneCanEdit:
                DocsLogger.error("share folder cannot have link share type anyone edit!")
                spaceAssertionFailure()
                updateLinkShareChoice(type: .closeLinkDes, chosenType: .close)
                linkShareEnabled = false
            }
        }
        self.updateLabelText()
    }
    
    private func updateLinkShareChoice(type: LinkType.Sub, chosenType: ShareLinkChoice) {
        if searchSettingEnable {
            var subTitle = type.text
            switch type {
            case .linkForOrgReadDes:
                subTitle = LinkType.Sub.peopleInOrgCanSearchAndView.text
            case .linkForOrgEditDes:
                subTitle = LinkType.Sub.peopleInOrgCanSearchAndEdit.text
            case .anybodyKnownLinkCanReadDes:
                subTitle = LinkType.Sub.peopleOnInternetCanViewPeopleInOrgCanSearch.text
            case .anybodyKnownLinkAndPasswordCanReadDes:
                subTitle = LinkType.Sub.anybodyKnownLinkAndPasswordCanViewPeopleInOrgCanSearch.text
            case .anybodyKnownLinkCanEditDes:
                subTitle = LinkType.Sub.peopleOnInternetCanEditPeopleInOrgCanSearch.text
            case .anybodyKnownLinkAndPasswordCanEditDes:
                subTitle = LinkType.Sub.anybodyKnownLinkAndPasswordCanEditPeopleInOrgCanSearch.text
            default: break
            }
            self.subTitle = subTitle
        } else {
            self.subTitle = type.text
        }
        if shareEntity.isSyncedBlock && chosenType == .close {
            self.subTitle = BundleI18n.SKResource.LarkCCM_CM_SharePanel_LinkAccess_Options(
                BundleI18n.SKResource.LarkCCM_Docs_Comments_SyncBlock_Title
            )
        }
        self.chosenType = chosenType
    }
    
    private func updateLabelText() {
        if shareEntity.isFormV1 || shareEntity.isBitableSubShare {
            updateSubViewsConstraintsForBitable()
        } else {
            updateSubViewsConstraints()
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    private func updateSubViewsConstraints() {
        let showSubTitle = needShowSubTitle()
        if showSubTitle {
            subTitleLabel.isHidden = false
            nameLabel.text = linkShareEnabled
                ? BundleI18n.SKResource.LarkCCM_Docs_LinkSharingOn_Menu_Mob
                : BundleI18n.SKResource.LarkCCM_Docs_LinkSharingOff_Menu_Mob
            subTitleLabel.text = subTitle
        } else {
            subTitleLabel.isHidden = true
            nameLabel.text = BundleI18n.SKResource.Doc_Share_NotOwnerCloseTitle
            subTitleLabel.text = ""
        }
    }
    private func updateSubViewsConstraintsForBitable() {
        let showSubTitle = needShowSubTitle()
        if showSubTitle {
            nameLabel.text = subTitle
        } else {
            nameLabel.text = ""
        }
    }

    private func needShowSubTitle() -> Bool {
        if shareEntity.isBitableSubShare {
            return true
        }
        var flag = true
        if let publicPermissions = publicPermissions, publicPermissions.isOwner {
            flag = true
        } else if isUserInteractionEnabled {
            flag = true
        } else if shareEntity.isSyncedBlock {
            flag = true
        } else if publicPermissions?.linkShareEntity == .close {
            flag = false
        }
        return flag
    }
}
