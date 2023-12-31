//
//  CollaboratorInfoView.swift
//  SKCommon
//
//  Created by CJ on 2021/4/6.
//

import Foundation
import SKResource
import SKUIKit
import SKFoundation

class CollaboratorInfoView: UIView {
    var collaborator: Collaborator? {
        didSet {
            update(collaborator: collaborator)
        }
    }

    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.N500
        return label
    }()
    
    private lazy var bottomLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        return view
    }()

    private lazy var infoPanleView: SKListCellView = {
        let view = SKListCellView()
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(avatarImageView)
        addSubview(infoPanleView)
        addSubview(descriptionLabel)
        addSubview(bottomLineView)
    }

    private func setupConstraints() {
        avatarImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(54)
        }

        infoPanleView.snp.makeConstraints { make in
            make.leading.equalTo(avatarImageView.snp.trailing).offset(12)
            make.centerY.equalTo(avatarImageView)
            make.trailing.lessThanOrEqualToSuperview().offset(-10)
        }

        descriptionLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(infoPanleView)
            make.trailing.equalToSuperview().offset(-5)
            make.top.equalTo(infoPanleView.snp.bottom).offset(5)
        }

        bottomLineView.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.width.equalToSuperview()
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    private func update(collaborator: Collaborator?) {
        guard let collaborator = collaborator else { return }
        updateAvatarImageViewCornerRadius(flag: true)
        if collaborator.type == .folder {
            updateAvatarImageViewCornerRadius(flag: false)
            if let url = URL(string: collaborator.avatarURL) {
                avatarImageView.kf.setImage(with: url, placeholder: BundleResources.SKResource.Common.Tool.icon_tool_sharefolder)
            } else {
                avatarImageView.image = BundleResources.SKResource.Common.Tool.icon_tool_sharefolder
            }
        } else if collaborator.type == .email {
            avatarImageView.image = BundleResources.SKResource.Common.Collaborator.avatar_person
        } else if collaborator.type == .temporaryMeetingGroup {
            avatarImageView.image = BundleResources.SKResource.Common.Collaborator.avatar_meeting
        } else if collaborator.type == .wikiUser
                    || collaborator.type == .newWikiAdmin
                    || collaborator.type == .newWikiMember
                    || collaborator.type == .newWikiEditor {
            avatarImageView.image = BundleResources.SKResource.Common.Collaborator.avatar_wiki_user
        } else if collaborator.type == .organization || collaborator.type == .ownerLeader {
            avatarImageView.image = BundleResources.SKResource.Common.Collaborator.icon_collaborator_organization_32
        } else if collaborator.type == .userGroup || collaborator.type == .userGroupAssign {
            avatarImageView.image = BundleResources.SKResource.Common.Collaborator.icon_usergroup
        } else {
            if let url = URL(string: collaborator.avatarURL) {
                avatarImageView.kf.setImage(with: url, placeholder: BundleResources.SKResource.Common.Collaborator.avatar_placeholder)
            } else {
                avatarImageView.image = BundleResources.SKResource.Common.Collaborator.avatar_placeholder
            }
        }
        descriptionLabel.text = collaborator.cellDescription
        updateInfoPanelView(collaborator)
        updateInfoPanelConstraints(collaborator)
    }

    private func updateAvatarImageViewCornerRadius(flag: Bool) {
        if flag {
            avatarImageView.layer.cornerRadius = 27
            avatarImageView.layer.masksToBounds = true
            avatarImageView.backgroundColor = UIColor.ud.N100
        } else {
            avatarImageView.layer.cornerRadius = 0
            avatarImageView.layer.masksToBounds = false
            avatarImageView.backgroundColor = UIColor.ud.N00
        }
    }

    func updateInfoPanelView(_ collaborator: Collaborator) {
        var externalVisable: Bool = false
        if EnvConfig.CanShowExternalTag.value &&
           (collaborator.isExternal || collaborator.publicPermissions?.linkShareEntityV2?.canCrossTenant == true) &&
           User.current.info?.isToC == false {
            externalVisable = true
        }
        var views: [SKListCellElementType] = [.titleLabel(text: collaborator.name)]
        if let tagValue = collaborator.organizationTagValue, UserScopeNoChangeFG.HZK.b2bRelationTagEnabled {
            views.append(.customTag(text: tagValue, visable: externalVisable))
        } else {
            views.append(.external(visable: externalVisable))
        }
        if collaborator.type == .app {
            views.append(.app(visable: true))
        }
        infoPanleView.update(views: views)
    }

    private func updateInfoPanelConstraints(_ collaborator: Collaborator) {
        if collaborator.type == .email {
            infoPanleView.snp.updateConstraints({ (make) in
                make.centerY.equalTo(avatarImageView).offset(-13)
            })
            descriptionLabel.isHidden = false
            descriptionLabel.snp.updateConstraints { make in
                make.top.equalTo(infoPanleView.snp.bottom).offset(2)
            }
            descriptionLabel.numberOfLines = 2
            return
        }
        descriptionLabel.numberOfLines = 1
        if descriptionLabel.text == nil || descriptionLabel.text?.isEmpty == true {
            descriptionLabel.isHidden = true
            infoPanleView.snp.updateConstraints({ (make) in
                make.centerY.equalTo(avatarImageView)
            })
        } else {
            descriptionLabel.isHidden = false
            infoPanleView.snp.updateConstraints({ (make) in
                make.centerY.equalTo(avatarImageView).offset(-11)
            })
        }
    }
}
