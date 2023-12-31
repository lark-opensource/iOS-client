//
//  EmbedDocAuthHeaderView.swift
//  SKCommon
//
//  Created by guoqp on 2022/3/1.
//

import Foundation
import SKUIKit
import SKResource
import Kingfisher
import SKFoundation
import RxSwift
import UniverseDesignCheckBox
import UniverseDesignColor
import UniverseDesignIcon
import UIKit


class EmbedDocAuthCellSectionHeaderView: UIView {
    var click: ((EmbedDocAuthViewModel.EnabledAction) -> Void)?
    private var enabledAction = EmbedDocAuthViewModel.EnabledAction.grant

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textPlaceholder
        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        return label
    }()

    lazy var grantAccessButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitleColor(UDColor.colorfulBlue, for: .normal)
        button.setTitle(BundleI18n.SKResource.LarkCCM_EmbeddedFiles_GrantAllPermission_Button_Mobile, for: .normal)
        button.addTarget(self, action: #selector(buttonAction(sender:)), for: .touchUpInside)
        return button
    }()


    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBodyOverlay
        addSubview(titleLabel)
        addSubview(grantAccessButton)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(safeAreaLayoutGuide.snp.left).offset(16)
            make.top.bottom.equalToSuperview()
            make.height.equalTo(44)
            make.right.lessThanOrEqualTo(grantAccessButton.snp.left).offset(-10)
        }
        grantAccessButton.snp.makeConstraints { make in
            make.right.equalTo(safeAreaLayoutGuide.snp.right).offset(-16)
            make.top.bottom.equalToSuperview()
        }
    }

    func update(hasPermissionCount: Int, noPermissonCount: Int, enabledAction: EmbedDocAuthViewModel.EnabledAction) {
        var text: String = ""
        if hasPermissionCount > 0 && noPermissonCount > 0 {
            text = BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Desc1(hasPermissionCount, noPermissonCount)
        } else if hasPermissionCount > 0 {
            text = BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Desc2(hasPermissionCount)
        } else if noPermissonCount > 0 {
            text = BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Desc3(noPermissonCount)
        } else {
            text = ""
        }
        titleLabel.text = text
        
        self.enabledAction = enabledAction
        switch enabledAction {
        case .grant:
            grantAccessButton.isHidden = false
            grantAccessButton.setTitle(BundleI18n.SKResource.LarkCCM_EmbeddedFiles_GrantAllPermission_Button_Mobile, for: .normal)
        case .revoke:
            grantAccessButton.isHidden = false
            grantAccessButton.setTitle(BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_RevokeAll, for: .normal)
        case .none:
            grantAccessButton.isHidden = true
        }
    }

    @objc
    private func buttonAction(sender: UIButton) {
        click?(enabledAction)
    }
}


class EmbedDocAuthHeaderView: UIView {
    var click: ((String, String?) -> Void)?
    private let width: CGFloat

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textColor = UDColor.textTitle
        label.sizeToFit()
//        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        return label
    }()

    private lazy var container: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var avatarView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor.ud.N100
        imageView.isUserInteractionEnabled = true
        imageView.layer.cornerRadius = CGFloat(20)
        imageView.layer.masksToBounds = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(clickAvatarViewAction))
        imageView.addGestureRecognizer(tap)
        return imageView
    }()

    private lazy var nickLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        return label
    }()

    private lazy var externalLabel: SKNavigationBarTitle.ExternalLabel = {
        let label = SKNavigationBarTitle.ExternalLabel()
        label.clipsToBounds = true
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        return label
    }()

    private var roleType: CollaboratorType = .user
    private var chatName: String?
    private var chatID: String?


    init(width: CGFloat) {
        self.width = width
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(titleLabel)
        addSubview(container)
        container.addSubview(avatarView)
        container.addSubview(nickLabel)
        container.addSubview(descriptionLabel)
//        container.addSubview(externalLabel)

        titleLabel.preferredMaxLayoutWidth = width - 2 * 16
        titleLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(16)
        }

        container.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(7)
            make.height.equalTo(68)
            make.bottom.equalToSuperview().inset(8)
        }

        avatarView.snp.makeConstraints { (make) in
            make.width.height.equalTo(40.0)
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        nickLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(container.snp.centerY)
        }

//        externalLabel.snp.makeConstraints { (make) in
//            make.centerY.equalTo(nickLabel.snp.centerY)
//            make.left.equalTo(nickLabel.snp.right).offset(3)
//            make.height.equalTo(16)
//            make.right.lessThanOrEqualTo(permissionContainer.snp.left).offset(-10)
//        }

        descriptionLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nickLabel)
            make.top.equalTo(container.snp.centerY)
            make.right.equalToSuperview().offset(-16)
        }
    }

    func updateNickLabelLayout() {
        if descriptionLabel.text?.isEmpty == false {
            return
        }
        nickLabel.snp.remakeConstraints { make in
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    func update(chatName: String, detail: String?, roleType: CollaboratorType, imageKey: String?, chatID: String) {
        var description: String?
        if let str = detail, str.isEmpty == false {
            description = str
        }

        var title: String
        switch roleType {
        case .group, .permanentMeetingGroup, .temporaryMeetingGroup:
            title = BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Subtitle_Chat_ver2
            if description?.isEmpty == true {
                description = BundleI18n.SKResource.Doc_Facade_NoGroupDesc
            }
        default:
            title = BundleI18n.SKResource.CreationMobile_Docs_EmbeddedFiles_AccessDetails_Subtitle_Chat_ver2
        }

        self.roleType = roleType
        self.chatID = chatID
        self.chatName = chatName

        titleLabel.text = title
        nickLabel.text = chatName
        descriptionLabel.text = description

        DocsLogger.info("imageKey:\(String(describing: imageKey))")
        if let imageKey = imageKey {
            let fixedKey = imageKey.replacingOccurrences(of: "lark.avatar/", with: "")
                .replacingOccurrences(of: "mosaic-legacy/", with: "")
            avatarView.bt.setLarkImage(with: .avatar(key: fixedKey, entityID: chatID),
                                       placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
        }
        updateNickLabelLayout()
    }

    @objc
    func clickAvatarViewAction() {
        if roleType == .user, let id = chatID {
            click?(id, chatName)
        }
    }
}
