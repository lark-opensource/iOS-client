//
//  CollaboratorCell.swift
//  Collaborator
//
//  Created by Da Lei on 2018/3/28.

import Foundation
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignTag
import SKInfra

//cell右侧按钮内容类型
enum PermissionLabelDisplayType {
    case role //显示权限角色文案，点击切换权限角色
    case delete //显示删除文案
}

protocol CollaboratorCellDelegate: AnyObject {
    func collaboratorCell(_ cell: CollaboratorCell, didClickRightDeleteBtn collaborator: Collaborator?, at sender: UIGestureRecognizer?)
    func collaboratorCell(_ cell: CollaboratorCell, didClickPermissionBtn collaborator: Collaborator?, at sender: UIGestureRecognizer?)
    func collaboratorCell(_ cell: CollaboratorCell, didClickAvatarView collaborator: Collaborator?)
    func collaboratorCell(_ cell: CollaboratorCell, didClickQuestionMark collaborator: Collaborator?)
    func collaboratorCell(_ cell: CollaboratorCell, didClickTips collaborator: Collaborator?)
    func collaboratorCell(_ cell: CollaboratorCell, didClickCacBlockTag collaborator: Collaborator?)
}

class CollaboratorCell: UICollectionViewCell {
    static let reuseIdentifier = "CollaboratorCell"
    var model: CollaboratorCellModel?
    var canBeEdited = false
    var wikiV2SingleContainer: Bool = false
    var spaceSingleContainer: Bool = false
    var isShareFolder: Bool = false
    public weak var delegate: CollaboratorCellDelegate?
    private var permissionLabelDisplayType: PermissionLabelDisplayType = .role

    private lazy var avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.ud.N100
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickAvatarViewAction))
        imageView.addGestureRecognizer(tap)
        return imageView
    }()
    
    private lazy var tipsButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(tipsButtonAction), for: .touchUpInside)
        button.setBackgroundImage(UDIcon.infoOutlined.ud.withTintColor(UDColor.iconN2), for: .normal)
        button.isHidden = true
        button.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
        return button
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        return label
    }()
    
    private lazy var permissionSourceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        return label
    }()
    
    private lazy var permissionOptionArrowView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BundleResources.SKResource.Common.Collaborator.permission_optionArrow.ud.withTintColor(UDColor.iconN2)
        imageView.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        return imageView
    }()
    
    private lazy var permissionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didClickPermissionBtn(sender:)))
        label.addGestureRecognizer(tapGesture)
        label.textAlignment = .right
        label.isUserInteractionEnabled = true
        label.setContentCompressionResistancePriority(.required + 100, for: .horizontal)
        return label
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        return view
    }()
    
    private lazy var permissionContainer: UIView = {
        let view = UIView()
        view.docs.addHighlight(with: UIEdgeInsets(top: -6, left: -10, bottom: -6, right: -10), radius: 8)
        view.setContentCompressionResistancePriority(.defaultHigh + 1, for: .horizontal)
        return view
    }()

    private lazy var containerStackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 3
        return view
    }()
    
    private lazy var infoPanelView: SKListCellView = {
        let view = SKListCellView()
        return view
    }()
    
    private lazy var cacBlockTag: UDTag = {
        let config = UDTagConfig.TextConfig(cornerRadius: 4,
                                            textColor: UDColor.udtokenTagTextSOrange,
                                            backgroundColor: UDColor.udtokenTagBgOrange)
        let tag = UDTag(text: BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_Restricted_Tag,
                        textConfig: config)
        tag.isUserInteractionEnabled = true
        tag.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cacBlockTagAction)))
        tag.setContentCompressionResistancePriority(.required, for: .horizontal)
        return tag
    }()

    private lazy var questionMarkButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(questionMarkButtonAction), for: .touchUpInside)
        button.setBackgroundImage(BundleResources.SKResource.Common.Collaborator.icon_tool_guide_nor, for: .normal)
        button.isHidden = true
        return button
    }()

    public var hideSeperator: Bool = false {
        didSet {
            self.lineView.isHidden = hideSeperator
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.ud.N00
        addSubview(avatarView)
        addSubview(permissionContainer)
        permissionContainer.addSubview(permissionOptionArrowView)
        permissionContainer.addSubview(permissionLabel)
        addSubview(infoPanelView)

        addSubview(containerStackView)
//        containerStackView.addSubview(infoPanelView)
        containerStackView.addArrangedSubview(cacBlockTag)
        
        addSubview(descriptionLabel)
        addSubview(permissionSourceLabel)
        addSubview(lineView)
        addSubview(questionMarkButton)
        addSubview(tipsButton)
    }

    private func setupConstraints() {
        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(48.0)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        infoPanelView.snp.makeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
            make.right.lessThanOrEqualTo(permissionContainer.snp.left).offset(-10)
        }
        
        containerStackView.snp.makeConstraints { make in
            make.height.equalTo(16)
            make.left.equalTo(infoPanelView.snp.right).offset(3)
            make.centerY.equalTo(infoPanelView.snp.centerY)
            make.right.lessThanOrEqualTo(permissionContainer.snp.left).offset(-10)
        }
        
        descriptionLabel.snp.makeConstraints { (make) in
            make.left.equalTo(infoPanelView)
            make.top.equalTo(infoPanelView.snp.bottom)
            make.height.equalTo(20)
            make.right.lessThanOrEqualTo(permissionContainer.snp.left).offset(-10)
        }
        
        permissionSourceLabel.snp.makeConstraints { (make) in
            make.top.equalTo(descriptionLabel.snp.bottom)
            make.left.equalTo(infoPanelView)
            make.height.equalTo(20)
            make.right.lessThanOrEqualTo(permissionContainer.snp.left).offset(-10)
        }

        permissionContainer.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-17)
        }
        
        permissionOptionArrowView.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        permissionLabel.snp.makeConstraints { (make) in
            make.height.equalTo(22)
            make.top.bottom.left.equalToSuperview()
            make.right.equalTo(permissionOptionArrowView.snp.left)
        }
        
        lineView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.left.equalTo(infoPanelView)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        tipsButton.snp.makeConstraints { make in
            make.centerY.equalTo(infoPanelView)
            make.left.equalTo(infoPanelView.snp.right).offset(4)
            make.height.width.equalTo(16)
        }
    }

    public func setModel(_ model: CollaboratorCellModel,
                         wikiV2SingleContainer: Bool = false,
                         spaceSingleContainer: Bool = false,
                         isShareFolder: Bool = false,
                         permissionLabelDisplayType: PermissionLabelDisplayType = .role) {
        self.permissionLabelDisplayType = permissionLabelDisplayType
        self.wikiV2SingleContainer = wikiV2SingleContainer
        self.spaceSingleContainer = spaceSingleContainer
        self.isShareFolder = isShareFolder
        canBeEdited = false
        self.model = model
        let collaborator = model.collaborator
        if let permSource = collaborator.permSource, !permSource.isEmpty {
            if wikiV2SingleContainer {
                permissionSourceLabel.text = BundleI18n.SKResource.CreationMobile_Wiki_Permission_InheritPermissions_Tooltip
            } else {
                permissionSourceLabel.text = BundleI18n.SKResource.CreationMobile_ECM_InheritFolderDesc
            }
            permissionSourceLabel.isHidden = false
        } else {
            permissionSourceLabel.text = ""
            permissionSourceLabel.isHidden = true
        }
        let description: String = collaborator.cellDescription
        if description.isEmpty, collaborator.isExternal == false {
            descriptionLabel.isHidden = true // temporaryMeetingGroup 的 groupDescription 和 departmentName 都是空，也会隐藏 description，符合预期
        } else {
            if collaborator.type == .email {
                descriptionLabel.text = description
            } else if collaborator.isExternal {
                if let tenantName = collaborator.tenantName, !tenantName.isEmpty {
                    descriptionLabel.text = tenantName
                } else {
                    let dataCenterAPI = DocsContainer.shared.resolve(DataCenterAPI.self)
                    descriptionLabel.text = dataCenterAPI?.userInfo(for: collaborator.userID)?.tenantName
                }
            } else {
                descriptionLabel.text = description
            }
            descriptionLabel.isHidden = (descriptionLabel.text?.isEmpty == true)
        }

        updateAvatarView(collaborator: collaborator)
        if case .delete = permissionLabelDisplayType {
            //显示删除按钮
            if (collaborator.userID != User.current.info?.userID) && !collaborator.isOwner {
                canBeEdited = true
            }
        } else if wikiV2SingleContainer || spaceSingleContainer {
            canBeEdited = collaborator.canModify
        } else {
            // 协作者可被编辑 && 不是自己 && 不是owner  都满足才能编辑
            if collaborator.canModify && (collaborator.userID != User.current.info?.userID) && !collaborator.isOwner {
                canBeEdited = true
            }
        }

        if case .delete = permissionLabelDisplayType {
            permissionOptionArrowView.isHidden = true
        } else {
            permissionOptionArrowView.isHidden = canBeEdited ? false : true
        }
        
        if [1, 2].contains(model.collaborator.tooltipsType) && LKFeatureGating.wikiMemberEnable {
            tipsButton.isHidden = false
        } else {
            tipsButton.isHidden = true
        }

        permissionLabel.textColor = canBeEdited ? UDColor.textTitle : UDColor.textCaption
        permissionLabel.isUserInteractionEnabled = canBeEdited ? true : false
        permissionContainer.isUserInteractionEnabled = canBeEdited ? true : false
        updateInfoPanel(collaborator)
        udpateCacBlockedTag(collaborator: collaborator)
        updateQuestionMarkButton(collaborator: collaborator)
        updateNickNameLabelConstraints(collaborator: collaborator)
        updatePermissionLabel(collaborator, permissionLabelDisplayType: permissionLabelDisplayType)
    }
    
    func updateInfoPanel(_ collaborator: Collaborator) {
        let visableOwnerLabel = collaborator.isOwner && (wikiV2SingleContainer || spaceSingleContainer)
        var views: [SKListCellElementType] = [.titleLabel(text: collaborator.name),
                                              .owner(visable: visableOwnerLabel)]
        if let value = collaborator.organizationTagValue, UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
            views.append(.customTag(text: value, visable: collaborator.isExternal))
        } else {
            views.append(.external(visable: collaborator.isExternal))
        }
        if collaborator.type == .app {
            views.append(.app(visable: true))
        }
        infoPanelView.update(views: views)
    }
    
    func updatePermissionLabel(_ collaborator: Collaborator,
                               permissionLabelDisplayType: PermissionLabelDisplayType) {
        if collaborator.blockStatus == .blockedByCac {
            permissionLabel.text = BundleI18n.SKResource.LarkCCM_Workspace_ConAccess_NoPerm_Menu
        } else if collaborator.isOwner {
            permissionLabel.text = (wikiV2SingleContainer || spaceSingleContainer)
                ? BundleI18n.SKResource.CreationMobile_Wiki_Permission_FullAccess_Options
                : BundleI18n.SKResource.Doc_Share_ShareOwner
        } else {
            permissionLabel.text = collaborator.userPermissions.permRoleType.titleText
            if case .delete = permissionLabelDisplayType {
                permissionLabel.text = BundleI18n.SKResource.Bitable_Form_RemovePermissionPopupButton
            }
        }
    }

    private func udpateCacBlockedTag(collaborator: Collaborator) {
        cacBlockTag.isHidden = !(collaborator.blockStatus == .blockedByCac)
    }

    private func updateQuestionMarkButton(collaborator: Collaborator) {
        questionMarkButton.isHidden = !collaborator.hasTips
        questionMarkButton.snp.remakeConstraints { (make) in
            make.centerY.equalTo(infoPanelView.snp.centerY)
            make.height.width.equalTo(24)
            make.left.equalTo(containerStackView).offset(3)
            make.right.lessThanOrEqualTo(permissionContainer.snp.left).offset(-3).priority(.high)
        }
        questionMarkButton.hitTestEdgeInsets = UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8)
    }

    func updateNickNameLabelConstraints(collaborator: Collaborator) {
        if collaborator.type == .email {
            descriptionLabel.numberOfLines = 2
            descriptionLabel.snp.updateConstraints { (make) in
                make.height.equalTo(40)
            }
            infoPanelView.snp.updateConstraints { make in
                make.centerY.equalToSuperview().offset(-13)
            }
            return
        }
        descriptionLabel.numberOfLines = 1
        let width = DocsSDK.currentLanguage == .en_US ? 48 : 28
        var offsetY = 0
        let showDescriptionLabel = !(descriptionLabel.text?.isEmpty == true || descriptionLabel.text == nil || descriptionLabel.isHidden)
        let showPermissionSourceLabel = !(permissionSourceLabel.isHidden || permissionSourceLabel.text?.isEmpty == true)
        if showDescriptionLabel && showPermissionSourceLabel {
            offsetY = 20
        } else if showDescriptionLabel {
            offsetY = 10
        } else if showPermissionSourceLabel {
            offsetY = 10
        }
        descriptionLabel.snp.updateConstraints { (make) in
            make.height.equalTo(showDescriptionLabel ? 20: 0)
        }
        infoPanelView.snp.updateConstraints { make in
            make.centerY.equalToSuperview().offset(-offsetY)
        }
    }
    
    func updateAvatarView(collaborator: Collaborator) {
        let avatarURL = collaborator.avatarURL
        if collaborator.type == .wikiUser
             || collaborator.type == .newWikiAdmin
             || collaborator.type == .newWikiMember
             || collaborator.type == .newWikiEditor {
            //TODO: 这段逻辑等APP版本整体提上去后，通知后端修改下发的资源，去掉本地逻辑
            avatarView.image = BundleResources.SKResource.Common.Collaborator.avatar_wiki_user
        } else {
            if avatarURL.hasPrefix("http") {
                avatarView.kf.setImage(with: URL(string: avatarURL),
                                       placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder,
                                       options: nil, progressBlock: nil) { (_) in
                }
            } else {
                avatarView.image = collaborator.avatarImage ?? BundleResources.SKResource.Common.Collaborator.avatar_placeholder
            }
        }
        
        // 文件夹icon 不需要圆角
        if collaborator.type == .folder {
            avatarView.layer.cornerRadius = 0
            avatarView.layer.masksToBounds = false
            avatarView.backgroundColor = .clear
        } else {
            avatarView.layer.cornerRadius = CGFloat(24)
            avatarView.layer.masksToBounds = true
        }
    }

    @objc
    func didClickPermissionBtn(sender: UITapGestureRecognizer) {
        if case .delete = permissionLabelDisplayType {
            delegate?.collaboratorCell(self, didClickRightDeleteBtn: model?.collaborator, at: sender)
        } else {
            delegate?.collaboratorCell(self, didClickPermissionBtn: model?.collaborator, at: sender)
        }
    }

    @objc
    func clickAvatarViewAction() {
        delegate?.collaboratorCell(self, didClickAvatarView: model?.collaborator)
    }

    @objc
    func questionMarkButtonAction() {
        delegate?.collaboratorCell(self, didClickQuestionMark: model?.collaborator)
    }
    
    @objc
    func tipsButtonAction() {
        delegate?.collaboratorCell(self, didClickTips: model?.collaborator)
    }
    
    @objc
    func cacBlockTagAction(recognizer: UITapGestureRecognizer) {
        delegate?.collaboratorCell(self, didClickCacBlockTag: model?.collaborator)
    }
}
