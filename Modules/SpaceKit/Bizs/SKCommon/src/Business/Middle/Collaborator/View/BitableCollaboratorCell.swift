//
//  BitableBitableCollaboratorCell.swift
//  Collaborator
//
//  Created by Da Lei on 2018/3/28.

import Foundation
import SKUIKit
import LarkButton
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignEmpty
import SpaceInterface
import SKInfra

protocol BitableCollaboratorCellDelegate: AnyObject {
    func collaboratorCell(_ cell: BitableCollaboratorCell, didClickAvatarView collaborator: Collaborator?)
    func collaboratorCell(_ cell: BitableCollaboratorCell, didClickRightDeleteBtn collaborator: Collaborator?, at sender: UIGestureRecognizer?)
}

class BitableCollaboratorCell: UICollectionViewCell {
    static let reuseIdentifier = "BitableCollaboratorCell"
    var model: CollaboratorCellModel?
    private var canEdit: Bool = false
    public weak var delegate: BitableCollaboratorCellDelegate?

    private lazy var avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.ud.N100
        imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickAvatarViewAction))
        imageView.addGestureRecognizer(tap)
        return imageView
    }()
    
    private lazy var nickLabel: SKListCellView = {
        let label = SKListCellView()
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        return label
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
        addSubview(permissionLabel)
        addSubview(nickLabel)
        addSubview(descriptionLabel)
        addSubview(lineView)
    }

    private func setupConstraints() {
        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(48.0)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        nickLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
            make.right.lessThanOrEqualTo(permissionLabel.snp.left).offset(-10)
        }

        descriptionLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nickLabel)
            make.top.equalTo(nickLabel.snp.bottom)
            make.height.equalTo(20)
            make.right.lessThanOrEqualTo(permissionLabel.snp.left).offset(-10)
        }
        permissionLabel.snp.makeConstraints { (make) in
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-17)
        }
        
        lineView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview()
            make.left.equalTo(nickLabel)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    public func setModel(_ model: CollaboratorCellModel, canEdit: Bool) {
        self.canEdit = canEdit
        self.model = model
        let collaborator = model.collaborator

        let description: String = collaborator.cellDescription
        if description.isEmpty, collaborator.isExternal == false {
            descriptionLabel.isHidden = true // temporaryMeetingGroup 的 groupDescription 和 departmentName 都是空，也会隐藏 description，符合预期
        } else {
            if collaborator.isExternal {
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
        updateInfoPanel(collaborator)
        updateNickNameLabelConstraints(collaborator: collaborator)
        updatePermissionLabel(collaborator, canEdit: canEdit)
    }

    func updateInfoPanel(_ collaborator: Collaborator) {
        var views: [SKListCellElementType] = [.titleLabel(text: collaborator.name)]
        if UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
            if let value = collaborator.organizationTagValue {
                views.append(.customTag(text: value, visable: collaborator.isExternal))
            } else {
                views.append(.external(visable: collaborator.isExternal))
            }
        }
        if collaborator.type == .app {
            views.append(.app(visable: true))
        }
        nickLabel.update(views: views)
    }

    func updateNickNameLabelConstraints(collaborator: Collaborator) {
        let showDescriptionLabel = !(descriptionLabel.text?.isEmpty == true || descriptionLabel.text == nil || descriptionLabel.isHidden)
        descriptionLabel.snp.updateConstraints { (make) in
            make.height.equalTo(showDescriptionLabel ? 20: 0)
        }

        var offsetY = 0
        if showDescriptionLabel {
            offsetY = 10
        }
        nickLabel.snp.updateConstraints { (make) in
            make.right.lessThanOrEqualTo(permissionLabel.snp.left).offset(-10)
            make.centerY.equalToSuperview().offset(-offsetY)
        }
    }

    func updatePermissionLabel(_ collaborator: Collaborator, canEdit: Bool) {
        permissionLabel.text = BundleI18n.SKResource.Bitable_Form_RemovePermissionPopupButton
        permissionLabel.textColor = cellCanBeEdit(collaborator) ? UDColor.textTitle : UDColor.textDisabled
    }

    func updateAvatarView(collaborator: Collaborator) {
        let avatarURL = collaborator.avatarURL
        if avatarURL.hasPrefix("http") {
            avatarView.kf.setImage(with: URL(string: avatarURL),
                                   placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder,
                                   options: nil, progressBlock: nil) { (_) in
            }
        } else {
            avatarView.image = collaborator.avatarImage ?? BundleResources.SKResource.Common.Collaborator.avatar_placeholder
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

    private func cellCanBeEdit(_ collaborator: Collaborator) -> Bool {
        return canEdit && (collaborator.userID != User.current.info?.userID) && !collaborator.isOwner
    }

    @objc
    func didClickPermissionBtn(sender: UITapGestureRecognizer) {
        delegate?.collaboratorCell(self, didClickRightDeleteBtn: model?.collaborator, at: sender)
    }

    @objc
    func clickAvatarViewAction() {
        delegate?.collaboratorCell(self, didClickAvatarView: model?.collaborator)
    }
}

class BitableEmptyCollaboratorsCell: UICollectionViewCell {
    static let reuseIdentifier = "BitableEmptyCollaboratorsCell"

    public var tapEvent: ((BitableEmptyCollaboratorsCell) -> Void)?
    
    public var addAvailability: BitableAdPermAddDisableReason = .none {
        didSet {
            let config: UDEmptyConfig
            if addAvailability.addable {
                config = UDEmptyConfig(
                    title: .init(titleText: ""),
                    description: .init(descriptionText: BundleI18n.SKResource.Bitable_AdvancedPermission_CollaboratorIsEmpty),
                    imageSize: 100,
                    type: .noGroup,
                    primaryButtonConfig: (BundleI18n.SKResource.Bitable_AdvancedPermission_AddCollaborator, { [weak self] button in
                        guard let self = self else { return }
                        self.didTapConfirm()
                    })
                )
            } else {
                config = UDEmptyConfig(
                    title: .init(titleText: ""),
                    description: .init(descriptionText: BundleI18n.SKResource.Bitable_AdvancedPermission_CollaboratorIsEmpty),
                    imageSize: 100,
                    type: .noGroup
                )
            }
            emptyView.update(config: config)
        }
    }

    private lazy var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: BundleI18n.SKResource.Bitable_AdvancedPermission_CollaboratorIsEmpty),
                                                  imageSize: 100,
                                                  type: .noGroup,
                                                  labelHandler: nil,
                                                  primaryButtonConfig: (BundleI18n.SKResource.Bitable_AdvancedPermission_AddCollaborator, { [weak self] button in
                                                    guard let self = self else { return }
                                                    self.didTapConfirm()
                                               }),
                                                  secondaryButtonConfig: nil))
        return emptyView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func didTapConfirm() {
        tapEvent?(self)
    }
}
